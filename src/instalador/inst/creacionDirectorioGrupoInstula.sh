#Este script verifica si el directorio actual es el nuevo directorio
#En el caso de que lo sea, no hace nada
#En el caso de que no lo sea, crea dentro del directorio actual el nuevo directorio

NUEVO_DIRECTORIO=$1 
RUTA_A_CHECKEAR=$2
EVALUAR=`echo $RUTA_A_CHECKEAR | grep ".*/$NUEVO_DIRECTORIO\$"`
if [ -z "$EVALUAR" ]
then
	CURRENT="$RUTA_A_CHECKEAR/$NUEVO_DIRECTORIO"
	echo "El directorio \"$RUTA_A_CHECKEAR\" no contiene como ultmo directorio \"$NUEVO_DIRECTORIO\""
	if [ ! -d $CURRENT ]
	then
		mkdir -p $CURRENT;
		echo "Se creo el directorio, \"$CURRENT\".."
	else
		echo "El directorio \"$CURRENT\" ya existe."
	fi
else
	echo "El directorio \"$RUTA_A_CHECKEAR\" es el buscado"
fi
