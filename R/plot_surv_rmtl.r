
## function to plot the restricted mean time lost as it evolves over values of
## the continuous variable
#' @importFrom rlang .data
#' @export
plot_surv_rmtl <- function(time, status, variable, data, model,
                           na.action=options()$na.action,
                           tau, horizon=NULL,
                           size=1, linetype="solid", alpha=1,
                           xlab=variable, ylab="Restricted Mean Time Lost",
                           title=NULL, subtitle=NULL,
                           legend.title=variable, legend.position="right",
                           gg_theme=ggplot2::theme_bw(), ...) {
  requireNamespace("adjustedCurves")
  requireNamespace("dplyr")

  check_inputs_plots(time=time, status=status, variable=variable,
                     data=data, model=model, na.action=na.action,
                     horizon=horizon, fixed_t=NULL, max_t=Inf,
                     discrete=TRUE, panel_border=TRUE, t=1, tau=tau)

  # perform na.action
  if (is.function(na.action)) {
    data <- na.action(data)
  } else {
    na.action <- get(na.action)
    data <- na.action(data)
  }

  if (is.null(horizon)) {
    horizon <- seq(min(data[, variable]), max(data[, variable]),
                   length.out=100)
  }

  # get plotdata
  fixed_t <- c(0, sort(unique(data[, time][data[, status]==1])))
  plotdata <- curve_cont(data=data,
                         variable=variable,
                         model=model,
                         horizon=horizon,
                         times=fixed_t,
                         na.action="na.fail",
                         cif=TRUE,
                         ...)

  # use adjustedCurves package to calculate RMTL values
  plotdata$group <- as.factor(plotdata$cont)
  plotdata$cif <- plotdata$est
  plotdata$est <- NULL
  plotdata$cont <- NULL
  fake_adjcif <- list(adjcif=plotdata)
  class(fake_adjcif) <- "adjustedcif"

  out <- vector(mode="list", length=length(tau))
  for (i in seq_len(length(tau))) {
    rmtl <- adjustedCurves::adjusted_rmtl(fake_adjcif, from=0, to=tau[i],
                                          conf_int=FALSE)
    rmtl$group <- as.numeric(as.character(rmtl$group))
    rmtl$tau <- tau[i]

    out[[i]] <- rmtl
  }
  out <- dplyr::bind_rows(out)
  out$tau <- as.factor(out$tau)

  # plot them
  p <- ggplot2::ggplot(out, ggplot2::aes(x=.data$group, y=.data$rmtl,
                                         color=.data$tau))

  if (length(tau)==1) {
    p$mapping$colour <- NULL
  }

  p <- p + ggplot2::geom_line(size=size, linetype=linetype, alpha=alpha) +
    ggplot2::labs(x=xlab, y=ylab, title=title, subtitle=subtitle,
                  fill=legend.title) +
    gg_theme +
    ggplot2::theme(legend.position=legend.position)

  return(p)
}