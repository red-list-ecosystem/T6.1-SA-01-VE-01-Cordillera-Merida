dot -Teps -Gsize=7,5\! -osandbox/CEM-Venezuela-TGE.eps assets/CEM-Venezuela-TGE.gv 
## 170 mm according to:
## set_units(170,mm) %>% set_units(inches)
dot -Tpng -Gsize=6.69,4\! -Gdpi=600 -osandbox/CEM-Venezuela-TGE.png assets/CEM-Venezuela-TGE.gv 

dot -Tpng -Gsize=10 -Gdpi=300 -osandbox/Graphical-assessment-summary.png assets/Data-sources-Venezuela.gv 

dot -Tpng -Gsize=5,5 -Gdpi=300 -osandbox/Types-of-data.png assets/Types-of-data.gv
dot -Tpng -Gsize=5,5 -Gdpi=300 -osandbox/Data-sources.png assets/Simplified-data-sources.gv
