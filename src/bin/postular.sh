#!/bin/bash
source utils.sh
source agencia_helpers.sh
source beneficio_helpers.sh

CAMPOS_NOVEDAD=( CUIL 'Tipo doc' 'Nro doc' Apellido Nombre Domicilio Localidad Provincia 'Código de Beneficio' 'Fecha pedido de Alta' 'Duración pedida' )

main() {

  # die if existe otro postular corriendo
  checkCurrentScriptAlreadyRunning || exit 1

  # die if el ambiente no esta cargado
  checkEnvironmentLoaded || exit 1

  cd $RECIBIDOS
  local output_file="$NUEVOS/benef.$$"
  local error_file="$NUEVOS/benerro.$$"

  while local archivo_novedades=`ls | grep '^.\{6\}\.[0-9]\{1,\}$' | head -n 1`; [[ $archivo_novedades != '' ]]; do
    # Rechazar si agencia no existe
    local agencia=${archivo_novedades::6}

    # Recuperar la información de la agencia
    DATOS_AGENCIA=`buscar_agencia $agencia`
    if [[ -z $DATOS_AGENCIA ]]; then
      log "Agencia desconocida $agencia, se rechaza el archivo $archivo_novedades"
      mover $archivo_novedades $RECHAZADOS
      continue
    fi

    info "Comenzando a procesar agencia: $agencia, archivo: $archivo_novedades"

    local numero_de_registros=0
    local cantidad_con_error=0
    local cantidad_nuevo=0
    while read novedad; do
      (( numero_de_registros= $numero_de_registros + 1 ))

      # Validar formato registro
      checkFormatoNovedad $archivo_novedades $numero_de_registros "$novedad" 2>> $error_file \
        || { ((cantidad_con_error= cantidad_con_error + 1)) && continue; }

      # Validar campos
      checkCamposNovedad $archivo_novedades $numero_de_registros "$novedad" \
        && ((cantidad_nuevo= cantidad_nuevo + 1))

      # Calcular campos
      generarBeneficio $archivo_novedades "$novedad" >> $output_file
    done < "$archivo_novedades"

    info "Se finalizó de procesar el archivo $archivo_novedades"
    info "- Total de registros           : $numero_de_registros"
    info "- Total de registros con error : $cantidad_con_error"
    info "- Total de beneficiarios nuevos: $cantidad_nuevo"

    # Enviar a recibidos
    mover "$archivo_novedades" "$PROCESADOS" postular
  done

  # presentar estadisticas
  exit 0
}

# Por cada archivo a procesar
checkFormatoNovedad() {
  # $1 => Nombre archivo
  # $2 => Numero de Registro
  # $3 => Registro de novedad
  local cantidad_de_campos=$(( `echo "$3" | grep -o ',' | wc -l` + 1 ))

  if [[ $cantidad_de_campos -eq 11 ]]; then

    # Convertir la novedad en un array
    ARRAY_NOVEDAD=()
    for i in {1..11}; do
      ARRAY_NOVEDAD[$i-1]=`echo $3 | cut -f $i -d ,`
    done

    # Validar campos obligatorios
    local error=""
    for i in {0..8}; do
      if [[ -z ${ARRAY_NOVEDAD[$i]} ]]; then
        rechazarRegistro "$@" "Campo ${CAMPOS_NOVEDAD[$i]} no informado"
        error='true'
        break
      fi
    done

    [[ $error != 'true' ]]

  elif [[ $cantidad_de_campos -lt 11 ]]; then

    rechazarRegistro "$@" 'Registro con campos de menos'
    false

  else # Mas de 11 campos

    rechazarRegistro "$@" 'Registro con campos de mas'
    false

  fi
}

