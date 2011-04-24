#!/bin/bash
source ./utils.sh
source ./agencia_helpers.sh

# Esto debería ser hecho sólo por postini...
initPostulaEnvironment

# die if existe otro postular corriendo
checkCurrentScriptAlreadyRunning || exit 1

# die if el ambiente no esta cargado
checkEnvironmentLoaded || exit 1

# Por cada archivo a procesar
checkFormatoNovedad() {
  true
}

checkCamposNovedad() {
  true
}

generarBeneficio() {
  echo "hola"
}

while next_file=`ls | grep '^.\{6\}\.[0-9]\{1,\}$' | head -n 1`; [[ $next_file != '' ]]; do
  # Rechazar si agencia no existe
  agencia=${next_file::6}
  info_agencia=`buscar_agencia $agencia`
  if [[ -z $info_agencia ]]; then
    log "agencia desconocida $agencia, se rechaza el archivo $next_file"
    mv $next_file $next_file.invalido
    continue
  fi

  echo $info_agencia
  while read novedad; do
    echo $novedad
    # Validar formato registro
    checkFormatoNovedad $novedad || continue
    # Validar campos
    checkCamposNovedad $novedad || continue
    # Calcular campos
    generarBeneficio $novedad >> novedades.$$
  done < "$next_file"

  # Enviar a recibidos
  mv $next_file $next_file.old
done

# presentar estadisticas

