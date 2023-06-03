require(units)
require(sf)
require(tidyr)
library(ggplot2)
library(dplyr)
library(grid)

require(RColorBrewer)

here::i_am("inc/figures-for-manuscript.R")
target.dir <- "sandbox"
load(here::here(target.dir,"assessment-data-Cordillera-de-Merida.rda"))
#load(here::here(target.dir,"gbm-model-Cordillera-de-Merida.rda"))
load(here::here(target.dir,"mb-year-collapse-Cordillera-de-Merida.rda"))
#rslts <- readRDS(here::here(target.dir,"gbm-RS-Cordillera-de-Merida.rds"))
source(here::here("inc","functions.R"))

old <- theme_set(theme_classic())
#theme_update(panel.grid.minor = element_line(colour = "pink"),
#             panel.grid.major = element_line(colour = "rosybrown3"))


# Fig 3 decline extent ----------------------------------------------------


# Table 1 in Ramirez et al 2020
peaks <- rep(c('La Concha','Bolivar','Humboldt'),c(2,3,7))
year <- set_units(c(1910,1952,1910,1952,1998,1910,1952,1998,2009,2015,2016,2019),year)
glacier_area <- c(0.379,	0.103,	1.273,	0.601,	0.047,	3.374,	1.613,	0.386,	0.164,	0.11,	0.079,	0.045) %>% set_units(km^2)
glacier_area_se <- c(NA,0.008,NA,0.04,0.009,NA,0.044,0.027,0.019,0.005,0.005,0.004) %>% set_units(km^2)
perimeter <- c(3.98,2.15,7.16,10.39,1.69,11.48,11.62,4.99,3.32,2.13,2.27,1.46) %>% set_units(km)
terminus <- c(4420,4623,4280,4482,4735,4280,4460,4620,4720,4740,4780,4800)%>% set_units(m)

ven_rslts <- tibble(peaks,years=year,glacier_extent=glacier_area,glacier_extent_error=glacier_area_se,perimeter,terminus)
# rslts %>% drop_units %>% dplyr::select(1:4) %>% rename(Peak=peaks,Year=years,`Extent (km^2)`=glacier_extent,`S.E. (km^2)`=glacier_extent_error) %>% knitr::kable()

totals <- ven_rslts %>% group_by(years) %>%
  summarise(
    eco_extent=sum(glacier_extent),
    error_extent=sqrt(sum(glacier_extent_error^2,na.rm=T))
  )
totals$error_extent[1] <- max(totals$error_extent)


mod1 <- glm(eco_extent~years,data=totals %>% drop_units, weights=1/sqrt(error_extent),
            family=quasipoisson(log))
prd1 <- futurePred(mod1,eval.years=1910:2040)

mod2 <- glm(eco_extent~years,data=totals %>% drop_units %>% filter(years>1990) , weights=1/sqrt(error_extent),
            family=quasipoisson(log))
prd2 <- futurePred(mod2,eval.years=1990:2048)

figa <- ggplot() + #geom_point(data=rslts,aes(y=glacier_extent,x=years,colour=peaks)) +
  geom_point(data=totals %>% drop_units,
             aes(y=eco_extent,x=years)) +
  #geom_errorbar(data=totals %>% drop_units,
  #              aes(x=years,ymax=eco_extent+error_extent,
  #                  ymin=eco_extent-error_extent)) +
  geom_line(data=prd1,aes(x=years,y=best),color='grey33') +
  geom_ribbon(data=prd1,aes(x=years,ymin=lower,ymax=upper),fill="grey77",alpha=.2) +
  xlab("Year") + ylab("Extent [km²]") 


figb <- figa + coord_cartesian(xlim=c(1990,2040),ylim=c(0,1)) +
  geom_line(data=prd2,aes(x=years,y=best),color='grey33', lty=2) 
#  geom_ribbon(data=prd2,aes(x=years,ymin=lower,ymax=upper),fill="whitesmoke",alpha=.5)

png(here::here(target.dir,"fig3-decline-extent.png"),
    width=120,height=120,res=600, units="mm")
vp <- viewport(width = 0.5, height = 0.5, x = 0.7, y = 0.7)
print(figa + scale_x_continuous(breaks=c(1910,1950,1990,2030)))
print(figb + scale_x_continuous(breaks=c(1990,2015,2040)), vp = vp)
dev.off()


# Fig 4 degradation FLH ---------------------------------------------------

FLH.lo <- loess(FLH ~ years, FLH.df)
prdTS <- predict(FLH.lo, data.frame(years=c(1960:2010)), se = TRUE)
#max(c(1960:2010)[(prdTS$fit - prdTS$se.fit) < 4840])
#max(c(1960:2010)[(prdTS$fit) < 4840])
#max(c(1960:2010)[(prdTS$fit + prdTS$se.fit) < 4970])

bls <- brewer.pal(6,"Greys")

peak_height <- tibble(
  peak=c("La Concha (1952)","Bolívar (1998)","Humboldt (2019)"),
  year=c(1956,1998,1980),
  hmin=c(4623,4745,4720),
  hmax=c(4840,4970,4920))

png(here::here(target.dir,"fig4-trend-flh.png"),
    width=80,height=80,res=600, units="mm")
ggplot() +
  geom_hline(data=peak_height,aes(yintercept=hmax),lty=2,linewidth=0.3) +
  geom_label(data=peak_height,aes(x=year,y=hmax,label=peak),size=2) +
  geom_smooth(data=FLH.df,aes(x=years,y=FLH),
              formula = y ~x,
              method = loess,
              linewidth=0.6,
              colour='grey33',fill='grey77') +
#  geom_line(data=FLH.df,aes(x=years,y=FLH),colour=bls[4], lty=3) +
#  geom_point(data=FLH.df,aes(x=years,y=FLH),colour=bls[5]) + 
  scale_colour_brewer(palette = "Dark2") +
   theme(legend.position = "none") +
  labs(x='Year',y='Freeze Level Height [m]')
dev.off()


# Fig 5 Year of collapse ---------------------------------------------------


ycdata <- ycdata %>% 
  filter(!ssp %in% "SSP1-1.9")

label_xy <- tibble(ssp=unique(ycdata$ssp),
                   x=c(2085, 2085, 2068, 2055), 
                   y=c(.58,.92,.85,.65))

png(here::here(target.dir,"fig5-year-of-collapse.png"),
    width=80,height=80,res=600, units="mm")
ggplot(data=ycdata) +
  #  geom_histogram(aes(x=collapse_year,fill=scn)) +
  stat_ecdf(aes(x=collapse_year,
                #color = ssp,
                linetype = ssp), 
            geom = "step") +
  stat_ecdf(aes(x=collapse_year), 
            geom = "step",lwd=1.3) +
  geom_label(
    aes(x=x,y=y,label = ssp, 
        #color=ssp
        ), data = label_xy,
    size = 1.5) +
  xlab("Year of collapse") +
  ylab("Cummulative proportion of models") +
  theme(legend.position = "none")
dev.off()
