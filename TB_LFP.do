clear
set more off
cls

/***********************************************
		TF - Introducción a la Econometría
					L-F-P
		Tema - Violencia hacia la mujer				
***********************************************/

**# 1. SETEO DE VARIABLES GLOBALES Y DESCARGA DE MÓDULOS

global data cd "C:\Users\ecoja\Escritorio\TB_Metria\TB_LFP\Data"
global result cd "C:\Users\ecoja\Escritorio\TB_Metria\TB_LFP\Resultados"

$result
use "BD_LFP.dta", clear

// Histograma de Violencia
histogram Violencia, frequency title("Histograma de Violencia") xtitle("Cant. incidentes de violencia") ytitle("Frecuencia") width(5) normal

graph export "Histograma_Violencia.png", as(png) name("Graph") replace

**# 1. Estimación por MCO
	reg Violencia Educacion Educacion_pareja Edad Numero_hijos i.Estado_civil i.Zona i.Region i.Consumo_alcohol
	estimates store modelo1
	
	outreg2 using resultados_finales.doc, replace ctitle(Modelo Base) label

**# 2. Pruebas econométricas

	// Test de Multicolinealidad
	estat vif
	
	// Test de Variables Omitidas
	ovtest
	
	// Test de Heterocedasticidad
	qui reg Violencia Educacion Educacion_pareja Edad Numero_hijos i.Estado_civil i.Zona i.Region i.Consumo_alcohol
	gen n=_n
	predict resid, residuals
	gen resid2=resid^2
	
	// Gráfico de residuos al cuadrado vs. número de observación
	twoway (line resid2 n, lcolor(blue) lwidth(medium)), ///
		title("Residuos al Cuadrado vs. Número de Observación") ///
		xtitle("Número de Observación") ///
		ytitle("Residuos al Cuadrado")
	graph export "G2_Hetero.png", as(png) name("Graph") replace
	
	qui reg Violencia Educacion Educacion_pareja Edad Numero_hijos i.Estado_civil i.Zona i.Region i.Consumo_alcohol
	predict y_est, xb
	
	// Gráfico de residuos al cuadrado vs. valores ajustados
	twoway (scatter resid2 y_est, mcolor(red) msymbol(circle)), ///
		title("Residuos al Cuadrado vs. Valores Ajustados") ///
		xtitle("Valores Ajustados") ///
		ytitle("Residuos al Cuadrado")
	graph export "G1_Hetero.png", as(png) name("Graph") replace
	
	estat imtest, white
	estat hettest, rhs
	*p-value < 0.05, entonces se rechaza la H0, existe problema de Heterocedasticidad
	
**# 3. Correción de Heterocedasticidad
	

	use "BD_LFP.dta", clear
	
	reg Violencia Educacion Educacion_pareja Edad Numero_hijos i.Estado_civil i.Zona i.Region i.Consumo_alcohol, vce (robust)
	estimates store modelo2
	

	outreg2 using resultados_finales.doc, append ctitle(Modelo Robusto) label

**# 4. Modelo Significativo (solo variables significativas)

	*clear
	*set more off
	*cls
	
	use "BD_LFP.dta", clear
		
	// Dropeo de variables
	drop if Violencia == 0
	
	reg Violencia Educacion Educacion_pareja Edad Numero_hijos i.Estado_civil i.Zona i.Region i.Consumo_alcohol
	estimates store modelo_1
	
	outreg2 using resultados_corregido.doc, replace ctitle(Modelo Base Drop) label

	estat imtest, white
	
	// Heterocedasticidad Corregida
	
	reg Violencia Educacion Educacion_pareja Edad Numero_hijos i.Estado_civil i.Zona i.Region i.Consumo_alcohol, vce (robust)
	estimates store modelo_2

	outreg2 using resultados_corregido.doc, append ctitle(Modelo Robusto Drop) label
	
	*esttab mco_sin_factor mco_con_factor, title("Comparación de Estimaciones")
	*estimates stats mco_sin_factor mco_con_factor


**# 5. Modelo Adicional
/*
	svyset id_persona [pw=factora07]
	svy: reg Violencia Educacion Educacion_pareja Edad Numero_hijos i.Estado_civil i.Zona i.Region i.Consumo_alcohol
	estimates store modelo3
	$result
	outreg2 using resultados_finales.doc, append ctitle(Modelo con Factor) label
*/	