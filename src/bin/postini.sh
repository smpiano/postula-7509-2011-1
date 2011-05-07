#!/bin/bash

# Funcion que imprime el valor de las variables
evariables () {
  echo "CURRDIR=$CURRDIR";
  echo "GRUPO=$GRUPO";
  echo "ARRIDIR=$ARRIDIR";
  echo "BINDIR=$BINDIR";
  echo "CONFDIR=$CONFDIR";
  echo "DATASIZE=$DATASIZE";
  echo "LOGDIR=$LOGDIR";
  echo "MAXLOGSIZE=$MAXLOGSIZE";
  echo "USERID=$USERID";
  echo "FECINS=$FECINS";
  echo "PATH=$PATH";
}

# Funcion que corre POSTONIO
runPostonio () {
  #Nico tiene que editar aca.
  #./postonio.sh start
  EXIT=`echo $?`
  if [ $EXIT != 0 ]
  then
    echo "Analizar error"
  else
    echo "POSTONIO ha sido puesto en ejecucion"
  fi
}

# Funcion que verifica la existencia del directorio
exist () {
  if [ -d "$1" ]
  then
    echo "Verificando ruta \"$1\" OK"
  else
    echo "La ruta \"$1\" no existe, necesita crear dicha ruta para ejecutar POSTINI"
  fi
}

echo "...::: POSTINI :::..."

# Necesidad del pasaje de un parametro
#if [ $# != 1 ] 
#then
#  echo "Se debe pasar un parametro, el nombre del demonio POSTONIO [para test usar: xorg]"
#  exit 1
#fi


# Comando que verifica la existencia de las variables de inicializacion de ambiente
CHECK=`echo $PATH | grep 'grupo02'`

if [ ! -z "$CHECK"  ]
then
  echo "ADVERTENCIA: las variables de entorno ya fueron seteadas"

  # Imprimo variables
  evariables
else

  # Seteo las variables de entorno para la sesion del usuario (la idea seria que me lleguen como parametro)
  CURRDIR="$PWD"                                # Directorio Actual de trabajo 
  GRUPO=`./service_instula.sh GRUPO`            # Directorio del grupo
  ARRIDIR=`./service_instula.sh ARRIDIR`        # Directorio de arribos de archivos externos 
  BINDIR=`./service_instula.sh BINDIR`          # Directorio para los ejecutables
  CONFDIR=`./service_instula.sh CONFDIR`        # Directorio para los archivos de configuracion
  DATASIZE=`./service_instula.sh DATASIZE`      # Espacio minimo necesario en el directorio ARRIDIR en Mb
  LOGDIR=`./service_instula.sh LOGDIR`          # Directorio para los archivos de log de los comandos
  LOGEXT=`./service_instula.sh LOGEXT`          # Extension de los archivos de log
  MAXLOGSIZE=`./service_instula.sh MAXLOGSIZE`  # Tamaño máximo de los archivos de log
  USERID=`whoami`                               # Usuario de la instalacion
  FECINS=`date +%d/%m/%Y\ %H:%M`                # Fecha y Hora de inicio de instalacion
  MAESTRO_AGENCIAS="$CONFDIR/agencias.mae"
  MAESTRO_BENEFICIOS="$CONFDIR/beneficios.mae"
  POSTULA_ENV="Loaded"

  # Valido la existencia
  #exist $GRUPO
  #exist $ARRIDIR
  #exist $BINDIR
  #exist $CONFDIR
  #exist $LOGDIR

  # Seteo la variable PATH
  PATH=$PATH:$GRUPO:$ARRIDIR:$CONFDIR:$BINDIR

  # Exporto las variables
  export CURRDIR
  export GRUPO
  export ARRIDIR
  export BINDIR
  export CONFDIR
  export DATASIZE
  export LOGDIR
  export LOGEXT
  export MAXLOGSIZE
  export USERID
  export FECINS
  export PATH

  # Imprimo variables
  echo "\n Imprimo variables:"
  evariables

  # Verifico si esta postonio levantado
  postonio=`ps -ef | grep -v grep | grep 'postonio'`

  if [ -z "$postonio" ]
  then
    # Levanto postonio
    echo "levanto postonio.."
    #runPostonio
  else
    # Fuerzo a postonio a correr
    echo "\nInicializacion de Ambiente Concluida"
    echo "Ambiente"

    # Imprimo variables
    evariables

    echo "Demonio corriendo bajo el Nro.: $postonio"
  fi

fi
