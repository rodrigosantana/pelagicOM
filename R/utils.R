########################################################################
## Description: pelagicOM - general utilities (RNG handling, temporal
##              anchors, truncated draws, kernel Gaussian fields, I/O)
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Small stateless helpers shared by the biomass (Part I) and fishery
## (Part II) components. They are verbatim ports of the helpers used in
## Experimento_02 (Simulacao_Biomassa/R and Simulacao_Pesca/R/00_utils.R):
## any change in the order or number of random draws here would break the
## exact reproduction of the BET operating truth.
##
### Code:
########################################################################

`%||%` <- function(a, b) if (is.null(a)) b else a

om_msg <- function(verbose, ...) if (isTRUE(verbose)) message(...)

########################################################################
######@> Random number generator...

######@> Seeds every stream with the RNG kinds used in Experimento_02
######@> (R >= 3.6 defaults). Setting the kinds explicitly makes the
######@> results independent of a user-level RNGkind() change...
om_set_seed <- function(seed) {
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion",
             sample.kind = "Rejection")
}

######@> Runs 'code' and restores the caller's RNG state (and kinds)
######@> afterwards, so that the package never leaves a side effect on the
######@> user's random stream. Inside, modules call om_set_seed() exactly
######@> where the original scripts called set.seed()...
with_om_rng <- function(code) {
    genv <- globalenv()
    had_seed <- exists(".Random.seed", envir = genv, inherits = FALSE)
    old_seed <- if (had_seed) get(".Random.seed", envir = genv) else NULL
    old_kind <- RNGkind()
    on.exit({
        suppressWarnings(RNGkind(old_kind[1], old_kind[2], old_kind[3]))
        if (had_seed) assign(".Random.seed", old_seed, envir = genv)
        else if (exists(".Random.seed", envir = genv, inherits = FALSE))
            rm(".Random.seed", envir = genv)
    }, add = TRUE)
    force(code)
}

########################################################################
######@> Temporal anchors...

######@> Linear interpolation of a named vector (name = year, value) to
######@> the requested years, constant outside the anchor range...
interp_anchors <- function(years, anchors) {
    a <- as.numeric(names(anchors)); v <- as.numeric(anchors)
    o <- order(a); a <- a[o]; v <- v[o]
    if (length(a) == 1) return(rep(v, length(years)))
    stats::approx(x = a, y = v, xout = years, rule = 2)$y
}

######@> Centred moving average (removes the corners of the removal-rate
######@> phases)...
moving_average <- function(x, k = 3) {
    if (k < 2) return(x)
    n <- length(x); y <- x
    for (i in seq_len(n)) {
        j <- max(1, i - k %/% 2):min(n, i + k %/% 2)
        y[i] <- mean(x[j])
    }
    y
}

######@> AR(1) noise on the log scale with marginal variance sd^2 (first
######@> value drawn from the stationary distribution) and bias correction
######@> so that E[exp(eps)] = 1...
ar1_noise <- function(n, sd, rho, bias_correct = TRUE) {
    if (sd <= 0 || n < 1) return(rep(0, n))
    e <- numeric(n)
    e[1] <- stats::rnorm(1, 0, sd)
    if (n > 1)
        for (i in 2:n)
            e[i] <- rho * e[i - 1] + stats::rnorm(1, 0, sd * sqrt(1 - rho^2))
    if (bias_correct) e <- e - sd^2 / 2
    e
}

########################################################################
######@> Truncated draws...

######@> Lognormal with median 'median' and coefficient of variation
######@> 'cv', truncated to [lo, hi] by rejection (only out-of-range
######@> values are redrawn)...
rlnorm_trunc <- function(n, median, cv, lo, hi) {
    sdlog <- sqrt(log(1 + cv^2))
    x <- stats::rlnorm(n, log(median), sdlog)
    bad <- which(x < lo | x > hi)
    k <- 0
    while (length(bad) > 0 && k < 50) {
        x[bad] <- stats::rlnorm(length(bad), log(median[bad]), sdlog)
        bad <- which(x < lo | x > hi); k <- k + 1
    }
    pmin(pmax(x, lo), hi)
}

######@> Uniform integers in [lo, hi]...
rint <- function(n, lo, hi) sample.int(hi - lo + 1L, n, replace = TRUE) +
                                lo - 1L

########################################################################
######@> Gaussian random field by kernel smoothing...

######@> 1D Gaussian kernel matrix (n x n), truncated at 4 sd...
gaussian_kernel_matrix <- function(n, range) {
    d <- outer(seq_len(n), seq_len(n), "-")
    K <- exp(-0.5 * (d / range)^2)
    K[abs(d) > 4 * range] <- 0
    K
}

#' Gaussian random field on the regular lattice
#'
#' Smooths white noise with a separable Gaussian kernel,
#' \eqn{F = K_r Z K_c^\top}, and normalises cell by cell so that every
#' lattice cell has marginal standard deviation exactly `sd`. This is the
#' spatial building block of the persistent habitat field, of the
#' spatio-temporal noise and of the spatial catchability field.
#'
#' @param lattice List with `n_row` and `n_col` (see [om_domain_iccat()]).
#' @param range Standard deviation of the kernel, in lattice cells
#'   (degrees for a 1-degree grid).
#' @param sd Marginal standard deviation (log scale).
#' @return Matrix `n_row x n_col`.
#' @export
gaussian_random_field <- function(lattice, range, sd) {
    nr <- lattice$n_row; nc <- lattice$n_col
    if (sd <= 0) return(matrix(0, nr, nc))
    Kr <- gaussian_kernel_matrix(nr, range)
    Kc <- gaussian_kernel_matrix(nc, range)
    Z  <- matrix(stats::rnorm(nr * nc), nr, nc)
    F  <- Kr %*% Z %*% t(Kc)
    norm <- sqrt(outer(rowSums(Kr^2), rowSums(Kc^2)))
    sd * F / norm
}

######@> Value of a lattice matrix at each domain cell...
field_at_cells <- function(M, cells) M[cbind(cells$Row, cells$Col)]

########################################################################
######@> Tables and files...

######@> Gzip-compressed csv (the output standard of the project)...
write_csv_gz <- function(x, file) {
    con <- gzfile(file, "w")
    on.exit(close(con))
    utils::write.csv(x, con, row.names = FALSE, na = "")
    invisible(file)
}

######@> Last observation carried forward on a vector with NA (used by
######@> spatial fidelity)...
fill_forward <- function(x) {
    idx <- seq_along(x)
    idx[is.na(x)] <- NA
    idx <- cummax(ifelse(is.na(idx), 0L, idx))
    x[idx]
}

need_pkg <- function(pkg, what) {
    if (!requireNamespace(pkg, quietly = TRUE))
        stop(what, " requires the package '", pkg, "' (install.packages('",
             pkg, "'))", call. = FALSE)
    invisible(TRUE)
}