checkCamposNovedad() {

  unset ESTADO_RECHAZO MOTIVOS_RECHAZO

  # Validar campos obligatorios
  for i in {0..8}; do
    if [[ -z ${ARRAY_NOVEDAD[$i]} ]]; then
      rechazarBeneficio "Campo ${CAMPOS_NOVEDAD[$i]} no informado"
    fi
  done

  if [[ ${#ARRAY_NOVEDAD[0]} -ne 11 ]]; then
    rechazarBeneficio "Campo ${CAMPOS_NOVEDAD[0]} tiene longitud errónea"
  fi

  if [[ ! "${ARRAY_NOVEDAD[0]}" =~ ^[0-9]*$ ]]; then
    rechazarBeneficio "Campo ${CAMPOS_NOVEDAD[0]} no tiene formato numérico"
  fi

  if [[ ${#ARRAY_NOVEDAD[2]} -ne 9 ]]; then
    rechazarBeneficio "Campo ${CAMPOS_NOVEDAD[2]} tiene longitud errónea"
  fi

  if [[ ! "${ARRAY_NOVEDAD[2]}" =~ ^[0-9]*$ ]]; then
    rechazarBeneficio "Campo ${CAMPOS_NOVEDAD[2]} no tiene formato numérico"
  fi

  datos_beneficio=`buscar_beneficio ${ARRAY_NOVEDAD[8]}`
  if [[ -z "$datos_beneficio" ]]; then
    rechazarBeneficio "No existe beneficio ${ARRAY_NOVEDAD[8]}"
  fi

  if [[ -n "${ARRAY_NOVEDAD[9]}" ]]; then
    if [[ ! `verificarFecha ${ARRAY_NOVEDAD[9]}` ]]; then
      rechazarBeneficio "FPA invalida ${ARRAY_NOVEDAD[9]}"
    fi
  fi

  FPB=$(fecha_baja_beneficio "$datos_beneficio")
  if [[ "${ARRAY_NOVEDAD[9]}" > "$FPB" ]]; then
    rechazarBeneficio "FPA (${ARRAY_NOVEDAD[9]}) mayor que FPB ($FPB)"
  fi

  DMB=$(duracion_maxima_beneficio "$datos_beneficio")
  if [[ ${ARRAY_NOVEDAD[10]:-0} -gt $DMB ]]; then
    rechazarBeneficio "DP (${ARRAY_NOVEDAD[10]}) mayor que DMB ($DMB)"
  fi

  if [[ ${ARRAY_NOVEDAD[10]:-1} -le 0 ]]; then
    rechazarBeneficio "DP (${ARRAY_NOVEDAD[10]}) menor o igual que 0"
  fi

  [[ "$ESTADO_RECHAZO" = "" ]]
}

generarBeneficio() {

  # $1 => Nombre archivo
  # $2 => Registro de novedad

  FC=`date +'%Y-%m-%d'`

  FPA=${ARRAY_NOVEDAD[9]}

  FIB=`fecha_inicio_beneficio "$datos_beneficio"`

  FEA=`mayor $FC $FPA $FIB`

  if [[ -n "$ESTADO_RECHAZO" ]]; then
    ESTADO=rechazado
  elif [[ "$FEA" > "$FC" ]]; then
    ESTADO=pendiente
  else
    ESTADO=aprobado
  fi

  DMB=`duracion_maxima_beneficio "$datos_beneficio"`
  DURACION=${ARRAY_NOVEDAD[10]:-$DMB}

  FF=`menor $(sumarMeses $FEA $DURACION) $(fecha_baja_beneficio "$datos_beneficio")`

  # Agencia, del nombre del archivo de postulantes \
  # Secuencia, del nombre del archivo de postulantes \
  # Los 10 primeros campos del archivo de postulantes (sin modificar)
  # Cuil, del archivo de postulantes
  # Tipo doc, del archivo de postulantes
  # Nro doc, del archivo de postulantes
  # Apellido, del archivo de postulantes
  # Nombre, del archivo de postulantes
  # Domicilio, del archivo de postulantes
  # Localidad, del archivo de postulantes
  # Provincia, del archivo de postulantes
  # Código de beneficio, del archivo de postulantes
  # Fecha Pedida de Alta , del archivo de postulantes
  # Fecha Efectiva de Alta, calculada
  # Estado, calculado, valores posibles: rechazado o aceptado o pendiente
  # Duración, del archivo de postulantes o calculada
  # Fecha Finalización, calculada
  # Motivo, N caracteres, explica el motivo del estado asignado
  # Usuario, calculado, nombre del usuario
  # Fecha Corriente, calculada, fecha actual
  printf "%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
    "`echo $1 | sed 's/\.\([^.]*\)$/,\1/'`" \
    "`echo $2 | cut -f 1-10 -d ,`" \
    "$FEA" "$ESTADO" "$DURACION" "$FF" "$MOTIVOS_RECHAZO" `whoami` "$FC"
}

rechazarRegistro() {
  # $1 => Nombre archivo
  # $2 => Numero de Registro
  # $3 => Registro de novedad
  # $4 => Motivo de Rechazo

  # Agencia, del nombre del archivo de postulantes
  # Secuencia, del nombre del archivo de postulantes
  # Numero de registro
  # Motivo
  # Registro original
  printf "%s,%s,%s,%s\n" \
    "`echo $1 | sed 's/\.\([^.]*\)$/,\1/'`" "$2" "$4" "$3" >&2
}

rechazarBeneficio() {
  MOTIVOS_RECHAZO=$MOTIVOS_RECHAZO${MOTIVOS_RECHAZO:+"|"}$1
  ESTADO_RECHAZO=1
}

main
