#!/bin/bash
source ./utils.sh
source ./agencia_helpers.sh
source ./beneficio_helpers.sh

DIR_ARRIBOS=arribos

CAMPOS_NOVEDAD=( '' CUIL 'Tipo doc' 'Nro doc' Apellido Nombre Domicilio Localidad Provincia 'Código de Beneficio' 'Fecha pedido de Alta' 'Duración pedida' )
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
    # echo $info_agencia
    while read novedad; do
      contador=$(( $contador + 1 ))

      # Validar formato registro
      checkFormatoNovedad $next_file $contador "$novedad" || continue

      # Validar campos
      checkCamposNovedad $next_file $contador "$novedad" || continue

      # Calcular campos
      generarBeneficio "$novedad" >> novedades.$$
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
    splittable=`echo "$3" | sed "s/\([^,]*\)/'\1'/g" | tr ',' ' '`

    # Convertir la novedad en un array
    ARRAY_NOVEDAD=()
    for campo in $splittable; do
      # XXX: Check if can do this assignment without seding the quotes
      ARRAY_NOVEDAD[${#ARRAY_NOVEDAD[*]} + 1]=`echo "$campo" | sed "s/'//g"`
    done

    # Validar campos obligatorios
    for i in {1..9}; do
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

  $datos_beneficio=`buscar_beneficio ${ARRAY_NOVEDAD[8]}`
  if [[ ! -z "$datos_agencia" ]]; then
    rechazarRegistro "$@" "No existe beneficio ${ARRAY_NOVEDAD[8]}"
    return 0
  fi

  if [[ ! `verificarFecha ${ARRAY_NOVEDAD[10]}` ]]; then
    rechazarRegistro "$@" "FPA invalida ${ARRAY_NOVEDAD[10]}"
    return 0
  fi

  FPB=$(fechaBajaBeneficio "$datos_beneficio")
  if [[ `fechaEnSegundos "${ARRAY_NOVEDAD[10]}"` -gt \
        `fechaEnSegundos "$FPB"`
    ]]; then
    rechazarRegistro "$@" "FPA (${ARRAY_NOVEDAD[10]}) mayor que FPB ($FPB)"
    return 0
  fi

  DMB=$(duracionMaximaBeneficio "$datos_beneficio")
  if [[ ${ARRAY_NOVEDAD[11]-0} -gt $DMB ]]; then
    rechazarRegistro "$@" "DP (${ARRAY_NOVEDAD[11]}) mayor que DMB ($DMB)"
    return 0
  fi

  if [[ ${ARRAY_NOVEDAD[11]-1} -le 0 ]]; then
    rechazarRegistro "$@" "DP (${ARRAY_NOVEDAD[11]}) menor o igual que 0"
    return 0
  fi

  true
}

generarBeneficio() {
  echo "hola"
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

main
