#!/bin/bash

################################### GRALOG ###################################
#                                                                            #
# Parámetros:                                                                #
# 	(comando, tipo_mensaje, nombre_comando, mensaje)                     #
# 	                                                                     #
# comando: nombre del archivo de log en el que se va a almacenar el mensaje  #
# nombre_comando: Nombre del comado que genera el mensaje                    #
# tipo_mensaje: I = INFO; A = ALERTA; E = ERROR; ES = ERROR SEVERO           #
# mensaje: Mensaje a guardar en el archivo de log.	                     #
#                                                                            #
############################################################################## 


#Función que verifica si el archivo supera el tamaño máximo
verificar_archivo_excede_logsize (){

	arch_log=""

	#Almaceno los nombres de los archivos del directorio de logs en un archivo temporal
	ls -1 $directorio_logs > "$directorio_logs/nombres_archivos.tmp"

	arch_log=`grep "$nombre_archivo.$extension_arch_log" "$directorio_logs/nombres_archivos.tmp"`

	if [ "$arch_log"="$nombre_archivo.$extension_arch_log" ]
	then
		cd $directorio_logs
		cant_bytes=`wc -c $arch_log | cut -d' ' -f1` #Tomo la cantidad de bytes que ocupa

		if [ $cant_bytes -ge $max_size_log ]
		then
			#Grabo en el log que el tamaño fue excedido
			echo `date '+%m-%d-%y %T'`" - "$nombre_usuario" - "$nombre_comando" - I - Log excedido">>$directorio_logs/"$nombre_archivo."$extension_arch_log

			bytes_acum=0
			mitad_tamanio=0

			#Calculo el tamaño en bytes del archivo de log
			while read linea_archivo
			do
				#Acumulo los bytes que van sumando las líneas del archivo
				bytes_acum=$(($bytes_acum+`echo $linea_archivo | wc -c`))
			done < $directorio_logs/"$nombre_archivo."$extension_arch_log
	
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
					echo "$linea_archivo">>"$directorio_logs/temp.log"
				fi #[ $bytes_eliminados -le $mitad_tamanio ]
			done < $directorio_logs/"$nombre_archivo."$extension_arch_log


			#Renombro el archivo temporal "temp.log" para que se llame como lo solicitó el usuario
			rm $directorio_logs/"$nombre_archivo."$extension_arch_log
			mv $directorio_logs/"temp.log" $directorio_logs/"$nombre_archivo."$extension_arch_log

		fi #[ $cant_bytes > $max_size_log]
	
	fi #[ "$arch_log" = "gralog."$extension_arch_log ]

	rm "$directorio_logs/nombres_archivos.tmp"

} #Fin verificar_archivo_excede_logsize ()



#####Flujo principal#####
nombre_usuario=`whoami`
nombre_comando=""
tipo_mensaje="I"
mensaje=""

#Verifico cantidad de parámetros
if [ $# != 4 ]
then
	echo "Parámetros inválidos"
	exit 1
fi #[ $# != 4 ]


#Obtengo parámetros

#Nombre archivo
nombre_archivo=$1

#Nombre del comando
nombre_comando=$2

#Tipo de mensaje
tipo=`echo $3 | tr "[:lower:]" "[:upper:]"`
if [ $tipo = "I" -o $tipo = "A" -o $tipo = "E" -o $tipo = "ES" ]
then
	tipo_mensaje=$tipo
else
	echo "Parámetro 3 inválido"
	exit 1
fi #[ $tipo = "I" -o $tipo = "A" -o $tipo = "E" -o $tipo = "ES" ]

#Mensaje
mensaje=$4

#TODO: Modificar el contenido de estas variables usando las variables de entorno
directorio_grupo=$CURRDIR #Obtengo el directorio en el que debo posicionarme para ejecutar los comandos
directorio_logs=$LOGDIR #Obtengo el directorio en donde se almacenan los logs
extension_arch_log=$LOGEXT #Obtengo la extensión del archivo de log (sin .)
max_size_log=$MAXLOGSIZE #Obtengo el máximo tamaño que puede ocupar un archivo de log


#Verifico si existe el directorio de los archivos de log
if [ ! -d $directorio_logs ]
then
	#Creo el directorio
	mkdir $directorio_logs

	#Creo el archivo de log
	>"$directorio_logs/$nombre_archivo.$extension_arch_log"

	#Guardo el mensaje en el log	
	echo $nombre_archivo.$extension_arch_log" - "`date '+%m-%d-%y %T'`" - "$nombre_usuario" - "$nombre_comando" - "$tipo_mensaje" - "$mensaje>>$directorio_logs/"$nombre_archivo."$extension_arch_log

	verificar_archivo_excede_logsize

	exit 0
else
	#Verifico si existe el archivo de log
	existe_log=`ls $directorio_logs | grep "$nombre_archivo.$extension_arch_log"`
	if [ -z $existe_log ]
	then
		#Creo el archivo de log
		>"$directorio_logs/$nombre_archivo.$extension_arch_log"

		#Guardo el mensaje en el log
		echo $nombre_archivo.$extension_arch_log" - "`date '+%m-%d-%y %T'`" - "$nombre_usuario" - "$nombre_comando" - "$tipo_mensaje" - "$mensaje>>$directorio_logs/"$nombre_archivo."$extension_arch_log

		verificar_archivo_excede_logsize

		exit 0
	else
		#Guardo el mensaje en el log
		echo $nombre_archivo.$extension_arch_log" - "`date '+%m-%d-%y %T'`" - "$nombre_usuario" - "$nombre_comando" - "$tipo_mensaje" - "$mensaje>>$directorio_logs/"$nombre_archivo."$extension_arch_log

		verificar_archivo_excede_logsize

		exit 0

	fi #[ -z $existe_log ]
fi #[ ! -d $directorio_logs ]


