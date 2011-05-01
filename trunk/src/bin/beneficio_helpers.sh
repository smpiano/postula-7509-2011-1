buscar_beenficio() {
  grep "^$1," $MAESTRO_BENEFICIOS
}

fecha_baja_beneficio() {
  echo $1 | cut -f 1 -d ,
}
