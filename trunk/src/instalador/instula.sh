#!/bin/bash

######### Comando instula.sh #########

# Declaración de variables globales
TARDIR="`dirname "$0"`"		# Nos indica donde se encuentran los archivos patrones de instalacion (es relativo al pwd).
CURRDIR=$PWD
GRUPO="$CURRDIR"
INSTDIR="$GRUPO/inst"
CONFDIR="$GRUPO/conf"
BINDIR="$GRUPO/bin"
ARRIDIR="$GRUPO/arribos"
DATASIZE="200"			# Medido en Mb
LOGDIR="$GRUPO/log"
LOGEXT="log"
LOGSIZE="500"			# Medido en Kb
USERID=`whoami`
FECINST=`date +%d/%m/%Y\ %H:%M`	# Fecha y Hora de inicio de instalacion
INSTULA_CONF="$CONFDIR/instula.conf"
POSTINI=""
POSTONIO=""
POSTULAR=""
POSTLIST=""
POSTONIO_TIEMPO_ESPERA="10"
PATH_VALIDO=""
SIZE_VALIDO=""
ACEPTO_TERMINOS="no"

# Variable usada para el nombre del archivo de log de instula
ARCHIVO_LOG="$CONFDIR/instula.log"


# Estos serian los directorios que deberian ser creados a mano antes de comenzar la instalacion
antesDeInstula () {
	# TODO borrar o arreglar
	#$TARDIR/creacionDirectorioGrupoInstula.sh grupo02 $CURRDIR
	$TARDIR/creacionDirectorioGrupoInstula.sh conf $GRUPO
	$TARDIR/creacionDirectorioGrupoInstula.sh data $GRUPO
	$TARDIR/creacionDirectorioGrupoInstula.sh inst $GRUPO
}

