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

// Descargar y descomprimir módulos para cada año
local modules "1631 1632 1635 1637"	// Módulos seleccionados

// Descarga de las módulos

foreach m in `modules'{
	$data
	qui copy https://proyectos.inei.gob.pe/iinei/srienaho/descarga/STATA/910-Modulo`m'.zip 910-Modulo`m'.zip, replace
	qui unzipfile 910-Modulo`m'.zip, replace
}

disp "Descarga y extracción completada de los módulos: `modules' para el año 2023."

// Año 2023: ENDES
qui global mod910_1631 cd "C:\Users\ecoja\Escritorio\TB_Metria\TB_LFP\Data\910-Modulo1631"
qui global mod910_1632 cd "C:\Users\ecoja\Escritorio\TB_Metria\TB_LFP\Data\910-Modulo1632"
qui global mod910_1635 cd "C:\Users\ecoja\Escritorio\TB_Metria\TB_LFP\Data\910-Modulo1635"
qui global mod910_1637 cd "C:\Users\ecoja\Escritorio\TB_Metria\TB_LFP\Data\910-Modulo1637"

**# 2. LIMPIEZA DE MÓDULOS

*************************************
* Módulo 1631: Datos básicos de MEF *
*************************************

$mod910_1631
* Base "REC91" con información de las mujeres, y algunas variables de salud materno-infantil
use "REC91_2023.dta", clear
rename *,lower
save, replace

* Base "REC0111" con información resumen de los hogares de las mujeres seleccionadas
use "REC0111_2023.dta", clear
rename *,lower
save, replace

******************************************************
* Módulo 1632: Nacimientos y conocimiento de métodos *
******************************************************

$mod910_1632
* Base RE223132 con información de fecundidad de la mujer:
use "RE223132_2023.dta",clear
rename *,lower
save , replace

******************************************
* Módulo 1635: Nupcialidad y fecundidad **
******************************************

$mod910_1635
* Base RE516171 con información sobre cuidado y uso de métodos anticonceptivos
use "RE516171_2023.dta",clear
rename *,lower
save, replace


*********************************************************
* Módulo 1637: Mortalidad materna y violencia familiar **
*********************************************************

$mod910_1637
* Base REC84DV con información sobre violencia familiar
use "REC84DV_2023.dta",clear
rename *,lower
save, replace

**# 3. UNIÓN DE BASES DE DATOS

$mod910_1631
use "REC0111_2023.dta", clear
merge 1:1 caseid using "REC91_2023.dta",nogen keepusing(sregion)
$mod910_1632
merge 1:1 caseid using "RE223132_2023.dta", nogen keepusing(v202)
$mod910_1635
merge 1:1 caseid using "RE516171_2023.dta",nogen keepusing(v501 v715)
$mod910_1637
merge 1:1 caseid using "REC84DV_2023.dta", nogen keepusing(d103a-d103d d105a-d105i d109 d113)
drop d103c
$result
save "BD_LFP.dta", replace

**# 4. CREACIÓN DE VARIABLES
$result
use "BD_LFP.dta", clear

* Año
rename id1 Ahno

* Estrato
rename v022 Estrato

* 4.1 Violencia (endógena)

* Sumatoria de los tipos de violencia:
drop if d103a == .
foreach x of varlist d103a-d105i{
recode `x' (0 3=0) (1/2=1)
}
egen Violencia=rowtotal(d103a-d105i) if d103a!=.

lab var Violencia "Cantidad de incidentes de violencia hacia la mujer"

* drop if Violencia == 0

* 4.2 Educación (exógena principal)
*codebook v133
rename v133 Educacion

label var Educacion "Anhos de educacion"

* 4.3 Edad (exógena)
*codebook v149
rename v012 Edad

* 4.4 Zona (exógena)
*codebook v140
rename v140 Zona
drop if Zona == 7
recode Zona (1 = 0) (2 = 1)

label var Zona "Zona de residencia"
label define zona 0 "Zona Rural" 1 "Zona Urbana"
label val Zona zona

* 4.5 Region (exógena)
*codebook sregion
rename sregion Region
recode Region (1/2 = 1) (3 = 2) (4 = 3)

label var Region "Region Natural"
label define region 1 "Costa" 2 "Sierra" 3 "Selva"
label val Region region

* 4.6 Número de hijos (exógena)
*codebook v202
rename v202 Numero_hijos
label var Numero_hijos "Cantidad de hijos de la entrevistada"

* 4.7 Estado Civil (exógena)
*codebook v501
rename v501 Estado_civil

* 4.8 Ocupación de la mujer (exógena)
*codebook v717
*drop if v717 == 98
*rename v717 Ocupacion_mujer

* 4.9 Educación de la pareja (exógena)
*codebook v715
drop if v715 == 98
rename v715 Educacion_pareja
label var Educacion_pareja "Anhos de educacion de la pareja"

* 4.10 Consumo de alcohol de la pareja
*codebook d113
rename d113 Consumo_alcohol
label var Consumo_alcohol "¿Su pareja consume bebidas alcoholicas?"

* Factor de expansion según ficha técnica
gen peso=v005/1000000
label var peso "Factor de ponderacion"

global vars "Ahno caseid Estrato Violencia Educacion Educacion_pareja Edad Numero_hijos Estado_civil Zona Region peso Consumo_alcohol"

order $vars

keep $vars

save "BD_LFP.dta", replace

$result
export excel using "BD_LFP.xlsx", firstrow(variables) replace