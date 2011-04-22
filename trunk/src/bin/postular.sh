#!/bin/bash

source ./utils.sh

# Esto debería ser hecho sólo por postini...
initPostulaEnvironment

# die if existe otro postular corriendo
checkCurrentScriptAlreadyRunning || exit 1

# die if el ambiente no esta cargado
checkEnvironmentLoaded || exit 1

# Por cada archivo a procesar
  # Rechazar si agencia no existe
  # Validar formato registro
  # Validar campos
  # Calcular campos

# presentar estadisticas



