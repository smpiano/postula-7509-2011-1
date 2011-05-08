#!/bin/bash

#Harcodeo de directorios. Luego usar variables de ambiente
AGENCIASDIR='/home/ngonzalez/Escritorio/postonio/AGENCIAS'
ARRIBDIR='/home/ngonzalez/Escritorio/postonio/ARRIBDIR/'
INBOX='/home/ngonzalez/Escritorio/postonio/RECIBIDOS/'
AGENCY_SEQUENCES='/home/ngonzalez/Escritorio/postonio/testing2.txt'



#Pasar funciones auxiliares a otro archivo
#===============================================F U N C I O N E S  A U X I L I A R E S ==================================================================#

#Verifica si el Deamon ya esta corriendo
function anotherPostonioCheck() {
    q=`ps -ef |grep $0 |grep -v "grep"|grep -v $$| wc -l`
    if [ $q != "0" ]; then
        echo "Postonio already running..."
        exit 1
    fi
}

#Inicia el Deamon
function start() {
    anotherPostonioCheck
    echo "Postonio started to run..."
    main
}

#Apaga el Deamon
function shutdown() {
    echo "Shutting down Postonio..."
    kill `ps -ef |grep $0|grep -v $$ |grep -v "grep"|awk '{print($2)}'`
}


#======================================================================================#
# Funcion que se fija si en el archivo maestro de agencias se encuentra un codigo de 
# agencia particular

function isInAgencyMasterFile(){
	
	local agency_code=$1
	local ___result=$2
	local IFS=","
	local found='false'

	echo "[POSTONIO] Buscando el codigo de agencia '$agency_code' en el archivo maestro de agencias"
	
	exec < $AGENCIASDIR/agencias2.mae
	while read LINE  
	do
		echo "[POSTONIO] Buscando en la linea; '$LINE' "
		bar=( $LINE )
		echo "[POSTONIO] Chequeando Codigo de agencia = ${bar[1]}"
		
		if [ $agency_code == ${bar[1]} ]
		then
			echo "[POSTONIO] Codigo de Agencia encontrado !"			
			found='true'
			#Cortar el ciclo!
		fi
	done

	eval $___result="'$found'"
}

#======================================================================================#
# Funcion que evalua si el codigo de agencia es valido, buscandolo en el archivo 
# maestro de agencias

function validAgencyCode() {
	local agency_code=$1
	local __result=$2

	isInAgencyMasterFile $agency_code result_is_in_agency_master_file  
	
	echo "[POSTONIO] isInAgencyMasterFile: resultado = $result_is_in_agency_master_file  "

	eval $__result="'$result_is_in_agency_master_file'"
}
#======================================================================================#
# Funcion que dado un codigo de agencia (parametro 1), devuelve la mayor secuencia asociada
# a dicho codigo, utilizando para ello el archivo de secuencias 'AGENCY_SEQUENCES'. Devuelve null
# en caso de estar el codigo de agencia en dicho archivo

function buscarMayorSecuenciaPorCodigoDeAgencia(){
	
	local agencia_codigo=$1
	local _secuencia=$2
	local nullValue='null'
	
	resultado=$(egrep ^$agencia_codigo\.[0-9]{6}$ $AGENCY_SEQUENCES)

	resultado_contador=$(echo "$resultado" | wc -l)
	
	if [ $resultado_contador -gt 1 ]; then
		echo "Error de consistencia de datos en el archivo de secuencias"
		exit 1
	fi

	if [ -z $resultado ];then
		eval $_secuencia="'$nullValue'"
	else
		sequ=$(echo "$resultado" | cut -d '.' -f2)
		eval $_secuencia="'$sequ'"
	fi
}
#======================================================================================#
# Funcion que dado un numero de secuencia y un codigo de agencia, evalua si la secuencia asociada 
# al codigo de agencia (parametro 2) y mayor,menor o igual que la secuancia pasada por
# parametro (parametro 1)

function validSequence(){
	local _sequence=$1
	local _agency_code=$2
	local _resultSequenceFunction=$3

	buscarMayorSecuenciaPorCodigoDeAgencia $_agency_code secuencia

	if [ $secuencia == 'null' ];then
		echo $linea_archivo>>$AGENCY_SEQUENCES
		eval $_resultSequenceFunction='true'
	fi
	
	if [ $_sequence -le $secuencia ];then
		echo "[POSTONIO] Error, el numero de secuencia de la agencia a insertar no es incremental."
		echo "Se quizo insertar '$_sequence' y el mayor numero de secuencia asociado al codigo de agencia :'$_agency_code' es '$secuencia'"
		eval $_resultSequenceFunction='false'
	fi

	if [ $_sequence -gt $secuencia ];then
		eval $_resultSequenceFunction='true'
	fi
}

