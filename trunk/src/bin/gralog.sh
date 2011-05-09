#!/bin/bash

################################### GRALOG ###################################
#                                                                            #
# Parámetros:                                                                #
# 	(comando, TIPO_MENSAJE, NOMBRE_COMANDO, MENSAJE)                     #
# 	                                                                     #
# comando: nombre del archivo de log en el que se va a almacenar el MENSAJE  #
# NOMBRE_COMANDO: Nombre del comado que genera el MENSAJE                    #
# TIPO_MENSAJE: I = INFO; A = ALERTA; E = ERROR; ES = ERROR SEVERO           #
# MENSAJE: Mensaje a guardar en el archivo de log.	                     #
#                                                                            #
############################################################################## 


#Función que verifica si el archivo supera el tamaño máximo
verificarSiArchivoExcedeLogsize (){

	arch_log=""

	#Almaceno los nombres de los archivos del directorio de logs en un archivo temporal
	ls -1 $DIRECTORIO_LOGS > "$DIRECTORIO_LOGS/nombres_archivos.tmp"

	arch_log=`grep "$NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG" "$DIRECTORIO_LOGS/nombres_archivos.tmp"`

	if [ "$arch_log"="$NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG" ]
	then
		cd $DIRECTORIO_LOGS
		cant_bytes=`wc -c $arch_log | cut -d' ' -f1` #Tomo la cantidad de bytes que ocupa

		if [ ${cant_bytes:-0} -ge $MAX_SIZE_LOG ]
		then
			#Grabo en el log que el tamaño fue excedido
			echo $NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG" - "`date '+%m-%d-%y %T'`" - "$NOMBRE_USUARIO" - "$NOMBRE_COMANDO" - I - Log excedido">>$DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG

			bytes_acum=0
			mitad_tamanio=0

			#Calculo el tamaño en bytes del archivo de log
			while read linea_archivo
			do
				#Acumulo los bytes que van sumando las líneas del archivo
				bytes_acum=$(($bytes_acum+`echo $linea_archivo | wc -c`))
			done < $DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG
	
			mitad_tamanio=$(($bytes_acum/2))

			bytes_eliminados=0

			#Elimino las líneas más antiguas que superen el 50% del tamaño permitido
			while read linea_archivo
			do
				if [ $bytes_eliminados -le $mitad_tamanio ]
				then	
					#Sumo bytes acumulados de las lineas que tengo que eliminar hasta llegar al 50% del total
					#Voy eliminando líneas hasta sumar el 50% del total
					bytes_eliminados=$(($bytes_eliminados+`echo $linea_archivo | wc -c`))
				else
					#Escribo la línea que persiste en un archivo temporal "temp.log"
					echo "$linea_archivo">>"$DIRECTORIO_LOGS/temp.log"
				fi #[ $bytes_eliminados -le $mitad_tamanio ]
			done < $DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG


			#Renombro el archivo temporal "temp.log" para que se llame como lo solicitó el usuario
			rm $DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG
			mv $DIRECTORIO_LOGS/"temp.log" $DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG

		fi #[ $cant_bytes > $MAX_SIZE_LOG]
	
	fi #[ "$arch_log" = "gralog."$EXTENSION_ARCH_LOG ]

	rm "$DIRECTORIO_LOGS/nombres_archivos.tmp"

} #Fin verificar_archivo_excede_logsize ()



#####Flujo principal#####
NOMBRE_USUARIO=`whoami`
NOMBRE_COMANDO=""
TIPO_MENSAJE="I"
MENSAJE=""

#Verifico cantidad de parámetros
if [ $# != 4 ]
then
	echo "Parámetros inválidos"
	exit 1
fi #[ $# != 4 ]


#Obtengo parámetros

#Nombre archivo
NOMBRE_ARCHIVO="$1"

#Nombre del comando
NOMBRE_COMANDO="$2"

#Tipo de MENSAJE
tipo="`echo $3 | tr "[:lower:]" "[:upper:]"`"
if [ "$tipo" = "I" -o "$tipo" = "A" -o "$tipo" = "E" -o "$tipo" = "ES" ]
then
	TIPO_MENSAJE="$tipo"
else
	echo "Parámetro 3 inválido"
	exit 1
fi #[ $tipo = "I" -o $tipo = "A" -o $tipo = "E" -o $tipo = "ES" ]

#Mensaje
MENSAJE="$4"

DIRECTORIO_LOGS="$LOGDIR" #Obtengo el directorio en donde se almacenan los logs
EXTENSION_ARCH_LOG="$LOGEXT" #Obtengo la extensión del archivo de log (sin .)
MAX_SIZE_LOG=$(($MAXLOGSIZE\*1024)) #Obtengo el máximo tamaño que puede ocupar un archivo de log (en bytes)

#Verifico si existe el directorio de los archivos de log
if [ ! -d "$DIRECTORIO_LOGS" ]
then
	#Creo el directorio
	mkdir -p "$DIRECTORIO_LOGS"

	#Creo el archivo de log
	>"$DIRECTORIO_LOGS/$NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG"

	#Guardo el MENSAJE en el log	
	echo $NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG" - "`date '+%m-%d-%y %T'`" - "$NOMBRE_USUARIO" - "$NOMBRE_COMANDO" - "$TIPO_MENSAJE" - "$MENSAJE>>$DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG

	verificarSiArchivoExcedeLogsize
	exit 0
else
	#Verifico si existe el archivo de log
	existe_log=`ls $DIRECTORIO_LOGS | grep "$NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG"`
	if [ -z $existe_log ]
	then
		#Creo el archivo de log
		>"$DIRECTORIO_LOGS/$NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG"

		#Guardo el MENSAJE en el log
		echo $NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG" - "`date '+%m-%d-%y %T'`" - "$NOMBRE_USUARIO" - "$NOMBRE_COMANDO" - "$TIPO_MENSAJE" - "$MENSAJE>>$DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG

		verificarSiArchivoExcedeLogsize

		exit 0
	else
		#Guardo el MENSAJE en el log
		echo $NOMBRE_ARCHIVO.$EXTENSION_ARCH_LOG" - "`date '+%m-%d-%y %T'`" - "$NOMBRE_USUARIO" - "$NOMBRE_COMANDO" - "$TIPO_MENSAJE" - "$MENSAJE>>$DIRECTORIO_LOGS/"$NOMBRE_ARCHIVO."$EXTENSION_ARCH_LOG

		verificarSiArchivoExcedeLogsize

		exit 0

	fi #[ -z $existe_log ]
fi #[ ! -d $DIRECTORIO_LOGS ]


