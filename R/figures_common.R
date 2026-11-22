########################################################################
## Description: pelagicOM - common theme, palettes and figure saving
##
## Author: Rodrigo Sant'Ana
## Created: 2026-11-22
## Version: 0.1.0
##
### Commentary:
##
## Visual identity of Experimento 02: white background, black and grey
## tones, lines told apart by tone AND line type (black-and-white print),
## minimal theme, English labels. Palettes are generated for any number
## of regions / fleets / strategies; with the Experimento 02 names they
## are exactly the original ones.
##
### Code:
########################################################################

GRAY_INK   <- "black"
GRAY_MID   <- "grey45"
GRAY_LIGHT <- "grey70"
GRAY_GRID  <- "grey88"

#' Publication theme of pelagicOM figures
#'
#' Minimal grey-scale `ggplot2` theme used by every figure of the
#' package.
#'
#' @param base Base font size.
#' @return A `ggplot2` theme.
#' @export
theme_pub <- function(base = 11) {
    need_pkg("ggplot2", "theme_pub()")
    ggplot2::theme_minimal(base_size = base) +
        ggplot2::theme(
            panel.grid.major = ggplot2::element_line(colour = GRAY_GRID,
                                                     linewidth = 0.3),
            panel.grid.minor = ggplot2::element_blank(),
            axis.text   = ggplot2::element_text(colour = GRAY_MID),
            axis.title  = ggplot2::element_text(colour = GRAY_INK),
            strip.text  = ggplot2::element_text(colour = GRAY_INK,
                                                face = "bold"),
            legend.position = "bottom",
            legend.title = ggplot2::element_blank(),
            plot.title  = ggplot2::element_text(face = "bold"),
            plot.subtitle = ggplot2::element_text(colour = GRAY_MID),
            plot.background = ggplot2::element_rect(fill = "white",
                                                    colour = NA)
        )
}

save_fig <- function(p, file, oc, width = NULL, height = NULL,
                     verbose = TRUE) {
    ggplot2::ggsave(file, p,
                    width  = if (is.null(width))  oc$fig_width  else width,
                    height = if (is.null(height)) oc$fig_height else height,
                    dpi = oc$fig_dpi, bg = "white")
    om_msg(verbose, "  fig: ", file)
    invisible(file)
}

fmt_lat <- function(x) {
    ifelse(x > 0, sprintf("%g\u00b0N", x),
           ifelse(x < 0, sprintf("%g\u00b0S", -x), "0\u00b0"))
}

######@> "a", "a and b", "a, b and c"...
collapse_and <- function(x) {
    n <- length(x)
    if (n <= 1) return(paste(x, collapse = ""))
    paste(paste(x[-n], collapse = ", "), "and", x[n])
}

######@> Colours, line types and legend labels of the regions. Labels
######@> are ordered from north to south; breaks ascending...
region_style <- function(regions) {
    lb <- regions$labels; br <- sort(regions$breaks); n <- length(lb)
    if (identical(lb, c("R01", "R02", "R03"))) {
        pal <- c(R01 = "grey55", R02 = "black", R03 = "grey30")
        lty <- c(R01 = "solid", R02 = "solid", R03 = "22")
    } else {
        pal <- stats::setNames(grDevices::gray.colors(n, start = 0,
                                                      end = 0.6), lb)
        lty <- stats::setNames(rep(c("solid", "22", "42", "12"),
                                   length.out = n), lb)
    }
    desc <- character(n)
    for (k in seq_len(n)) {
        j <- n - k + 1L                       # band index from the south
        desc[k] <- if (n == 1L) "whole domain"
                   else if (j == n) paste(">", fmt_lat(br[n - 1L]))
                   else if (j == 1L) paste("<", fmt_lat(br[1L]))
                   else paste0(fmt_lat(br[j - 1L]), "-", fmt_lat(br[j]))
    }
    lab <- stats::setNames(sprintf("%s (%s)", lb, desc), lb)
    list(pal = pal, lty = lty, lab = lab)
}

fleet_style <- function(fleets) {
    if (identical(fleets, c("A", "B", "C", "D", "E"))) {
        pal <- c(A = "black", B = "grey25", C = "grey45", D = "grey60",
                 E = "grey75")
        lty <- c(A = "solid", B = "22", C = "solid", D = "42", E = "12")
    } else {
        pal <- stats::setNames(grDevices::gray.colors(length(fleets),
                                                      start = 0, end = 0.75),
                               fleets)
        lty <- stats::setNames(rep(c("solid", "22", "solid", "42", "12"),
                                   length.out = length(fleets)), fleets)
    }
    list(pal = pal, lty = lty)
}

strategy_style <- function(levels) {
    if (identical(levels, c("S1", "S2", "S3"))) {
        pal <- c(S1 = "black", S2 = "grey45", S3 = "grey70")
        lty <- c(S1 = "solid", S2 = "22", S3 = "42")
    } else {
        pal <- stats::setNames(grDevices::gray.colors(length(levels),
                                                      start = 0, end = 0.7),
                               levels)
        lty <- stats::setNames(rep(c("solid", "22", "42", "12"),
                                   length.out = length(levels)), levels)
    }
    list(pal = pal, lty = lty)
}

utils::globalVariables(c(
    "Year", "value", "y", "lab", "Region", "Biomass", "Share", "Density",
    "series", "Lat_band", "Relative", "Latitude", "Fleet", "Sets",
    "Strategy", "share", "component", "level", "HBF", "q_vessel",
    "TrueCatch", "B_total", "RawCPUE", "share_of_total", "species",
    "mechanism", "panel"))
