#!/bin/bash

# Requiere jpeginfo, ImageMagick (que incluye convert)
#
########################################################
##            PARAMETROS A MODIFICAR                  ##  
########################################################

# - ruta en el servidor de los archivos ESTACIONX_ultima.jpg
rutaArchivosUltimos="/home/datos2/estacion/Status"
# - ruta en el servidor de los archivos Viejos
rutaArchivosViejos="/home/datos2/estacion/Status/Viejos"

# - Color del texto 
colorTexto="yellow"

# - Tipo de fuente
tipoFuente="FreeMono"

# - Tamano de la fuente en pixels
tamanoFuente=20

# - Nombre del archivo temporal que contiene todo el texto
archivoTemporal="archivoTemporalTexto.tmp"

# - Lista de numeros de las estaciones (hay un par imagen, texto x c/estacion)
#listaEstaciones=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 19 21)
listaEstaciones=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)
# tipoEstaciones:
#  w - Watec
#  a - ASI
#tipoEstaciones=('a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'w')
tipoEstaciones=('a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a' 'a')

nEstaciones=${#listaEstaciones[@]}

########################################################
##            Fin MODIFICACION PARAMETROS             ##
########################################################

#########################################################
##       FUNCION PARA ARMAR EL TEXTO                   ##
#########################################################
#  En el cuerpo de la funcion se define la estructura
#  de como se despliega el texto, se arma usando "echo" 
#  (o "print"). 
#  Por ej: cada campo en una linea distinta:
#  
#      ESTACION: 1
#      FECHA: AAAA-MM-DD
#      HORA LOCAL: HH:MM:SS
#
# Otro ej en una sola linea:
#
#     ESTACION: 1   FECHA: AAAA-MM-DD   HORA LOCAL: HH:MM::SS
#
# Tener en cuenta el tamano de la imagen a crear y el de la fuente
# en los parametros de modificacion

armarTexto ()
{
    
   # $1 hace referencia al nro de estacion
   # $2  ""      ""     la fecha
   # $3  ""      ""     a la hora
   
     # armo el texto en una sola linea
   
   echo "ESTACION: $1  FECHA: $2  HORA UT: $3"
}         
######################################################
##      FIN FUNCION  ARMAR TEXTO                    ##
######################################################


dayyesterday=`date -d yesterday '+%Y%m%d'`
daytoday=`date '+%Y%m%d'`

cd $rutaArchivosViejos

n=0
while [ ${n} -lt ${nEstaciones} ]
do
    estacion=${listaEstaciones[${n}]}

    listtxt=`ls 'ESTACION'$estacion'_'$dayyesterday'-'2[0-3]*'.txt' 'ESTACION'$estacion'_'$daytoday'-'0[0-9]*'.txt' 2> /dev/null`
    if [ ${#listtxt} -gt 0 ] 
    then
    	list=`echo $listtxt | sed 's/.txt//g'`
    	listjpg=''
    	listtxt2=''
    	for file in $list
    	do
    	    if ! (( $(jpeginfo -c "$file".jpg | grep -c -E "WARNING|ERROR") ))
    	    then
        	    tipo=${tipoEstaciones[${n}]}
        
        	    if [ "$tipo" = "a" ] 
        	    then
        		convert "$file".jpg -resize 25% imagen_tmp.jpg
        	    else
        		cp "$file".jpg imagen_tmp.jpg
        	    fi
        	    
        	    # Hallar taman~o de imagen
        	    w=`identify -format '%w' imagen_tmp.jpg`
        	    h=`identify -format '%h' imagen_tmp.jpg`
        	    # Aumentar el alto
        	    hn=$((h + 50))
        	    
        	    # - posicion inicial del texto en imagen final en pixeles 
        	    #  El origen es el centro de la imagen X positivo hacia izq, y positivo hacia abajo
        	    #   (ver opcion "gravity" en "convert", el valor de X no importa, esta centrado)   
        	    posicionIniX=0
        	    posicionIniY=$h
        
                   fecha=`awk '{ printf "%4.0f/%02d/%02d",$4,$5,$6 }' "$file".txt`
              	   hora=`awk '{ printf "%02d:%02d:%02d",$7,$8,$9 }' "$file".txt`
           	   
        	   # El comando convert convierte un archivo de texto a una imagen, el formato
        	   # del archivo de texto para convert, requiere como encabezado "text posicionIniX,posicionIniY"
        	   # y todo el texto a convertir entre comillas dobles, estas lineas arman el encabezado
           	   # llama a la funcion que arma el texto
        	   texto=`armarTexto $estacion $fecha $hora`
        	   echo text $posicionIniX,$posicionIniY \'$texto\' > $archivoTemporal
        
        	   # creo la imagen con convert, la imagen creada es "imagenNROESTACION.png"
        	   # junto con ESTACIONX-ultimajpg se copian al servidor web 
        	   convert imagen_tmp.jpg -gravity North -background black -extent ${w}x${hn} \
        	       -pointsize $tamanoFuente  -fill $colorTexto \
        	       -draw @$archivoTemporal "$file"_Texto.jpg
        	   
        	   listjpg+=' '"$file"_Texto.jpg 
        	   listtxt2+=' '"$file".txt 
            fi
    	done
    	# listjpg="`echo $list | sed 's/ /_Texto.jpg /g'`_Texto.jpg"
    	convert -delay 10 -loop 0 $listjpg $rutaArchivosUltimos'/ESTACION'"$estacion"'.gif'
    
        cat $listtxt2 | awk '{printf "%s %4d%2.2d%2.2d-%2.2d:%2.2d:%2.2d\n",$2,$4,$5,$6,$7,$8,$9}' > $rutaArchivosUltimos'/Resumen/Resumen'"$estacion"'_'"$daytoday"'.txt'
    
    	rm -rf $archivoTemporal
    	rm -rf imagen_tmp.jpg
    	rm -rf *_Texto.jpg
    else
	    echo "La lista de la estacion " $n " esta vacia"
    fi    

    liststat=`ls 'status_ESTACION'$estacion'_'$dayyesterday'-'1[2-9]*'.txt' 'status_ESTACION'$estacion'_'$dayyesterday'-'2[0-3]*'.txt' 'status_ESTACION'$estacion'_'$daytoday'-'0[0-9]*'.txt' 'status_ESTACION'$estacion'_'$daytoday'-'1[0-1]*'.txt' 2> /dev/null`
    if [ ${#liststat} -gt 0 ] 
    then
        cat $liststat > $rutaArchivosUltimos'/Resumen/status_Resumen'"$estacion"'_'"$daytoday"'.txt'
    fi
    
    n=$((n+1))
done

## EOF