loguear () {
	if [ $# -eq 1 ]
	then
		echo "$1" | tee -a "$ARCHIVO_LOG"
	else
		echo "$1">>"$ARCHIVO_LOG"
	fi
}

# Muestra del proceso cancelado
procesoCancelado () {
	loguear "Proceso de instalación cancelado.";
}

########## PASO 1 : INICIAR ARCHIVO LOG ##########
inicializarArchivoLog () {
	if [ -f $ARCHIVO_LOG ]
	then
		#Renombro el archivo y genero uno nuevo
		local nombre_log_archivado="$CONFDIR/instula_`date "+%Y%m%d%H%M%N"`.log"
		mv "$ARCHIVO_LOG" "$nombre_log_archivado"
	fi #[ -z $log_existe ]
	loguear "Inicio de Instalación" s
}


########## PASO 2 : VERIFICACION DE COMPONENTES INSTALADOS ##########
# TODO ver como manejamos estas cosas.
postulaInstalado () {
	loguear "********************************************************"
	loguear "*   Proceso de Instalación del sistema de Postulantes  *"
	loguear "*            Copyright TPSistemasOp (c)2011            *"
	loguear "********************************************************"
	loguear "* Se encuentran instalados los siguientes componentes: *"
	loguear "* POSTINI  <$2> <$1>\t*"
	loguear "* POSTONIO <$3> <$1>\t*"
	loguear "* POSTULAR <$4> <$1>\t*"
	loguear "* POSTLIST <$5> <$1>\t*"
	loguear "********************************************************"
	procesoCancelado
	fin
}

# Valida si los componentes tienen permiso de ejecucion
existeComponente () {
	if [ -x "$1" ]
	then
		echo "\n* <"$2">\t\t\t\t\t\t\t*"
	fi
}

noExisteComponente () {
	if [ ! -x "$1" ]
	then
		echo "\n* <"$2">\t\t\t\t\t\t\t*"
	fi
}

# TODO ver como brindamos los datos de instalacion completa o instalacion parcial
postulaIncompleto () {
	local instalados="`existeComponente "$1" POSTINI`"
	local no_instalados="`noExisteComponente "$1" POSTINI`"
	instalados=$instalados"`existeComponente "$2" POSTONIO`"
	instalados=$instalados"`existeComponente "$3" POSTULAR`"
	instalados=$instalados"`existeComponente "$4" POSTLIST`"
	no_instalados=$no_instalados"`noExisteComponente "$2" POSTONIO`"
	no_instalados=$no_instalados"`noExisteComponente "$3" POSTULAR`"
	no_instalados=$no_instalados"`noExisteComponente "$4" POSTLIST`"
	
	loguear "**************************************************************"
	loguear "* Proceso de Instalación del sistema Postulantes             *"
	loguear "*          Copyright TPSistemasOp (c)2011                    *"
	loguear "**************************************************************"
	loguear "* Se encuentran instalados los siguientes componentes:\t\t*"
	loguear "$instalados"
	loguear "* Falta instalar los siguientes componentes:\t\t\t*"
	loguear "$no_instalados"
	loguear "* Elimine los componentes instalados e inténtelo nuevamente.\t*"
	loguear "*\t\t\t\t\t\t\t\t*"
	loguear "**************************************************************"
	procesoCancelado
	fin
}

# TODO
isPostulaInstalado () {
	if [ -f "$INSTULA_CONF" ]
	then
		local bindir_configurado="`cat "$INSTULA_CONF" | grep 'BINDIR' | cut -f2 -d\=`"
		cd "$bindir_configurado"
		# La instacion esta completa si:
		# - Las variables de entorno estan en instula.conf
		# - Los componentes existen
		local user="`./service_instula_conf.sh USERID`"
		local fecha_postini="`./service_instula_conf.sh POSTINI`"
		local fecha_postonio="`./service_instula_conf.sh POSTONIO`"
		local fecha_postular="`./service_instula_conf.sh POSTULAR`"
		local fecha_postlist="`./service_instula_conf.sh POSTLIST`"
		local componente_postini="postini.sh"
		local componente_postonio="postonio.sh"
		local componente_postular="postular.sh"
		local componente_postlist="plist.pl"
		if [ ! -z "$user" -a ! -z "$fecha_postini" -a ! -z "$fecha_postonio" -a ! -z "$fecha_postular" -a ! -z "$fecha_postlist" -a -x "$componente_postini" -a -x "$componente_postonio" -a -x "$componente_postular" -a -x "$componente_postlist" ]
		then
			#Paso 2.1
			postulaInstalado "$user" "$fecha_postini" "$fecha_postonio" "$fecha_postular" "$fecha_postlist";
		else
			#Paso 2.2
			postulaIncompleto "$componente_postini" "$componente_postonio" "$componente_postular" "$componente_postlist";
		fi
		cd "$CURRDIR"
		exit 1;
	fi
}

########## PASO 3 : ACEPTACION DE TERMINOS Y CONDICIONES ##########
mostrarLicencia () {
	loguear "**************************************************************"
	loguear "* Proceso de Instalación del sistema Postulantes         	*"
	loguear "*      	Copyright TPSistemasOp (c)2011                	*"
	loguear "**************************************************************"
	loguear "* Al instalar POSTULA UD. expresa estar en un todo de acuerdo*"
	loguear "* con los términos y condiciones del \"ACUERDO DE LICENCIA DE *"
	loguear "* SOFTWARE\" incluido en este paquete.                    	*"
	loguear "**************************************************************"
	loguear "\"A\" para aceptar, \"C\" para cancelar: \\c"
}



# Cero representa aceptacion de licencia
# Uno representa no aceptacion de licencia
consultaLicencia () {
	mostrarLicencia
	local respuesta=""
	read respuesta #Leo la selección del usuario
	loguear "$respuesta" s

	#Verifico que el usuario haya ingresado una opción correcta
	while [ "$respuesta" != "A" -a  "$respuesta" != "a" -a "$respuesta" != "C" -a "$respuesta" != "c" ]
	do
		loguear "Opción inválida"
		loguear "Por favor, ingrese \"A\" para aceptar, \"C\" para cancelar: \\c"
		read respuesta
		loguear "$respuesta" s
	done
	if [ "$respuesta" = "C" -o  "$respuesta" = "c" ]
	then
		procesoCancelado
		fin
		exit 1;
	fi
}

########## PASO 4 : PERL INSTALADO ##########
isPerlInstalado () {
	perl_existe=`whereis perl`
	loguear ""
	if [ "$perl_existe" != "perl:" ]
	then
		local perl_version=`perl --version | grep 'v[0-9]\{1,2\}\(\.[0-9]\{1,2\}\)\{1,2\}' | cut -f4 -d' '`
		local perl_release=`echo "$perl_version" | cut -f1 -d. | cut -c2-`
		if [ $perl_release -ge 5 ]
		then
			loguear "Perl version 5 o superior esta instalado ($perl_version)"
		else
			erorPerl;
		fi
	else
		errorPerl;
	fi
}


errorPerl () {
	loguear "**************************************************************"
	loguear "* Para instalar POSTULA es necesario contar previamente con  *"
	loguear "* Perl 5 o superior instalado.                           	*"
	loguear "* Efectúe su instalación e inténtelo nuevamente          	*"
	loguear "**************************************************************"
	procesoCancelado;
	fin;
	exit 1;
}

########## PASO 5 : MENSAJES INFORMATIVOS  ##########
mensajesInformativos () {
	loguear ""
	loguear "Todos los directorios del sistema de postulantes serán subdirectorios de $GRUPO"
	loguear ""
	loguear "Todos los componentes de la instalación se obtendrán del repositorio: $INSTDIR"
	loguear "Listando directorio:\n`ls $INSTDIR`"
	loguear ""
	loguear "El archivo de configuración y el log de la instalación se registrarán en: $CONFDIR"
}


########## VALIDAR ##########
validarPath () {
	local dir_a_validar="$1"
	local dir_default="$2"

	dir_a_validar="`echo "$dir_a_validar" | sed 's/^\(\/\|\.\|~\/\)\+//'`" # Corto caracteres de acceso relativo al inicio
	dir_a_validar="`echo "$dir_a_validar" | sed 's/\/\{2,\}/\//g'`" # Corto varias ocurrencias de slashes a uno solo
	dir_a_validar="`echo "$dir_a_validar" | sed 's/\/\+$//g'`" # Corto el ultimo si es un slash
	if [ -z "$dir_a_validar" ]
	then
		PATH_VALIDO="`loguear "$dir_default"`"
	else
		# Valido que no tenga "/./" o "/../" o combinaciones de estas luego de un caracter distinto al "."
		while [ ! -z "`echo "$dir_a_validar" | grep -o '[^\.]\(\/\.\.\?\/\)\+'`" ]
		do
			loguear "Usted ingresó una dirección inválida. Por favor ingrese nuevamente: \\c"
			read dir_a_validar
			loguear "$dir_a_validar" s
			dir_a_validar="`echo "$dir_a_validar" | sed 's/^\(\/\|\.\|~\/\)\+//'`"
			dir_a_validar="`echo "$dir_a_validar" | sed 's/\/\{2,\}/\//g'`"
			dir_a_validar="`echo "$dir_a_validar" | sed 's/\/\+$//g'`"
		done

		if [ -z "$dir_a_validar" ]
		then
			PATH_VALIDO="`loguear "$dir_default"`"
		else
			PATH_VALIDO="`loguear "$GRUPO/$dir_a_validar"`"
		fi
	fi
}

validarSize () {
	local size="$1"
	local default="$2"
	local minimo="$3"
	local valido=""
	while [ -z "$valido" -a ! -z "$size" ]
	do
		if [ ! -z "`echo "$size" | grep '[^0-9]\{1,\}'`" ]
		then
			loguear "La variable ingresada no es valida. Ingrese solo numeros: \\c"
			read size
			loguear "$size" s
		else
			if [ "$size" -lt "$minimo" ]
			then
				loguear "El tamaño ingresado no debe ser inferior al minimo ($minimo)"
				read size
				loguear "$size" s
			else
				valido="true"
			fi
		fi
	done

	if [ -z "$size" ]
	then
		SIZE_VALIDO="$2"
	else
		SIZE_VALIDO="$size"
	fi
}

########## PASO 6 : DEFINIR DIRECTORIO DE EJECUTABLES ##########
definirDirectorioEjecutables () {
	local default="$BINDIR"
	loguear "Ingrese el nombre del subdirectorio de ejecutables ($BINDIR): \\c"
	read BINDIR
	loguear "$BINDIR" s
	validarPath "$BINDIR" "$default"
	BINDIR="$PATH_VALIDO"
}

########## PASO 7 : DEFINIR DIRECTORIO DE ARRIBO DE ARCHIVOS EXTERNOS ##########
definirDirectorioArriboArchivos () {
	local default="$ARRIDIR"
	loguear "Ingrese el nombre del directorio que permite el arribo de archivos externos ($ARRIDIR): \\c"
	read ARRIDIR
	loguear "$ARRIDIR" s
	validarPath "$ARRIDIR" "$default"
	ARRIDIR="$PATH_VALIDO"
}

########## PASO 8 : RESERVAR ESPACIO MINIMO PARA DATOS ##########
definirEspacioMinimoDatos () {
	local default="$DATASIZE"
	loguear "Ingrese el espacio mínimo requerido para datos externos (en Mbytes) ("$DATASIZE"Mb): \\c"
	read DATASIZE
	loguear "$DATASIZE" s
	validarSize "$DATASIZE" "$default" "100"
	DATASIZE="$SIZE_VALIDO"
}

########## PASO 9 : VERIFICAR ESPACIO EN DISCO ##########
verificarEspacioEnDisco () {
	local available_space=`df -BM . | sed 's/ \+/,/g' | cut -f4 -d, | grep '[0-9]' | sed 's/M//'`
	if [ $available_space -lt $DATASIZE ]
	then
		loguear "    	ERROR !:"
		loguear "    	Insuficiente espacio en disco."
		loguear "    	Espacio disponible en $ARRIDIR "$available_space"Mb. "
		loguear "    	Espacio requerido "$DATASIZE"Mb."
		loguear ""
		definirEspacioMinimoDatos;
	fi
}

########## PASO 10 : DEFINIR DIRECTORIO ARCHIVOS DE LOG DE LOS COMANDOS ##########
definirDirectorioArchivosLog () {
	local default="$LOGDIR"
	loguear "Ingrese el nombre del directorio de log ($LOGDIR): \\c"
	read LOGDIR
	loguear "$LOGDIR" s
	validarPath "$LOGDIR" "$default"
	LOGDIR="$PATH_VALIDO"
}

########## PASO 11 : DEFINIR EXTENSION Y TAMAÑO DE ARCHIVOS DE LOG ##########
definirExtensionArchivosLog () {
	local default="$LOGEXT"
	loguear "Ingrese la extensión para los archivos de log ($LOGEXT): \\c"
	read LOGEXT
	loguear "$LOGEXT" s
	#Si el usuario no ingresó ningún valor utilizo el default log (lo almaceno sin el punto)
	if [ -z $LOGEXT ]
	then
		LOGEXT="$default"
	else
		LOGEXT=`echo $LOGEXT | sed 's/^\.\+//'`
	fi #[ -z $LOGEXT ]
}

definirTamanioArchivosLog () {
	local default="$LOGSIZE"
	loguear "Ingrese el tamaño máximo para los archivos $LOGEXT (en Kbytes) ("$LOGSIZE"KB): \\c"
	read LOGSIZE
	loguear "$LOGSIZE" s
	validarSize "$LOGSIZE" "$default" "400"
	LOGSIZE="$SIZE_VALIDO"
}


########## PASO 12 : MOSTRAR ESTRUCTURA PROPUESTA ##########
mostrarEstructuraDirectoriosYValoresParametros () {
	clear #limpio la pantalla

	loguear "***********************************************************************"
	loguear "* Parámetros de Instalación del paquete POSTULA                   	*"
	loguear "***********************************************************************"
	loguear "Directorio de trabajo: $GRUPO"
	loguear "Directorio de instalación: $INSTDIR"
	loguear "Directorio de configuración: $CONFDIR"
	loguear "Directorio de datos: $GRUPO/data"
	loguear "Librería de ejecutables: $BINDIR"
	loguear "Directorio de arribos: $ARRIDIR"
	loguear "Espacio mínimo reservado en $ARRIDIR: "$DATASIZE"Mb"
	loguear "Directorio para los archivos de Log: $LOGDIR"
	loguear "Extensión para los archivos de Log: $LOGEXT"
	loguear "Tamaño máximo para cada archivo de Log: "$LOGSIZE"Kb"
	loguear "Log de la instalación: $ARCHIVO_LOG"

	loguear "Si los datos ingresados son correctos oprima solo ENTER para iniciar la instalación. Si desea modificar alguno de ellos oprima cualquier tecla"
	loguear "************************************************************************"
}


########## PASO 13 : CONFIRMAR INICIO DE INSTALACION ##########
confirmarInicioInstalacion(){
	loguear "Iniciando Instalación... Está UD. seguro? (Si/No) \\c"
	read respuesta
	loguear "$respuesta" s

	while [ "$respuesta" != "Si" -a "$respuesta" != "No" ]
	do
		loguear "La opción ingresada es incorrecta. ¿Usted está seguro de proseguir con la instalación? (Si/No) \\c"
		read respuesta
		loguear "$respuesta" s
	done

	if [ "$respuesta" = "No" ]
	then
		procesoCancelado
		fin
		exit 1;
	fi
}

########## PASO 14 : CREAR ESTRUCTURAS DE DIRECTORIO  ##########
crearEstructurasDeDirectorio(){
	loguear "Creando Estructuras de Directorio......."
	mkdir -p "$BINDIR"
	loguear "Proceso de creacion de directorio ($BINDIR) OK"
	mkdir -p "$ARRIDIR"
	loguear "Proceso de creacion de directorio ($ARRIDIR) OK"
	mkdir -p "$LOGDIR"
	loguear "Proceso de creacion de directorio ($LOGDIR) OK"
	mkdir -p "$GRUPO/recibidos"
	loguear "Proceso de creacion de directorio ($GRUPO/recibidos) OK"
	mkdir -p "$GRUPO/rechazados"
	loguear "Proceso de creacion de directorio ($GRUPO/rechazados) OK"
	mkdir -p "$GRUPO/nuevos"
	loguear "Proceso de creacion de directorio ($GRUPO/nuevos) OK"
	mkdir -p "$GRUPO/procesados"
	loguear "Proceso de creacion de directorio ($GRUPO/procesados) OK"
	mkdir -p "$GRUPO/list"
	loguear "Proceso de creacion de directorio ($GRUPO/list) OK"
}

########## PASO 15 : INSTALACION ##########
instalar () {
	loguear "Iniciando instalación"
	loguear "Moviendo archivos"
	local postini="$TARDIR/postini.sh"
	local service_instula_conf_conf="$BINDIR/service_instula_conf.conf"
	local service_instula_conf="$TARDIR/service_instula_conf.sh"
	local gralog="$TARDIR/gralog.sh"
	local postonio="$TARDIR/postonio.sh"
	local postular="$TARDIR/postular.sh"
	local postlist="$TARDIR/plist.pl"
	local agencia_helpers="$TARDIR/agencia_helpers.sh"
	local beneficio_helpers="$TARDIR/beneficio_helpers.sh"
	local clobber="$TARDIR/clobber.sh"
	local mover="$TARDIR/mover.sh"
	local utils="$TARDIR/utils.sh"
	# TODO Importante: los archivos van a ser movidos desde el directorio patron TARDIR
	# TODO mover los archivos del paquete postula
	#copiar ademas service_instula_conf.sh

	if [ ! -f "$postini" -o ! -f "$service_instula_conf" -o ! -f "$postonio" -o ! -f "$postular" -o ! -f "$postlist" -o ! -f "$gralog" -o ! -f "$mover" -o ! -f "$agencia_helpers" -o ! -f "$beneficio_helpers" -o ! -f "$clobber" -o ! -f "$utils" ]
	then
		loguear "Falta uno de los componentes, para poder continuar con la instalacion"
		procesoCancelado
		fin
		exit 1
	fi
	cp "$service_instula_conf" "$BINDIR"
	cp "$agencia_helpers" "$BINDIR"
	cp "$beneficio_helpers" "$BINDIR"
	cp "$clobber" "$BINDIR"
	cp "$mover" "$BINDIR"
	cp "$utils" "$BINDIR"
	cp "$service_instula_conf" "$BINDIR"
	echo "$INSTULA_CONF">>"$service_instula_conf_conf"
	cp "$gralog" "$BINDIR"
	cp "$postini" "$BINDIR"
	POSTINI=`date "+%d-%m-%Y %H:%M.%N"`
	loguear "Instalación del componente POSTINI completada"
	
	cp "$postonio" "$BINDIR"
	POSTONIO=`date "+%d-%m-%Y %H:%M.%N"`
	loguear "Instalación del componente POSTONIO completada"
	
	cp "$postular" "$BINDIR"
	POSTULAR=`date "+%d-%m-%Y %H:%M.%N"`
	loguear "Instalación del componente POSTULAR completada"
	
	cp "$postlist" "$BINDIR"
	POSTLIST=`date "+%d-%m-%Y %H:%M.%N"`
	loguear "Instalación del componente PLIST.PL completada"
}

########## PASO 16 : GUARDAR LA INFORMACION DE LA INSTALACION ##########
guardarInformacionInstalacion () {
	>$INSTULA_CONF
	"$BINDIR/service_instula_conf.sh" CURRDIR "$GRUPO"
	"$BINDIR/service_instula_conf.sh" ARRIDIR "$ARRIDIR"
	"$BINDIR/service_instula_conf.sh" BINDIR "$BINDIR"
	"$BINDIR/service_instula_conf.sh" CONFDIR "$CONFDIR"
	"$BINDIR/service_instula_conf.sh" DATASIZE "$DATASIZE"
	"$BINDIR/service_instula_conf.sh" LOGDIR "$LOGDIR"
	"$BINDIR/service_instula_conf.sh" LOGEXT "$LOGEXT"
	"$BINDIR/service_instula_conf.sh" MAXLOGSIZE "$LOGSIZE"
	"$BINDIR/service_instula_conf.sh" USERID "$USERID"
	"$BINDIR/service_instula_conf.sh" FECINST "$FECINST"
	#Escribo hasta la linea 20
	local lineas_faltantes=$((20-`cat "$INSTULA_CONF" | wc -l`))
	for i in $(seq $lineas_faltantes)
	do
		echo "">>"$INSTULA_CONF"
	done
	"$BINDIR/service_instula_conf.sh" POSTINI "$POSTINI"
	"$BINDIR/service_instula_conf.sh" POSTONIO "$POSTONIO"
	"$BINDIR/service_instula_conf.sh" POSTULAR "$POSTULAR"
	"$BINDIR/service_instula_conf.sh" POSTLIST "$POSTLIST"
	"$BINDIR/service_instula_conf.sh" POSTONIO_TIEMPO_ESPERA "$POSTONIO_TIEMPO_ESPERA"
	"$BINDIR/service_instula_conf.sh" DATADIR "$GRUPO/data"
	"$BINDIR/service_instula_conf.sh" NUEVOS "$GRUPO/nuevos"
	"$BINDIR/service_instula_conf.sh" RECIBIDOS "$GRUPO/recibidos"
	"$BINDIR/service_instula_conf.sh" PROCESADOS "$GRUPO/procesados"
	"$BINDIR/service_instula_conf.sh" RECHAZADOS "$GRUPO/rechazados"
	"$BINDIR/service_instula_conf.sh" LISTDIR "$GRUPO/list"
}

########## PASO 17 : BORRAR ARCHIVOS TEMPORARIOS ##########
borrarArchivosTemporarios () {
	loguear "Borro archivos temporarios"
}

########## PASO 18 : MOSTRAR MENSAJE INDICANDO QUE FUE LO QUE SE INSTALO ########## 
mostrarMensajesInstalacion(){
	loguear "*************************************************************"
	loguear "* Se encuentran instalados los siguientes componentes:\t\t*"
	loguear "* POSTINI  <$POSTINI> <$USERID>\t\t*"
	loguear "* POSTONIO <$POSTONIO> <$USERID>\t\t*"
	loguear "* POSTLIST <$POSTLIST> <$USERID>\t\t*"
	loguear "* POSTULAR <$POSTULAR> <$USERID>\t\t*"
	loguear "**************************************************************"
	loguear "* FIN del Proceso de Instalación de Postulantes              *"
	loguear "*          Copyright TPSistemasOp (c)2011                    *"
	loguear "**************************************************************"
	loguear "Presione ENTER para salir"
	local respuesta
	read respuesta
	loguear "$respuesta" s
	fin
}

########## PASO 19 : FIN ##########
# Metodo de finalizacion de instalacion
fin () {
	#TODO cerrar instula.log
	loguear "Fin archivo - instula.log (cerrado)" s
}


antesDeInstula
inicializarArchivoLog
isPostulaInstalado
consultaLicencia
isPerlInstalado

while [ ! -z "$ACEPTO_TERMINOS" ]
do
	mensajesInformativos
	definirDirectorioEjecutables
	definirDirectorioArriboArchivos
	definirEspacioMinimoDatos
	verificarEspacioEnDisco
	definirDirectorioArchivosLog
	definirExtensionArchivosLog
	definirTamanioArchivosLog
	mostrarEstructuraDirectoriosYValoresParametros
	read ACEPTO_TERMINOS	
done
confirmarInicioInstalacion
crearEstructurasDeDirectorio
instalar
guardarInformacionInstalacion
borrarArchivosTemporarios
mostrarMensajesInstalacion
exit 0
