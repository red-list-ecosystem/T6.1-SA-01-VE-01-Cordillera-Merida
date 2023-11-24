INDIR=assets
OUTDIR=assets


dot -Teps -Gsize=7,5\! -o${OUTDIR}/CEM-Venezuela-TGE.eps ${INDIR}/CEM-Venezuela-TGE.gv 
## 170 mm according to:
## set_units(170,mm) %>% set_units(inches)
dot -Tpng -Gsize=6.69,4\! -Gdpi=600 -o${OUTDIR}/CEM-Venezuela-TGE.png ${INDIR}/CEM-Venezuela-TGE.gv 

dot -Tpng -Gsize=6.69,4\! -Gdpi=600 -o${OUTDIR}/CEM-legend.png ${INDIR}/CEM-legend.gv

dot -Tpng -Gsize=5,7 -Gdpi=300 -o${OUTDIR}/Graphical-assessment-summary.png ${INDIR}/Data-sources-Venezuela.gv 

dot -Tpng -Gsize=5,5 -Gdpi=300 -o${OUTDIR}/Types-of-data.png ${INDIR}/Types-of-data.gv
dot -Tpng -Gsize=5,5 -Gdpi=300 -o${OUTDIR}/Data-sources.png ${INDIR}/Simplified-data-sources.gv

dot -Tsvg -Gsize=1,1 -oalt-report/CR.svg assets/CR.gv
