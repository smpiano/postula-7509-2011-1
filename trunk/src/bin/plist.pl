#!/usr/bin/perl
#use strict;
#use warnings;
use Getopt::Long;

########## Cuerpo Principal ###########

#my %args;
#getopts("cde:t",\%args);

my @agencias;
my @beneficios;
my @archivos;
my @estados;
my $genera_matriz;
my $salida_archivo;
my $salida_pantalla;

my $parametros;
my $i = 0;
while ($i < @ARGV) {
	$parametros.=$ARGV[$i]." ";
	$i++;
}

# Parseo de argumentos

my $resultado = GetOptions(	
	"a:s{,}" => \@agencias,
	"b:s{,}" => \@beneficios,
	"c" => \$genera_matriz,
	"d" => \$salida_archivo,
	"e:s{,}" => \@estados,
	"f:s{,}" => \@archivos,
	"t" => \$salida_pantalla,
);

# Validacion de los parametros ingresados

validar_archivos(@archivos);
validar_agencias(@agencias);
validar_beneficios(@beneficios);
validar_estados(@estados);
validar_argumentos(@ARGV);
setear_salida($salida_pantalla, $salida_archivo);
mostrar_encabezado($parametros);


# Generacion del listado de nuevos beneficiarios

$i = 0;
while ($i < @archivos) {
	imprimir_linea_divisoria("*");

	my $input;
	if (!open($input, "<", $archivos[$i])) {
		print "No se puede abrir $archivos[$i]: $!\n";
	}else{
		print "Archivo: ".$archivos[$i]."\n";
		imprimir_linea_divisoria();
		print "Benef. Agencia CUIL        Apellido           Provincia     Estado    FEA\n";
		imprimir_linea_divisoria();

		my %matriz_control;
		my @beneficios_matriz;
		my $nro_linea = 0;
		my $cant_registros = 0;

		while (my $linea = <$input>) {
			$nro_linea++;
			my @registros = split(",",$linea);

			if (@registros == 19) {

				# Ajusto los campos a mostrar para que tengan una longitud fija
				my $beneficio = pack("A5",$registros[10]);
				my $agencia = pack("A6",$registros[0]);
				my $cuil = pack("A11",$registros[2]);
				my $apellido = pack("A18",$registros[5]);
				my $provincia = pack("A13",$registros[9]);
				my $estado = pack("A9",$registros[13]);
				my $fecha_efectiva_alta = pack("A10",$registros[12]);

				# Verifico que coincidan la agencia, beneficio y estado, con los filtros ingresados por linea de comandos
				next unless coincide_agencia($agencia, @agencias);
				next unless coincide_beneficio($beneficio, @beneficios);
				next unless coincide_estado($estado, @estados);

				if ($genera_matriz) {
					# Genero la matriz de control (hash de hashes) e incremento la cantidad de beneficiarios por provincia y beneficio.
					$matriz_control{$provincia}{$beneficio} ++;

					# Guardo una lista de todos los beneficios que se muestran
					push(@beneficios_matriz, $beneficio) unless arreglo_contiene_elemento($beneficio, @beneficios_matriz);
				}

				print $beneficio."  ".$agencia."  ".$cuil." ".$apellido." ".$provincia." ".$estado." ".$fecha_efectiva_alta."\n";
				$cant_registros++;
			}else{
				print "Error en el formato del registro en la linea $nro_linea.\n";
			}
		}
		imprimir_linea_divisoria();
		print "Total de beneficiarios: ".$cant_registros."\n";


		# Impresion de la matriz de control por provincia/beneficio

		if ($genera_matriz) {
			### validar que la matriz entre en la pantalla, sino sale solo por archivo.
			imprimir_linea_divisoria();
			print "Matriz de Control por Provincia/Beneficio:\n";
			imprimir_linea_divisoria();

			# Imprimo los nombres de los beneficios en la primera fila de la matriz
			my $fila0 = "             |";
			foreach my $beneficio (sort @beneficios_matriz) {
				$fila0 .= $beneficio."|";
			}
			print $fila0."TOTAL|\n";
		
			my %total_por_beneficio;
			# Imprimo por cada provincia la cantidad de beneficiarios de cada beneficio
			foreach my $provincia (sort keys %matriz_control) {

				my $fila .= $provincia."|";
				my $total_por_provincia = 0;

				foreach my $beneficio (sort @beneficios_matriz) {
					my $cantidad_beneficiarios = $matriz_control{$provincia}{$beneficio};
					$total_por_beneficio{$beneficio} += $cantidad_beneficiarios;
					$total_por_provincia += $cantidad_beneficiarios;
					### validar que la cantidad no sea mayor a 5 cifras.
					$cantidad_beneficiarios = formatear_cantidad($cantidad_beneficiarios);
					$fila .= $cantidad_beneficiarios."|";
				}
				$total_por_provincia = formatear_cantidad($total_por_provincia);
				$fila .= $total_por_provincia."|";
				print $fila."\n";
			}

			# Imprimo los totales por beneficio en la ultima linea
			my $fila_totales = "TOTAL        |";
			my $total_ultima_celda;
			foreach my $beneficio (sort @beneficios_matriz) {
				my $subtotal = $total_por_beneficio{$beneficio};
				$total_ultima_celda += $subtotal;
				$subtotal = formatear_cantidad($subtotal);
				$fila_totales .= $subtotal."|";
			}
			$total_ultima_celda = formatear_cantidad($total_ultima_celda);
			$fila_totales .= $total_ultima_celda."|";
			print $fila_totales."\n";
		}

		close $input;
	}
	$i++;
}

