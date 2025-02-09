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
merge 1:1 caseid using "REC84DV_2023.dta", nogen keepusing(d103a d103b d103d d105a-d105g d105h-d105i d109 d113)
$result
save "BD_LFP.dta", replace