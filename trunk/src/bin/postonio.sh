#!/bin/bash

#Harcodeo de directorios. Luego usar variables de ambiente
AGENCIASDIR='/home/ngonzalez/Escritorio/postonio/AGENCIAS'
ARRIBDIR='/home/ngonzalez/Escritorio/postonio/ARRIBDIR/'
INBOX='/home/ngonzalez/Escritorio/postonio/RECIBIDOS/'



#Pasar funciones auxiliares a otro archivo
#===============================================F U N C I O N E S  A U X I L I A R E S ==================================================================#


function anotherPostonioCheck() {
    q=`ps -ef |grep $0 |grep -v "grep"|grep -v $$| wc -l`
    if [ $q != "0" ]; then
        echo "Postonio already running..."
        exit 1
    fi
}

function start() {
    anotherPostonioCheck
    echo "Postonio started to run..."
    main
}

function shutdown() {
    echo "Shutting down Postonio"
    kill `ps -ef |grep $0|grep -v $$ |grep -v "grep"|awk '{print($2)}'`
}


function isInAgencyMasterFile(){
	
	local agencyCode=$1
	local ___result=$2
	local IFS=","
	local found='false'

	echo "[POSTONIO] Buscando el codigo de agencia '$agencyCode' en el archivo maestro de agencias"
	
	exec < $AGENCIASDIR/agencias.mae
	while read LINE  
	do
		echo "[POSTONIO] Buscando en la linea; '$LINE' "
		bar=( $LINE )
		echo "[POSTONIO] Chequeando Codigo de agencia = ${bar[1]}"
		
		if [ $agencyCode == ${bar[1]} ]
		then
			echo "[POSTONIO] Codigo de Agencia encontrado !"			
			found='true'
			#Cortar el ciclo!
		fi
	done

	eval $___result="'$found'"
}


function validNumber() {

	local  number=$1
	local  _result=$2
	local  myResult='false'

	if [[ $number == ${number//[^0-9]/} ]]
		then
			myResult='true'	
		else
			myResult='false'		
	fi
	
	eval $_result=$myResult
}

function validAgencyCode() {
	local agencyCode=$1
	local __result=$2
	
#	validNumber $agencyCode resultValidAgencyCodeNumber
#	echo "[POSTONIO] validNumber: resultado = $resultValidAgencyCodeNumber"
#
#	if [ $resultValidAgencyCodeNumber == 'true' ]
#	then

		isInAgencyMasterFile $agencyCode resultIsInAgencyMasterFile  
		echo "[POSTONIO] isInAgencyMasterFile: resultado = $resultIsInAgencyMasterFile"
#	fi
	
	eval $__result="'$resultIsInAgencyMasterFile'"
}

#=================================================================================================================================#


#Funcion principal
function execute() {
	
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
		#Arreglar, no usar egrep	
		FILTERED_FILE_NAME=$(ls $FILE | egrep ^[a-zA-Z]*\.[0-9]{6}$)
	
		if [ -z $FILTERED_FILE_NAME ]
		then
			echo "[POSTONIO] La estructura del nombre del archivo: '$FILE' es invalida."
			echo "[POSTONIO] Se moverá a la carpeta de rechazados"
			#Mover a la carpeta de rechazados
		else
			echo "[POSTONIO] La estructura del nombre del archivo: '$FILE' es valida"				
			echo "[POSTONIO] Validando el codigo de agencia"
		
			CODIGO_AGENCIA=$(echo $FILE | cut -d'.' -f1)

			validAgencyCode $CODIGO_AGENCIA result

			if [ $result == 'true' ]		
			then	
				echo "[POSTONIO] El codigo de agencia '$CODIGO_AGENCIA' es valido. (Fue entontrado en el Archivo Maestro de agencias)"
				echo "[POSTONIO] Se moverá el archivo '$CODIGO_AGENCIA' a la carpeta de recibidos"									
			else
				echo "[POSTONIO] El codigo de agencia '$CODIGO_AGENCIA' es inválido.(No fue hayado en el Archivo Maestro de agencias)"
				echo "[POSTONIO] Se moverá el archivo '$CODIGO_AGENCIA' a la carpeta de rechazados"						
				#Mover a la carpeta de rechazados
			fi
		fi

	done
}

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
