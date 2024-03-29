#!/bin/bash
ACTUAL="$PWD"
cd "`dirname $0`"
# Funcion que imprime el valor de las variables
evariables () {
  echo "CURRDIR=$CURRDIR";
  echo "GRUPO=$GRUPO";
  echo "ARRIDIR=$ARRIDIR";
  echo "BINDIR=$BINDIR";
  echo "CONFDIR=$CONFDIR";
  echo "DATASIZE=$DATASIZE";
  echo "LOGDIR=$LOGDIR";
  echo "LOGEXT=$LOGEXT";
  echo "MAXLOGSIZE=$MAXLOGSIZE";
  echo "USERID=$USERID";
  echo "FECINS=$FECINS";
  echo "PATH=$PATH";
  echo "POSTONIO_TIEMPO_ESPERA=$POSTONIO_TIEMPO_ESPERA";
  echo "DATADIR=$DATADIR"
  echo "NUEVOS=$NUEVOS";
  echo "RECIBIDOS=$RECIBIDOS";
  echo "PROCESADOS=$PROCESADOS"
  echo "RECHAZADOS=$RECHAZADOS";
  echo "LISTDIR=$LISTDIR";
}

# Funcion que corre POSTONIO
runPostonio () {

  postonio.sh start
  # El script postonio.sh arroja un exit 1 cuando ya está en ejecución.
  if [ $? != 0 ]
  then
    echo "POSTONIO ya se encuentra en ejecución."
  else
    echo "POSTONIO ha sido puesto en ejecución."
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

# Comando que verifica la existencia de las variables de inicializacion de ambiente
if [ ! -z "$POSTULA_ENV"  ]
then
  echo "### ADVERTENCIA: las variables de entorno ya fueron seteadas ###"

  # Imprimo variables
  evariables
else
  # Seteo las variables de entorno para la sesion del usuario (la idea seria que me lleguen como parametro)
  DATADIR="`./service_instula_conf.sh DATADIR`"
  MAESTRO_AGENCIAS="$DATADIR/agencias.mae"
  MAESTRO_BENEFICIOS="$DATADIR/beneficios.mae"

  if [ ! -f "$MAESTRO_AGENCIAS" -o ! -f "$MAESTRO_BENEFICIOS" ]
  then
    echo "Postini no puede correrse debido a la falta de existencia de los archivos MAESTROS"
    return
  fi
  CURRDIR="$PWD"					# Directorio Actual de trabajo
  GRUPO="`./service_instula_conf.sh CURRDIR`"		# Directorio del grupo
  ARRIDIR="`./service_instula_conf.sh ARRIDIR`"		# Directorio de arribos de archivos externos
  BINDIR="`./service_instula_conf.sh BINDIR`"		# Directorio para los ejecutables
  CONFDIR="`./service_instula_conf.sh CONFDIR`"		# Directorio para los archivos de configuracion
  DATASIZE="`./service_instula_conf.sh DATASIZE`"	# Espacio minimo necesario en el directorio ARRIDIR en Mb
  LOGDIR="`./service_instula_conf.sh LOGDIR`"		# Directorio para los archivos de log de los comandos
  LOGEXT="`./service_instula_conf.sh LOGEXT`"		# Extension de los archivos de log
  MAXLOGSIZE="`./service_instula_conf.sh MAXLOGSIZE`"	# Tamanio maximo de los archivos de log
  USERID="`./service_instula_conf.sh USERID`"			# Usuario de la instalacion
  FECINS="`date +%d/%m/%Y\ %H:%M`"  # Fecha y Hora de inicio de instalacion
  POSTULA_ENV="Loaded"
  POSTONIO_TIEMPO_ESPERA="`./service_instula_conf.sh POSTONIO_TIEMPO_ESPERA`"
  NUEVOS="`./service_instula_conf.sh NUEVOS`"
  RECIBIDOS="`./service_instula_conf.sh RECIBIDOS`"
  RECHAZADOS="`./service_instula_conf.sh RECHAZADOS`"
  PROCESADOS="`./service_instula_conf.sh PROCESADOS`"
  LISTDIR="`./service_instula_conf.sh LISTDIR`"

  # Valido la existencia
  #exist $GRUPO
  #exist $ARRIDIR
  #exist $BINDIR
  #exist $CONFDIR
  #exist $LOGDIR

  # Seteo la variable PATH
  PATH="$PATH:$BINDIR"

  # Exporto las variables
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
  export MAESTRO_AGENCIAS
  export MAESTRO_BENEFICIOS
  export POSTULA_ENV
  export POSTONIO_TIEMPO_ESPERA
  export DATADIR
  export NUEVOS
  export RECIBIDOS
  export PROCESADOS
  export RECHAZADOS
  export LISTDIR

  # Imprimo variables
  echo ""
  echo " Imprimo variables:"
  evariables

  # Verifico si esta postonio levantado
  postonio=`ps xc | grep -v grep | grep 'postonio.sh'`

  if [ -z "$postonio" ]
  then
    # Levanto postonio
    echo "levanto postonio.."
    runPostonio
  else
    # Fuerzo a postonio a correr
    echo "\nInicializacion de Ambiente Concluida"
    echo "Ambiente"

    # Imprimo variables
    evariables
    local pid="`echo "$postonio" | sed 's/ \+/,/g' | cut -f2 -d,`"
    echo "Demonio corriendo bajo el Nro.: $pid"
  fi

fi
cd "$ACTUAL"