#======================================================================================#
# Funcion que, luego de validar el valor de la secuencia del registro a insertar, actualiza el archivo
# de secuencias 'AGENCY_SEQUENCES'
function actualizar_archivo_secuencias(){
		
	local __codigo_agencia=$1
	local __secuencia=$2

	linea_a_insertar="$__codigo_agencia"."$__secuencia"
	
	archivo_modificado=$(cat $AGENCY_SEQUENCES | sed "s/^$__codigo_agencia\.[0-9]\{6\}$/$linea_a_insertar/")
	
	> $AGENCY_SEQUENCES
	for  i in $archivo_modificado 
	do
		echo "$i">>$AGENCY_SEQUENCES
	done		
}
#======================================================================================#
function executePosultar(){
	
}

#============================================== F I N   F U N C I O N E S  A U X I L I A R E S ============================================================#


# Funcion principal del demonio
function execute() {
	
	if [ -a $AGENCY_SEQUENCES ] 
	then
	  echo "Se empleara el archivo '$AGENCY_SEQUENCES' para almacenar las secuencias entrantes y realizar las validaciones pertinentes"
	else
		echo "Creando el archivo '$AGENCY_SEQUENCES'"
		> $AGENCY_SEQUENCES
	fi


	if [ ! -d $ARRIBDIR ] 
	then
		#Esto deberia salir en el log?
		echo "[POSTONIO] El directorio de arribos no fue aun creado o es invalido"
	fi

	echo "[POSTONIO] Buscando archivos en la carpeta '$ARRIBDIR'"


	cd $ARRIBDIR

	#Recorro todos los archivos dentro del directorio de arribos en busca de archivos con nombres validos
	for FILE in *.*
	do
		FILTERED_FILE_NAME=$(ls $FILE | egrep ^[a-zA-Z]*\.[0-9]{6}$)
	
		if [ -z $FILTERED_FILE_NAME ]
		then
			echo "[POSTONIO] La estructura del nombre del archivo: '$FILE' es invalida."
			echo "[POSTONIO] Se moverá a la carpeta de rechazados"
			#Mover a la carpeta de rechazados
		else
			echo "[POSTONIO] La estructura del nombre del archivo: '$FILE' es valida"				
			echo "[POSTONIO] Validando el codigo de agencia"
		
			codigo_agencia=$(echo $FILE | cut -d'.' -f1)
			sequence=$(echo $FILE | cut -d'.' -f2)
		
			validAgencyCode $codigo_agencia resultAgencyFunction
			validSequence $sequence $codigo_agencia resultSequenceFunction
			
			#Actualiza el archivo de secuencias			
			if [ $resultSequenceFunction == 'true' ];then
				actualizar_archivo_secuencias $codigo_agencia $sequence
				echo "[POSTONIO] La secuencia del codigo de agencia '$codigo_agencia' fue actualizada correctamente"
			else
				echo "[POSTONIO] La secuencia '$sequence' fue considerada invalida (ver detalle log)"
				echo "[POSTONIO] Se moverá el archivo '$codigo_agencia' a la carpeta de rechazados"
				#Mover a la carpeta de rechazados										
				exit 1
			fi

			
			if [ $resultAgencyFunction == 'true' ]		
			then	
				echo "[POSTONIO] El codigo de agencia '$codigo_agencia' es valido. (Fue entontrado en el Archivo Maestro de agencias)"
				echo "[POSTONIO] Se moverá el archivo '$codigo_agencia' a la carpeta de recibidos"									
				#Mover a la carpeta de recibidos
			else
				echo "[POSTONIO] El codigo de agencia '$codigo_agencia' es inválido.(No fue hayado en el Archivo Maestro de agencias)"
				echo "[POSTONIO] Se moverá el archivo '$codigo_agencia' a la carpeta de rechazados"						
				exit 1
				#Mover a la carpeta de rechazados
			fi
			
				#llamar al postular
				executePosultar
			
		fi

	done
}

#======================================================= M  A  I  N  =================================================================================#
function main() {
    {
        while [ 1 ]; do
            execute
#Sacar el tiempo a una variable de entorno
            sleep 30
        done
    } &
}

case $1 in
	"start")
       start
    ;;
    "shutdown")
        shutdown
    ;;
     *)
         start
     ;;
esac
#=======================================================================================================================================================#

