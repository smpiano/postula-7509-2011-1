#!/bin/bash
log() {
  comando=`basename $0`
  if [ -n "$VERBOSE" ]; then
    echo "-- $1" >&2
  fi
  gralog.sh "${comando%.*}" "${3:-$comando}" "${2:-A}" "$1"
}

info() {
  log "$1" "I" "${@:2}"
}

error() {
  log "$1" "E" "${@:2}"
}

error_severo() {
  log "$1" "ES" "${@:2}"
}

checkCurrentScriptAlreadyRunning() {
  # Listar todos los comandos | filtrar los que tienen el nombre de archivo y no son 'grep' | contar la cantidad de comandos
  count=`ps eo command='' | grep -v grep | grep -c -e "$0"`
  # Descontar el fork creado por el backtick
  count=$(( $count - 1 ))

  if [[ ! $count -eq 1 ]]
  then
    error "process is already running $0 `ps eo command='' | grep -v grep`"
    # Salir con false para poder manejar cancelación del script
    false
  fi
}

checkEnvironmentLoaded() {
  # TODO: decidir de que manera saber si el ambiente está inicializado
  if [[ ! -n "${POSTULA_ENV+x}" ]]
  then
    error "Environment not loaded :("
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
  if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    date -j -f "%Y-%m-%d" "$1" 2> /dev/null
  else
    date +"%Y-%m-%d" --date "$1"
  fi
}

sumarMeses() {
  if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    fecha_en_segundos=`date -j -f "%Y-%m-%d" "$1" +"%s" 2> /dev/null || date +"%s"`
    date -j -r $(expr $fecha_en_segundos + ${2:-0} \* 2592000 2> /dev/null || echo "0") +"%Y-%m-%d" 2> /dev/null || $1
  else
    date --date "$1 +$2 month"
  fi
}

mover() {
  mover.sh "$@"
}
