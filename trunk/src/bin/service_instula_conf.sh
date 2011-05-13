#!/bin/bash

# SERVICIO DESTINADO A MANEJAR EL ARCHIVO DE CONFIGURACION DE INSTULA
#
# 1- Un solo parametro indica un GET sobre la variable de entorno
# 2- Dos parametros indica un SET sobre la variable o la creacion,
#    en caso de que no exista

# Valido que se pasen 1 o 2 parametros
if [ $# != 1 -a $# != 2 ]
then
	exit 1
fi

NOMBRE=$1
VALOR=$2

# Indico la posicion del archivo de configuracion
#INSTULA_CONF="$PWD/instula.conf"
CURR="$PWD"
SCRIPT_DIR="`dirname "$0"`"
if [ -z "$SCRIPT_DIR" ]
then
	COMPLETE="$CURR"
else
	COMPLETE="$SCRIPT_DIR"
fi

if [ ! -f "$COMPLETE/service_instula_conf.conf" ]
then
	echo "No se puede inicializar el servicio, requiere de $COMPLETE/service_instula_conf.conf"
	return
else
	INSTULA_CONF="`cat "$COMPLETE/service_instula_conf.conf"`"
fi

#cd "$SCRIPT_DIR"
#INSTULA_CONF="$CURR/conf/instula.conf"

if [ ! -f "$INSTULA_CONF" ]
then
	>>"$INSTULA_CONF"
fi

# Evaluo que exista el nombre de esa variable
EXISTE_VARIABLE=`cat "$INSTULA_CONF" | grep "$NOMBRE"`

# Si el valor contiene algo significa que quieren hacer un SET
if [ -z  "$VALOR" ]
then
	echo `echo "$EXISTE_VARIABLE" | cut -f2 -d\=`
else
	if [ -z "$EXISTE_VARIABLE" ]
	then
		# Si no existe la variable la escribo en el archivo
		echo "$NOMBRE=$VALOR">>"$INSTULA_CONF"
	else
		# Modifico el valor de la variable
		sed -i "s/$NOMBRE.*/$NOMBRE=$VALOR/" "$INSTULA_CONF"
	fi
fi
#cd "$CURR"
