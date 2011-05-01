#!/bin/bash
log() {
  # TODO: Reemplazar por la llamada al script logger
  echo $1
}

checkCurrentScriptAlreadyRunning() {
  # Listar todos los comandos | filtrar los que tienen el nombre de archivo y no son 'grep' | contar la cantidad de comandos
  count=`ps eo command=''  | grep -e "$0" | grep -v grep | wc -l`
  # Descontar el fork creado por el backtick
  count=$(( $count - 1 ))

  if [[ ! $count -eq 1 ]]
  then
    log "process is already running $0"
    # Salir con false para poder manejar cancelación del script
    false
  fi
}

initPostulaEnvironment() {
  # TODO: decidir de que manera saber si el ambiente está inicializado
  export POSTULA_ENV='something' MAESTRO_AGENCIAS='agencias.mae' MAESTRO_BENEFICIOS='beneficios.mae'
}

checkEnvironmentLoaded() {
  # TODO: decidir de que manera saber si el ambiente está inicializado
  if [[ ! -n "${POSTULA_ENV+x}" ]]
  then
    log "Environment not loaded :("
    # Salir con false para poder manejar cancelación del script
    false
  fi
}

mayor() {
  # Mientras que tenga mas de dos parámetros
  while [[ $# -ge 2 ]]; do
    # Si el primero (que es el que va a descartar el shift)
    # es mayor, entonces invierto el orden para descartar el segundo
    if [[ "$1" > "$2" ]]; then
      set "$2" "$1" "${@:3}"
    fi
    shift
  done
  echo $1
}

menor() {
  # Mientras que tenga mas de dos parámetros
  while [[ $# -ge 2 ]]; do
    # Si el primero (que es el que va a descartar el shift)
    # es mayor, entonces invierto el orden para descartar el segundo
    if [[ "$1" < "$2" ]]; then
      set "$2" "$1" "${@:3}"
    fi
    shift
  done
  echo $1
}

verificarFecha() {
  if [[ "$TERM_PROGRAM" = "Apple_Terminal" ]]; then
    date -j -f "%Y-%m-%d" "$1" 2> /dev/null
  else
    date +"%Y-%m-%d" --date "$1"
  fi
}

sumarMeses() {
  if [[ "$TERM_PROGRAM" = "Apple_Terminal" ]]; then
    date -j -r $(expr `date -j -f "%Y-%m-%d" "$1" +"%s"` + $2 \* 2592000) +"%Y-%m-%d"
  else
    date --date "$1 +$2 month"
  fi
}
