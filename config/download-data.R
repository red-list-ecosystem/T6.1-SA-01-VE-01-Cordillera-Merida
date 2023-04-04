here::i_am("config/download-data.R")
target.dir <- "sandbox"
if (!file.exists(here::here(target.dir)))
  dir.create(here::here(target.dir))

library(osfr)
osfid <- "n73wk"
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s",osfid))

project_files <- osf_ls_files(osf_project)
osf_download(project_files, path=here::here(target.dir))

unzip (here::here(target.dir,"GIS-data-VEN.zip"),
       exdir=here::here(target.dir))


# Done !