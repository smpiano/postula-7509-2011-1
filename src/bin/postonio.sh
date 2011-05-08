#!/bin/bash

source utils.sh

AGENCY_SEQUENCES=$CONFDIR/AGENCY_SEQUENCES.txt

#===============================================F U N C I O N E S  A U X I L I A R E S ==================================================================#

#Verifica si el Deamon ya esta corriendo
function anotherPostonioCheck() {
    q=`ps -ef |grep $0 |grep -v "grep"|grep -v $$| wc -l`
    if [ $q != "0" ]; then
        log "Postonio already running..."
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

	info  "Buscando el codigo de agencia '$agency_code' en el archivo maestro de agencias"
	
	exec < $DATADIR/agencias2.mae
	while read LINE  
	do
		info "Buscando en la linea; '$LINE' "
		bar=( $LINE )
		info "Chequeando Codigo de agencia = ${bar[1]}"
		
		if [ $agency_code == ${bar[1]} ]
		then
			info "Codigo de Agencia encontrado !"			
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
		error "Error de consistencia de datos en el archivo de secuencias"
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
		error "El numero de secuencia de la agencia a insertar no es incremental."
		error "Se quizo insertar '$_sequence' y el mayor numero de secuencia asociado al codigo de agencia :'$_agency_code' es '$secuencia'"
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
	for i in $archivo_modificado 
	do
		echo "$i">>$AGENCY_SEQUENCES
	done		
}
#======================================================================================#
function executePosultar(){
  
  postular.sh &   
  
  $!
  
}

#============================================== F I N   F U N C I O N E S  A U X I L I A R E S ============================================================#


# Funcion principal del demonio
function execute() {
	
	if [ -a $AGENCY_SEQUENCES ] 
	then
	  info "Se empleara el archivo '$AGENCY_SEQUENCES' para almacenar las secuencias entrantes y realizar las validaciones pertinentes"
	else
		info "Creando el archivo '$AGENCY_SEQUENCES'"
		> $AGENCY_SEQUENCES
	fi


	if [ ! -d $ARRIDIR ] 
	then
		 error_severo "El directorio de arribos no fue aun creado o es invalido"
     exit 1
	fi

	info "Buscando archivos en la carpeta '$ARRIDIR'"


	cd $ARRIDIR

	#Recorro todos los archivos dentro del directorio de arribos en busca de archivos con nombres validos
	for FILE in *.*
	do
		FILTERED_FILE_NAME=$(ls $FILE | egrep ^[a-zA-Z]*\.[0-9]{6}$)
	
		if [ -z $FILTERED_FILE_NAME ]
		then
			info "La estructura del nombre del archivo: '$FILE' es invalida."
			info "Se moverá a la carpeta de rechazados"
          move $FILE $RECHAZADOS          
		else
			info "La estructura del nombre del archivo: '$FILE' es valida"				
			info "Validando el codigo de agencia"
		
			codigo_agencia=$(echo $FILE | cut -d'.' -f1)
			sequence=$(echo $FILE | cut -d'.' -f2)
		
			validAgencyCode $codigo_agencia resultAgencyFunction
			validSequence $sequence $codigo_agencia resultSequenceFunction
			
			#Actualiza el archivo de secuencias			
			if [ $resultSequenceFunction == 'true' ];then
				actualizar_archivo_secuencias $codigo_agencia $sequence
				info "La secuencia del codigo de agencia '$codigo_agencia' fue actualizada correctamente"
			else
				error "La secuencia '$sequence' fue considerada invalida (ver detalle log)"
				error "Se moverá el archivo '$codigo_agencia' a la carpeta de rechazados"
				mover $FILE $RECHAZADOS 										
				exit 1
			fi

			
			if [ $resultAgencyFunction == 'true' ]		
			then	
				info "El codigo de agencia '$codigo_agencia' es valido. (Fue entontrado en el Archivo Maestro de agencias)"
				info "Se moverá el archivo '$codigo_agencia' a la carpeta de recibidos"									
				mover $FILE $RECIBIDOS
			else
				info "El codigo de agencia '$codigo_agencia' es inválido.(No fue hayado en el Archivo Maestro de agencias)"
				info "Se moverá el archivo '$codigo_agencia' a la carpeta de rechazados"						
				exit 1
				mover $FILE $RECHAZADOS
			fi
	      
        #Chequea si estan dadas las condiciones para que se invoque el Postular  
        if [ `ls $RECIBIDOS | wc -l` -ne 0 ];then
				    
            if [ ps axo 'pid=,command=' | grep postular.sh | cut -f1 | wc -l ];then
              executePosultar
            else
              info "Postular ya se encuentra ejecutando"
            fi
        
        else
          info "No se recibieron nuevos archivos"
        fi
			
		fi

	done
}

#======================================================= M  A  I  N  =================================================================================#
function main() {
    {
        while [ 1 ]; do
            execute
            sleep $POSTONIO_TIEMPO_ESPERA
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


