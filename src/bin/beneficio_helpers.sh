# Id de Beneficio, numérico
# Código de beneficio, 5 caracteres
# Sponsor	N caracteres, ejemplos: Banco Mundial, Naciones Unidas, Presidencia, Fontar, Fonsoft
# Fecha Inicio Beneficio, aaaa-mm-dd
# Fecha Fin Beneficio, aaaa-mm-dd
# Duración máxima beneficio, numérico	
buscar_beneficio() {
  grep "^[^,]*,$1," $MAESTRO_BENEFICIOS
}

fecha_inicio_beneficio() {
  echo $1 | cut -f 4 -d ,
}

fecha_baja_beneficio() {
  echo $1 | cut -f 5 -d ,
}

duracion_maxima_beneficio() {
  echo $1 | cut -f 6 -d ,
}
