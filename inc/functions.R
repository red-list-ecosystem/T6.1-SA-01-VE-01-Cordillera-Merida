# devtools::install(sprintf("%s/bin/RLEtools",Sys.getenv("HOME")))
#require(RLEtools)
calc_decline <- function(data,start,end) {
  stopifnot("eco_extent" %in% colnames(data),
            "years" %in% colnames(data),
            start<=nrow(data),
            end<=nrow(data))
  start_date <- pull(data[start,"years"])
  end_date <- pull(data[end,"years"])
  stopifnot(start_date<end_date)
  start_extent <- pull(data[start,"eco_extent"])
  end_extent <- pull(data[end,"eco_extent"])
  res <- dplyr::tibble(
    start_date,
    end_date,
    time_frame=end_date-start_date,
    decline=(units::set_units(1,'1')-(end_extent/start_extent)) %>% units::set_units('%'))
  if ("error_extent" %in% colnames(data)) {
    start_error <- pull(data[start,"error_extent"])
    end_error <- pull(data[end,"error_extent"])
    res$error <- sqrt(((end_extent^2 * start_error^2) + (start_extent^2 * end_error^2)) / (start_extent^4)) %>% units::set_units('%')
  }
  return(res)
}
futurePred <- function(mod,eval.years=c(1990,2040), level=90) {
  prd1 <- predict(mod,newdata=tibble(years=eval.years),se.fit=T)
  ## following steps in https://fromthebottomoftheheap.net/2018/12/10/confidence-intervals-for-glms/
  ilink <- family(mod)$linkinv
  chat <- summary(mod)$dispersion # overdispersion
  # critical value for norm distribution
  alpha <- ((100-level)/100)/2
  quant <- qnorm(alpha, lower.tail = FALSE)
  # small sample size maybe should use a critical value from the t distribution
  #quant <- qt(0.025, df = df.residual(mod1), lower.tail = FALSE)
  prd <- tibble(
    years=eval.years,
    best=ilink(prd1$fit),
    lower=ilink(prd1$fit - (quant * prd1$se.fit * chat)),
    upper=ilink(prd1$fit + (quant * prd1$se.fit * chat))
  )
  return(prd)
}

relativeSeverity <- function(datevect,varvect,start,end,collapse,errorvect=NULL) {
  start_date <- datevect[start]
  end_date <- datevect[end]
  IV <- varvect[start]
  FV <- varvect[end]
  CV <- collapse
  OD=IV-FV
  MD=IV-CV
  res <- tibble(
    start_date,
    end_date,
    period=end_date-start_date,
    `Collapse value`=abs(CV),
    observed=OD,maximum=MD,
    RS=(OD/MD) %>% set_units('1') %>% set_units('%'))
  if (!is.null(errorvect)) {
    ## error propagation (according to https://astro.subhashbose.com/tools/error-propagation-calculator)
    start_error <- errorvect[start]
    end_error <- errorvect[end]
    res$s.e. <- sqrt(((start_error^2 * (CV-FV)^2) + (end_error^2 * (IV-CV)^2) ) / ((IV-CV)^4)) %>% set_units('1')%>% set_units('%')
  }
  return(res)
}