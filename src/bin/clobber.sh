root_dir=${1:-$PWD/grupo02}
rm $root_dir/benef.*
rm $root_dir/benerro.*
rm $root_dir/logs/*
mv $root_dir/procesados/* $root_dir/arribos
mv $root_dir/rechazados/* $root_dir/arribos
