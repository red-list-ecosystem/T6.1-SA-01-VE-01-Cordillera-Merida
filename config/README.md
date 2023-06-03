# Quarto

Create project and render a preview of the document:

```sh
conda deactivate
cd ~/proyectos/IUCN-RLE
quarto create-project T6.1-SA-01-VE-01-Cordillera-Merida --type book
quarto render T6.1-SA-01-VE-01-Cordillera-Merida

quarto preview T6.1-SA-01-VE-01-Cordillera-Merida

##quarto render T6.1-SA-01-VE-01-Cordillera-Merida --to pdf
```

Trying to render the book with a pdf output option throws an error:

```sh
Error: path for html_dependency not found: /var/folders/14/vyrp_30975d7y17lqxjblf2c0000gn/T//RtmpTv7Ea9
```
This seems to be related to the use of leaflet in the code. Should I create a branch for the pdf output without the interactive map?

Another option is to use a different subfolder with its own quarto.yml file to create a pdf document with different rules and composition as the html book. We trial this in a sepparate branch and test with:

```sh
quarto render suppl-mat/
```


## Citation and bibliography

- https://qmd4sci.njtierney.com/citations-and-styles
- https://github.com/citation-style-language/styles
- https://citationstyles.org/authors/

```{bash}
cd bibTeX
wget https://raw.githubusercontent.com/citation-style-language/styles/master/oryx.csl
```
# Update MacTeX

```sh
tlmgr update --list
## tlmgr: Local TeX Live (2021) is older than remote repository (2022).
## ...
```

This https://tug.org/texlive/upgrade.html suggest a new installation... I will use the package provided here: https://tug.org/mactex/

Then:

```sh
sudo tlmgr update --self --all
```

# Populate a sandbox folder with data

All data files shared via OSF cloud storage

To use OSF functions in R, need to install package `osfr` and add a personal access token to the `.Renviron` file in home directory.

See `download-data.R` file for download instructions.

# Populate Rdata folder

Cherry-picking output data from the analysis for display in this document

```sh
scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/z3529065/output/T6.1-tropical-glaciers/OUTPUT/bioclim-data-groups.rda Rdata/
scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/z3529065/output/T6.1-tropical-glaciers/OUTPUT/assessment-data-Cordillera-de-Merida.rda Rdata

scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/z3529065/output//T6.1-tropical-glaciers/OUTPUT/Group-29/modis-LST-and-CHIRPS.rda Rdata
scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/z3529065/output//T6.1-tropical-glaciers/OUTPUT/Group-29/RS-at-climate-station.rda Rdata
scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/z3529065/output//T6.1-tropical-glaciers/OUTPUT/gbm-model-Cordillera-de-Merida Rdata

scp $zID@kdm.restech.unsw.edu.au:/srv/scratch/z3529065/output/T6.1-tropical-glaciers/OUTPUT/trop-glacier-classified.rda Rdata/

```

# git / GitHub

```sh
git remote add origin git@github.com:red-list-ecosystem/T6.1-tropical-glaciers-docs.git
git push -u origin main
```

## git lfs

Download binary from https://git-lfs.github.com/
```sh
cd ~/Downloads/git-lfs-3.2.0/
./install.sh
```

Then we can initialise lfs in repository and add the files
```sh
git lfs install
git lfs track "*.rda"
git add .gitattributes
git add Rdata
git commit -m "track *.rda files using Git LFS"
```

If we have problems check this https://github.blog/2017-06-27-git-lfs-2-2-0-released/:
```sh
git lfs migrate info
git lfs migrate import --include="*.rda"
```
