#!/bin/bash
source ./utils.sh
source ./agencia_helpers.sh
source ./beneficio_helpers.sh

DIR_ARRIBOS=arribos

CAMPOS_NOVEDAD=( CUIL 'Tipo doc' 'Nro doc' Apellido Nombre Domicilio Localidad Provincia 'Código de Beneficio' 'Fecha pedido de Alta' 'Duración pedida' )
main() {

  # Esto debería ser hecho sólo por postini...
  initPostulaEnvironment

  # die if existe otro postular corriendo
  checkCurrentScriptAlreadyRunning || exit 1

  # die if el ambiente no esta cargado
  checkEnvironmentLoaded || exit 1

  cd $DIR_ARRIBOS
  while next_file=`ls | grep '^.\{6\}\.[0-9]\{1,\}$' | head -n 1`; [[ $next_file != '' ]]; do
    # Rechazar si agencia no existe
    agencia=${next_file::6}
    info_agencia=`buscar_agencia $agencia`
    if [[ -z $info_agencia ]]; then
      log "agencia desconocida $agencia, se rechaza el archivo $next_file"
      mv $next_file $next_file.invalido
      continue
    fi

    contador=0
    while read novedad; do
      contador=$(( $contador + 1 ))

      # Validar formato registro
      checkFormatoNovedad $next_file $contador "$novedad" || continue

      # Validar campos
      checkCamposNovedad $next_file $contador "$novedad"

      # Calcular campos
      generarBeneficio $next_file "$novedad" >> novedades.$$
    done < "$next_file"

    # Enviar a recibidos
    mv $next_file $next_file.old
  done
  # presentar estadisticas

}

# Por cada archivo a procesar
checkFormatoNovedad() {
  # $1 => Nombre archivo
  # $2 => Numero de Registro
  # $3 => Registro de novedad
  cantidad_de_campos=$(( `echo "$3" | grep -o ',' | wc -l` + 1 ))

  if [[ $cantidad_de_campos -eq 11 ]]; then

    # Cambiar las comas por espacios y los espacios por comas
    # splittable=`echo "$3" | tr ' ,' ', '`

    # Convertir la novedad en un array
    ARRAY_NOVEDAD=()
    for i in {1..11}; do
      ARRAY_NOVEDAD[$i-1]=`echo $3 | cut -f $i -d ,`
    done
    # for campo in $splittable; do
    #   # Cargar el campo en el arreglo corrigiendo las comas por los espacios originales
    #   ARRAY_NOVEDAD[${#ARRAY_NOVEDAD[@]}]="`echo $campo | tr , ' '`"
    # done

    # Validar campos obligatorios
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

}

generarBeneficio() {

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

  # Agencia, del nombre del archivo de postulantes
  # Secuencia, del nombre del archivo de postulantes
  echo -n `echo $1 | sed 's/\.\([^.]*\)$/,\1/'`,
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
  echo -n "`echo $2 | cut -f 1-10 -d ,`",
  # Fecha Efectiva de Alta, calculada
  echo -n $FEA,
  # Estado, calculado, valores posibles: rechazado o aceptado o pendiente
  echo -n $ESTADO,
  # Duración, del archivo de postulantes o calculada
  echo -n $DURACION,
  # Fecha Finalización, calculada
  echo -n $FF,
  # Motivo, N caracteres, explica el motivo del estado asignado
  echo -n $MOTIVOS_RECHAZO,
  # Usuario, calculado, nombre del usuario
  echo -n `whoami`,
  # Fecha Corriente, calculada, fecha actual
  echo $FC
}

rechazarRegistro() {
  # $1 => Nombre archivo
  # $2 => Numero de Registro
  # $3 => Registro de novedad
  # $4 => Motivo de Rechazo
  echo "param 1 $1"
  echo "param 2 $2"
  echo "param 3 $3"
  echo "param 4 $4"
}

rechazarBeneficio() {
  MOTIVOS_RECHAZO=$MOTIVOS_RECHAZO${MOTIVOS_RECHAZO:+"|"}$1
  ESTADO_RECHAZO=1
}

main
