#!/bin/bash

# Comando mover

# Uso: mover <origen> <destino> [<comando que invoca>]

# Errores: 1-Cantidad erronea de argumentos
#	   2-Archivo origen o directorio destino inexistente

source utils.sh

# Validacion de cantidad de argumentos:
if [ $# -lt 2 ]
then
	TIPO_MENSAJE="SE"
	MENSAJE="Faltan argumentos. Uso: mover <origen> <destino> [<comando que invoca>]"
	log "$MENSAJE" $TIPO_MENSAJE mover
	exit 1
fi

if [ $# -gt 3 ]
then
	TIPO_MENSAJE="SE"
	MENSAJE="Sobran argumentos. Uso: mover <origen> <destino> [<comando que invoca>]"
	log "$MENSAJE" $TIPO_MENSAJE mover
	exit 1
fi

# Validacion de existencia de archivo origen y directorio destino:

ORIGEN=$1
DESTINO=$2

if [ ! -e $ORIGEN ]
then
	TIPO_MENSAJE="SE"
	MENSAJE="Archivo origen $ORIGEN inexistente"
	log "$MENSAJE" $TIPO_MENSAJE mover
	exit 2
fi

if [ ! -d $DESTINO ]
then
	TIPO_MENSAJE="SE"
	MENSAJE="Directorio destino $ORIGEN inexistente"
	log "$MENSAJE" $TIPO_MENSAJE mover
	exit 2
fi


NOMBRE_ARCHIVO=`echo "$ORIGEN" | sed 's/^.*\/\(.*\)$/\1/'`
DESTINO="$DESTINO/$NOMBRE_ARCHIVO"

if [ -e $DESTINO ] # si el archivo ya existe	
then
	RUTA_DUPLICADO="$2/dup"

	if [ ! -d $RUTA_DUPLICADO ] # si no existe el directorio /dup lo crea
	then
		mkdir $RUTA_DUPLICADO
	fi

	SEC=0
	until [ ! -e $ARCHIVO_DUPLICADO ]
	do
		let SEC=$SEC+1
		ARCHIVO_DUPLICADO="$RUTA_DUPLICADO/$NOMBRE_ARCHIVO.$SEC"		
	done
	DESTINO=$ARCHIVO_DUPLICADO
fi

cp $ORIGEN $DESTINO
rm $ORIGEN

TIPO_MENSAJE="I"
MENSAJE="Movimiento desde $ORIGEN a $DESTINO"
log "$MENSAJE" $TIPO_MENSAJE mover

if [ $# -eq 3 ]
then
	COMANDO_INVOCANTE="$3"
	log "$MENSAJE" $TIPO_MENSAJE $COMANDO_INVOCANTE
fi

