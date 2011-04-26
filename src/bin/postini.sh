#!/bin/bash

# Funcion que imprime el valor de las variables
evariables () {
	echo "CURRDIR=$CURRDIR";
        echo "grupo=$grupo";
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
	sh $POSTONIO
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
		exit 2
	fi
}

echo "...::: POSTINI :::..."

# Necesidad del pasaje de un parametro
if [ $# != 1 ] 
then
	echo "Se debe pasar un parametro, el nombre del demonio POSTONIO [para test usar: xorg]"
	exit 1
fi

# Variable que representa el nombre del demonio POSTONIO
POSTONIO=$1


# Comando que verifica la existencia de las variables de inicializacion de ambiente
PARAM_ORIG_GRUPO="grupo02"
CHECK=`echo $PATH | grep $PARAM_ORIG_GRUPO`

if [ ! -z "$CHECK"  ]
then
	echo "ADVERTENCIA: las variables de entorno ya fueron seteadas"

	# Imprimo variables
	evariables
else

	# Seteo las variables de entorno para la sesion del usuario (la idea seria que me lleguen como parametro)
	CURRDIR="$PWD"                  # Directorio Actual de trabajo 
	grupo="$PWD/grupo02"            # Directorio del grupo
	ARRIDIR="$PWD/arribos"          # Directorio de arribos de archivos externos 
	BINDIR="$PWD/bin"               # Directorio para los ejecutables
	CONFDIR="$grupo/conf"           # Directorio para los archivos de configuracion
	DATASIZE="200"                  # Espacio minimo necesario en el directorio ARRIDIR en Mb
	LOGDIR="$grupo/log"             # Directorio para los archivos de log de los comandos
	LOGEXT="log"                    # Extension de los archivos de log
	MAXLOGSIZE="500"                # Tamanio maximo de los archivos de log
	USERID=`whoami`			# Usuario de la instalacion
	FECINS=`date +%d/%m/%Y\ %H:%M`  # Fecha y Hora de inicio de instalacion

	# Valido la existencia
	exist $grupo
	exist $ARRIDIR
	exist $BINDIR
	exist $CONFDIR
	exist $LOGDIR

	# Seteo la variable PATH
	PATH=$PATH:$grupo:$ARRIDIR:$CONFDIR:$BINDIR

	# Exporto las variables
	export CURRDIR
	export grupo
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
	postonio=`ps -ef | grep -v grep | grep $POSTONIO`

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

        # Defino las variables en un subshell superior
        bash

fi
