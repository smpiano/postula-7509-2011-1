#!/bin/bash

# Este script pretende limpiar las estructura de directorios que creo el comando de instalacion de instula
# Correrlo desde donde se encuentra service_instula_conf

echoVars () {
  echo "$1=$2"
}

CURRDIR="`./service_instula_conf.sh  CURRDIR`" # CURRDIR no se borra.
ARRIDIR="`./service_instula_conf.sh  ARRIDIR`"
BINDIR="`./service_instula_conf.sh  BINDIR`"
CONFDIR="`./service_instula_conf.sh  CONFDIR`"
LOGDIR="`./service_instula_conf.sh  LOGDIR`"
DATADIR="`./service_instula_conf.sh  DATADIR`"
NUEVOS="`./service_instula_conf.sh  NUEVOS`"
RECIBIDOS="`./service_instula_conf.sh  RECIBIDOS`"
PROCESADOS="`./service_instula_conf.sh  PROCESADOS`"
RECHAZADOS="`./service_instula_conf.sh  RECHAZADOS`"
LISTDIR="`./service_instula_conf.sh  LISTDIR`"


if [ -d "$CURRDIR" -a -d "$ARRIDIR" -a -d "$BINDIR" -a -d "$CONFDIR" -a -d "$LOGDIR" -a -d "$DATADIR" -a -d "$NUEVOS" -a -d "$RECIBIDOS" -a -d "$PROCESADOS" -a -d "$RECHAZADOS" -a -d "$LISTDIR" ]
then
  echo "Borrando estructuras.."
  rm -rfv "$ARRIDIR"
  rm -rfv "$LOGDIR"
  rm -rfv "$DATADIR"
  rm -rfv "$CURRDIR/inst"
  rm -rfv "$NUEVOS"
  rm -rfv "$RECIBIDOS"
  rm -rfv "$PROCESADOS"
  rm -rfv "$RECHAZADOS"
  rm -rfv "$CONFDIR"
  rm -rfv "$LISTDIR"
  rm -v "$BINDIR/*.sh"
else
  echo "No puede borrar alguno de los directorios no esta bien configurado en instula.conf"
  echo "ARRIDIR=$ARRIDIR"
  echo "LOGDIR=$LOGDIR"
  echo "DATADIR=$DATADIR"
  echo "NUEVOS=$NUEVOS"
  echo "RECIBIDOS=$RECIBIDOS"
  echo "PROCESADOS=$PROCESADOS"
  echo "RECHAZADOS=$RECHAZADOS"
  echo "CONFDIR=$CONFDIR"
  echo "BINDIR=$BINDIR"
fi
