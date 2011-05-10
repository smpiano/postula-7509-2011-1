#!/bin/bash

NOMBRE_TAR='build.tar.gz'

# borra el tar si ya existe
if [ -e "$NOMBRE_TAR" ]
then
  rm "$NOMBRE_TAR"
fi

# borra los directorio si ya existen
if [ -e conf ]
then
  rm -r conf
fi

if [ -e data ]
then
  rm -r data
fi

if [ -e inst ]
then
  rm -r inst
fi

# crea los directorios
mkdir conf
mkdir data
mkdir inst

# copia los archivos
cp -ur src/data/* data

cp -ur src/instalador/instula.sh inst
cp -ur src/instalador/creacionDirectorioGrupoInstula.sh inst
cp -ur src/bin/*.sh inst
cp -ur src/bin/plist.pl inst

# borra los ocultos del svn
cd data
rm -rf `find . -type d -name .svn`
cd ..

cd inst
rm -rf `find . -type d -name .svn`
cd ..

# crea el tar
tar czfv $NOMBRE_TAR conf data inst

# borra los directorios
rm -r conf
rm -r data
rm -r inst