close STDOUT;

exit 0;


########## Subrutinas ###########

sub validar_archivos {
	@archivos = @_;
	if (@archivos == 0 || $archivos[0] eq "") {
		print "No se encontraron archivos para procesar. Debe ingresar la opcion -f junto con los archivos que desea procesar.\n";
		mostrar_mensaje_ayuda();
		exit 1;
	}
}

sub validar_agencias {
	@agencias = @_;
	if (@agencias > 0 && $agencias[0] eq "") {
		print "Debe ingresar las agencias junto con la opcion -a. Para todas las agencias no ingrese dicha opcion.\n";
		mostrar_mensaje_ayuda();
		exit 1;
	}
}

sub validar_beneficios {
	@beneficios = @_;
	if (@beneficios > 0 && $beneficios[0] eq "") {
		print "Debe ingresar los beneficios junto con la opcion -b. Para todos los beneficios no ingrese dicha opcion.\n";
		mostrar_mensaje_ayuda();
		exit 1;
	}
}

sub validar_estados {
	@estados = @_;
	if (@estados > 0) {
		if ($estados[0] eq "") {
			print "Debe ingresar los estados que desea filtrar junto con la opcion -e. Para todos los estados no ingrese dicha opcion. ";
			print "Los estados posibles son \"a\" (aceptados) y \"p\" (pendientes).\n";
			mostrar_mensaje_ayuda();
			exit 1;
		}else{
			if (@estados > 2 || $estados[0] ne "a" && $estados[0] ne "p" || @estados == 2 && $estados[1] ne "a" && $estados[1] ne "p") {
				print "Los estados posibles son \"a\" (aceptados) y \"p\" (pendientes).\n";
				mostrar_mensaje_ayuda();
				exit 1;
			}
		}
	}
}

sub validar_argumentos {
	my @argumentos = @_;
	if (@argumentos != 0) {
		print "Los argumentos ingresados son incorrectos.\n";
		mostrar_mensaje_ayuda();
		exit 1;
	}
}

sub mostrar_mensaje_ayuda {
	print "Para ver la ayuda ejecute el comando con la opcion -h.\n";
}

sub setear_salida {
	my ($salida_pantalla, $salida_archivo) = @_;

	if ($salida_pantalla || !$salida_archivo) {
		system "clear";
	}

	if ($salida_archivo) {
		my $LISTDIR;
		my $SECUENCIA_LISTADOS;

		if ($ENV{"LISTDIR"}) {
			$LISTDIR = $ENV{"LISTDIR"};
		}else{
			print "No se encuentra seteada la variable de entorno \"LISTDIR\". Debe ejecutar \"postini\" previamente para poder usar \"plist\".\n";
			exit 1;
		}

		if ($ENV{"SECUENCIA_LISTADOS"}) {
			$SECUENCIA_LISTADOS = $ENV{"SECUENCIA_LISTADOS"};
		}else{
			print "No se encuentra seteada la variable de entorno \"SECUENCIA_LISTADOS\". Debe ejecutar \"postini\" previamente para poder usar \"plist\".\n";
			exit 1;
		}
		$SECUENCIA_LISTADOS++;
		my $archivo_salida = "$LISTDIR/plist.$SECUENCIA_LISTADOS";
		if ($salida_pantalla) {
			open(STDOUT, "| tee -i $archivo_salida");
		} else {
			open(STDOUT, ">", $archivo_salida);
		}
	}
}

sub imprimir_linea_divisoria {
	my $caracter = shift;
	$caracter = "-" unless $caracter;
	my $linea_divisoria;
	for(my $i=0; $i < 80; $i++){
		$linea_divisoria .= $caracter;
	}
	print $linea_divisoria."\n";
}

sub mostrar_encabezado {
	$parametros = shift;
	my $fecha = `date`;
	my $user = `whoami`;
	imprimir_linea_divisoria("*");
	print "*                                    PLIST                                     *\n";
	imprimir_linea_divisoria("*");
	print "Fecha: $fecha";
	print "Usuario: $user";
	print "Parametros: $parametros\n";
}

sub coincide_agencia {
	my ($agencia, @agencias) = @_;
	if (@agencias > 0 && $agencias[0] ne "") {
		return arreglo_contiene_elemento($agencia, @agencias);
	}
	return 1;
}

sub coincide_beneficio {
	my ($beneficio, @beneficios) = @_;
	if (@beneficios > 0 && $beneficios[0] ne "") {
		return arreglo_contiene_elemento($beneficio, @beneficios);
	}
	return 1;
}

sub arreglo_contiene_elemento {
	my ($elemento, @arreglo) = @_;
	foreach my $i (@arreglo) {
		return 1 if $i eq $elemento;
	}
	return 0;
}

sub coincide_estado {
	my ($estado, @estados) = @_;
	if (@estados == 1 && $estados[0] ne "") {
		return 1 if ($estados[0] eq "a" && $estado eq "aceptado ");
		return 1 if ($estados[0] eq "p" && $estado eq "pendiente");
		return 0;
	}
	return 1;
}

sub formatear_cantidad {
	($cantidad) = @_;
	$cantidad = sprintf("%5.0f", $cantidad);
	$cantidad = pack("A5",$cantidad);
}

