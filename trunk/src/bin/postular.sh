#!/bin/bash

source ./utils.sh

# Esto debería ser hecho sólo por postini...
initPostulaEnvironment

# die if existe otro postular corriendo
checkCurrentScriptAlreadyRunning || exit 1

# die if el ambiente no esta cargado
checkEnvironmentLoaded || exit 1

# Por cada archivo a procesar
next_file=`ls | grep '^.\{6\}\.[0-9]\{1,\}$' | head -n 1`
while [[ $next_file != '' ]]; do
  # Rechazar si agencia no existe
  # Validar formato registro
  # Validar campos
  # Calcular campos
  mv $next_file $next_file.old
  next_file=`ls | grep '^.\{6\}\.[0-9]\{1,\}$' | head -n 1`
done

# presentar estadisticas



