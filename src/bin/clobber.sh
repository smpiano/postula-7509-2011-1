[[ $# -eq 0 ]] && echo "Debe informar el directorio root a limpiar" && exit 1

root_dir=${1%/}
rm $root_dir/nuevos/benef.*
rm $root_dir/nuevos/benerro.*
rm $root_dir/logs/*
mv $root_dir/procesados/* $root_dir/rechazados/* $root_dir/recibidos/* $root_dir/arribos 2> /dev/null