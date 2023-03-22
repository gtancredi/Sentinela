#!/bin/bash

# se une la imagen y texto y se crea una nueva imagen con el nombre ESTACION#_ultimaTexto.jpg

# Agregar con contrab -e
#  */3 0-7,18-23 * * * /home/datos2/estacion/bin/bolidosImagenesWeb.sh

########################################################
##            PARAMETROS A MODIFICAR                  ##  
########################################################

# - ruta en el servidor de los archivos ESTACIONX_ultima.jpg
rutaArchivosUltimos="/home/datos2/estacion/Status"

# - Color del texto 
colorTexto="yellow"

# - Tipo de fuente
tipoFuente="FreeMono"

# - Tamano de la fuente en pixels
tamanoFuente=20

# - Nombre del archivo temporal que contiene todo el texto
archivoTemporal="archivoTemporalTexto.tmp"

# - Ruta del archivo con la imagen creada con el texto (con formato)
rutaImagenTexto="/home/datos2/estacion/Status"

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
##            FIN MODIFICACION PARAMETROS             ##
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

n=0
while [ ${n} -lt ${nEstaciones} ]
do
    estacion=${listaEstaciones[${n}]}
    file=$rutaArchivosUltimos"/ESTACION"$estacion"_ultima.txt"

    if [ -f $file ] 
    then
	tipo=${tipoEstaciones[${n}]}
	
	if [ "$tipo" = "a" ] 
	then
	    convert $rutaArchivosUltimos"/ESTACION"$estacion"_ultima.jpg" -resize 25% $rutaArchivosUltimos"/imagen_tmp.jpg"
	else
	    cp $rutaArchivosUltimos"/ESTACION"$estacion"_ultima.jpg" $rutaImagenTexto"/imagen_tmp.jpg"
	fi
	
	# Hallar taman~o de imagen
	w=`identify -format '%w' $rutaImagenTexto"/imagen_tmp.jpg"`
	h=`identify -format '%h' $rutaImagenTexto"/imagen_tmp.jpg"`
	# Aumentar el alto
	hn=$((h + 50))
	
	# - posicion inicial del texto en imagen final en pixeles 
	#  El origen es el centro de la imagen X positivo hacia izq, y positivo hacia abajo
	#   (ver opcion "gravity" en "convert", el valor de X no importa, esta centrado)   
	posicionIniX=0
	posicionIniY=$((h+20))
	
	fecha=`awk '{ printf "%4.0f/%02d/%02d",$4,$5,$6 }' $file`
	hora=`awk '{ printf "%02d:%02d:%02d",$7,$8,$9 }' $file `
	
	# El comando convert convierte un archivo de texto a una imagen, el formato
	# del archivo de texto para convert, requiere como encabezado "text posicionIniX,posicionIniY"
	# y todo el texto a convertir entre comillas, estas lineas arman el encabezado
	# llama a la funcion que arma el texto
	texto=`armarTexto $estacion $fecha $hora`
	echo text $posicionIniX,$posicionIniY \'$texto\' > $archivoTemporal
	
	# cierra las comillas luego de armar el texto, requerido por convert   
	#echo '"' >> $archivoTemporal
	#   	cat $archivoTemporal
	
	# creo la imagen con convert, la imagen creada es "imagenNROESTACION.png"
	# junto con ESTACIONX-ultimajpg se copian al servidor web
	# convert -background "black" -font $tipoFuente -pointsize $tamanoFuenteE  -fill $colorTexto \
	convert $rutaImagenTexto/imagen_tmp.jpg -gravity North -background black -extent ${w}x${hn} \
	       -pointsize $tamanoFuente  -fill $colorTexto \
	       -draw @$archivoTemporal $rutaImagenTexto/ESTACION"$estacion"_ultimaTexto.jpg


    fi
    n=$((n+1))
done

rm -rf $archivoTemporal
rm -rf $rutaImagenTexto/imagen_tmp.jpg
## EOF
