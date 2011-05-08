#!/bin/bash

# Comando mover

# Uso: mover <origen> <destino> [<comando que invoca>]

# Errores: 1-Cantidad erronea de argumentos
#	   2-Archivo origen o directorio destino inexistente
source utils.sh
# Validacion de cantidad de argumentos:
log "Hola"
if [ $# -lt 2 ]
then
	comando_invocante="mover"
	tipo_mensaje="SE"
	mensaje="Faltan argumentos. Uso: mover <origen> <destino> [<comando que invoca>]"
	echo $mensaje
	log "$mensaje" $tipo_mensaje mover
	#./cralog $comando_invocante $tipo_mensaje $comando_invocante $mensaje
	exit 1
fi

if [ $# -gt 3 ]
then
	comando_invocante="mover"
	tipo_mensaje="SE"
	mensaje="Sobran argumentos. Uso: mover <origen> <destino> [<comando que invoca>]"
	echo $mensaje
	log "$mensaje" $tipo_mensaje mover
	#./cralog $comando_invocante $tipo_mensaje $comando_invocante $mensaje
	exit 1
fi

# Validacion de existencia de archivo origen y directorio destino:

origen=$1
destino=$2

if [ ! -e $origen ]
then
	comando_invocante="mover"
	tipo_mensaje="SE"
	mensaje="Archivo origen $origen inexistente"
	echo $mensaje
	log "$mensaje" $tipo_mensaje mover
	#./cralog $comando_invocante $tipo_mensaje $comando_invocante $mensaje
	exit 2
fi

if [ ! -d $destino ]
then
	comando_invocante="mover"
	tipo_mensaje="SE"
	mensaje="Directorio destino $destino inexistente"
	log "$mensaje" $tipo_mensaje mover
	#./cralog $comando_invocante $tipo_mensaje $comando_invocante $mensaje
	exit 2
fi


nombre_archivo=`echo "$origen" | sed 's/^.*\/\(.*\)$/\1/'`
destino="$destino/$nombre_archivo"

if [ -e $destino ] # si el archivo ya existe	
then
	ruta_duplicado="$2/dup"

	if [ ! -d $ruta_duplicado ] # si no existe el directorio /dup lo crea
	then
		mkdir $ruta_duplicado
	fi

	sec=0
	until [ ! -e $archivo_duplicado ]
	do
		let sec=$sec+1
		archivo_duplicado="$ruta_duplicado/$nombre_archivo.$sec"		
	done
	destino=$archivo_duplicado
fi

cp $origen $destino
rm $origen

comando_invocante="mover"
tipo_mensaje="I"
mensaje="Movimiento desde $origen a $destino"
echo $mensaje
#./cralog $comando_invocante $tipo_mensaje $comando_invocante $mensaje

if [ $# -eq 3 ]
then
	comando_invocante="$3"
	echo $mensaje
	log "$mensaje" $tipo_mensaje $3
	#./cralog $comando_invocante $tipo_mensaje $comando_invocante $mensaje
fi

