buscar_agencia() {
  cat $MAESTRO_AGENCIAS | grep "^[^,]*,$1,"
}
