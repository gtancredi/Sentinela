#!/bin/bash
# Actualizacion del estado de las estaciones
# se genera el reporte del estado que se pone en el encabezado de ESTADO DE LAS ESTACIONES y en la pagina oculta estado

# Agregar con contrab -e
# */3 * * * * /home/datos2/estacion/bin/bolidosEstado.sh

########################################################
##            PARAMETROS A MODIFICAR                  ##  
########################################################

# - ruta en el servidor de los archivos ESTACIONX_ultima.txt
rutaArchivosUltimos="/home/datos2/estacion/Status"

# - Color del texto 
colorTexto="yellow"

# - Tipo de fuente
tipoFuente="Arial"

# - Tamano de la fuente en tamanoFuente
pixels=20

# - Nombre del archivo temporal que contiene todo el texto
archivoTemporal="archivoTemporalEstado.tmp"

# - Lista de numeros de las estaciones (hay un par imagen, texto x c/estacion)
#listaEstaciones=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 19 21)
listaEstaciones=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)

nEstaciones=${#listaEstaciones[@]}

presente=`date '+%s'`
hora=`date '+%H'`

rm -rf $archivoTemporal
echo "ESTACION  FECHA       HORA UT   STATUS" > $archivoTemporal

noche=`python /home/datos2/estacion/bin/es_noche.py`

if [ $noche == 1 ]
then
    n=0
    while [ ${n} -lt ${nEstaciones} ]
    do
    	estacion=${listaEstaciones[${n}]}
    	estacionn=`echo $estacion | awk '{printf "%02d",$1}'`
    	file=$rutaArchivosUltimos"/ESTACION"$estacion"_ultima.txt"
    
    	if [ -f $file ] 
    	then
    	    fecha=`awk '{ printf "%4.0f/%02d/%02d",$4,$5,$6 }' $file`
    	    hora=`awk '{ printf "%02d:%02d:%02d",$7,$8,$9 }' $file `
    	    fechahora=`awk '{ printf "%4.0f/%02d/%02d %02d:%02d:%02d UTC",$4,$5,$6,$7,$8,$9 }' $file`
    	
    	    ultimaimagen=`date --date="$fechahora" '+%s'`
    	    ultimatrans=`date -r $file '+%s'`
    
    	    diferenciaimagen=$((presente-ultimaimagen))
    	    diferenciatrans=$((ultimaimagen-ultimatrans))
    
    	    if [ $diferenciaimagen -lt 1800 ]
    	    then
    		    status='Operativa'
    	    else
    		    status='Inactiva'	    
    	    fi
    	
    	    echo "$estacionn        $fecha  $hora  $status" >> $archivoTemporal
    	    #echo "ESTACION: $estacionn FECHA: $fecha HORA UT: $hora STATUS: $status" >> $archivoTemporal
    	
    	fi
    	n=$((n+1))
    done
else
    n=0
    while [ ${n} -lt ${nEstaciones} ]
    do
    	estacion=${listaEstaciones[${n}]}
    	estacionn=`echo $estacion | awk '{printf "%02d",$1}'`
    	file=$rutaArchivosUltimos"/ESTACION"$estacion"_ultima.txt"
    
    	if [ -f $file ] 
    	then
    	    fecha=`awk '{ printf "%4.0f/%02d/%02d",$4,$5,$6 }' $file`
    	    hora=`awk '{ printf "%02d:%02d:%02d",$7,$8,$9 }' $file `
    	    fechahora=`awk '{ printf "%4.0f/%02d/%02d %02d:%02d:%02d UTC",$4,$5,$6,$7,$8,$9 }' $file`
    	
    	    echo "$estacionn        $fecha  $hora  De día" >> $archivoTemporal
    #	    echo "ESTACION: $estacionn FECHA: $fecha HORA UT: $hora STATUS: De día" >> $archivoTemporal
    	
    	fi
    	n=$((n+1))
    done    
fi

echo text 10,5 \" > ${rutaArchivosUltimos}"/ESTACION_Status.txt"
cat $archivoTemporal >> ${rutaArchivosUltimos}"/ESTACION_Status.txt"
echo \" >> ${rutaArchivosUltimos}"/ESTACION_Status.txt"

alto=$((nEstaciones*20))
convert -size 450x$alto xc:white -font "FreeMono-Bold" -pointsize 16 -fill black -draw @${rutaArchivosUltimos}"/ESTACION_Status.txt" ${rutaArchivosUltimos}"/ESTACION_Status.png"


rm -f $archivoTemporal
echo "                                ESPACIO ESPACIO ESPACIO   %     App.   noche  nueva   GPS  deltaT  Humedad  Temp.  Heater" > $archivoTemporal
echo "ESTACION  FECHA       HORA UT   total   libre   usado   usado  running        imagen       GPS-PC    %       *C" >> $archivoTemporal
n=0
while [ ${n} -lt ${nEstaciones} ]
do
    estacion=${listaEstaciones[${n}]}
    estacionn=`echo $estacion | awk '{printf "%02d",$1}'`
    file=$rutaArchivosUltimos"/status_ESTACION"$estacion"_ultima.txt"
	if [ -f $file ] 
	then
	    fecha=`awk '{ printf "%4.0f/%02d/%02d",substr($1,0,4),substr($1,5,2),substr($1,7,2) }' $file`
	    hora=`awk '{ printf "%02d:%02d:%02d",substr($1,10,2),substr($1,13,2),substr($1,16,2) }' $file `
	    arduino=`awk '{print length($0)}' $file`
	    if [ $arduino -gt 60 ]
	    then
	        stat=`awk '{printf "%3d     %3d     %3d    %s     %d      %d      %d      %d   %6.2f  %5.1f    %5.1f    %s\n",$2,$3,$4,$5,$6,$7,$8,$9,$10,$12,$15,$19}' $file`
            echo "$estacionn        $fecha  $hora   $stat"  >> $archivoTemporal
        else
            stat=`awk '{printf "%3d     %3d     %3d    %s     %d      %d      %d      %d   %6.2f\n",$2,$3,$4,$5,$6,$7,$8,$9,$10}' $file`
            echo "$estacionn        $fecha  $hora   $stat"  >> $archivoTemporal
        fi
    fi
    n=$((n+1))
done

echo text 10,5 \" > ${rutaArchivosUltimos}"/ESTACION_Status_completo.txt"
cat $archivoTemporal >> ${rutaArchivosUltimos}"/ESTACION_Status_completo.txt"
echo \" >> ${rutaArchivosUltimos}"/ESTACION_Status_completo.txt"

alto=$((nEstaciones*20))
convert -size 1230x$alto xc:white -font "FreeMono-Bold" -pointsize 16 -fill black -draw @${rutaArchivosUltimos}"/ESTACION_Status_completo.txt" ${rutaArchivosUltimos}"/ESTACION_Status_completo.png"

## EOF
