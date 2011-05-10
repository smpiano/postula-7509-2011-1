#Este script verifica si el directorio actual es el nuevo directorio
#En el caso de que lo sea, no hace nada
#En el caso de que no lo sea, crea dentro del directorio actual el nuevo directorio

NUEVO_SUBDIRECTORIO=$1 
RUTA_A_CHECKEAR=$2
CURRENT="$RUTA_A_CHECKEAR/$NUEVO_SUBDIRECTORIO"
if [ ! -d "$CURRENT" ]
then
	echo "El directorio \"$RUTA_A_CHECKEAR\" no contiene como ultmo directorio a \"$NUEVO_SUBDIRECTORIO\""
	mkdir -p $CURRENT;
	echo "Se creo el directorio, \"$CURRENT\".."
else
	echo "El directorio \"$CURRENT\" ya existe."
fi
