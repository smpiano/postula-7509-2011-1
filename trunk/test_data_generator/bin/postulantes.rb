#!/usr/bin/env ruby
require 'optparse'
require 'set'
require "forgery"

params = {
  target_file: $stdout,
  maestro_beneficios: 'beneficios.mae',
  agencias: %w[123456],
  registros: []
}

class RegistryOk

  TIPOS_DE_DOCUMENTO = %w[DU LC LE PA]

  def build(beneficios)
    beneficio_seleccionado = pick_beneficio(beneficios)
    [
      cuil,
      tipo_doc,
      nro_doc,
      apellido,
      nombre,
      domicilio,
      localidad,
      provincia,
      beneficio(beneficio_seleccionado),
      fecha_pedido_alta(beneficio_seleccionado),
      duracion_meses(beneficio_seleccionado),
    ].join(',')
  end

  def cuil
    "20-########-#".to_numbers
  end

  def tipo_doc
    TIPOS_DE_DOCUMENTO.sample
  end

  def nro_doc
    "#########".to_numbers
  end

  def apellido
    Forgery(:name).last_name
  end

  def nombre
    Forgery(:name).first_name
  end

  def domicilio
    Forgery(:address).street_address
  end

  def localidad
    Forgery(:address).city
  end

  def provincia
    Forgery(:address).state
  end

  def beneficio(beneficio_seleccionado)
    beneficio_seleccionado.codigo
  end

  def fecha_pedido_alta(beneficio_seleccionado)
    optional do
      duracion_en_dias = beneficio_seleccionado.fin - beneficio_seleccionado.inicio
      beneficio_seleccionado.inicio + rand(duracion_en_dias)
    end
  end

  def duracion_meses(beneficio_seleccionado)
    optional { rand(beneficio_seleccionado.duracion_maxima) + 1 }
  end

  def pick_beneficio(beneficios)
    beneficios.sample
  end

  private

  def optional
    rand > 0.1 ? yield : ''
  end

end

class RegistryError < Struct.new(:type, :ok_registry)

  def initialize(type, ok_registry = RegistryOk.new)
    super
  end

  def build(beneficios)
    beneficio_seleccionado = ok_registry.pick_beneficio(beneficios)
    [
      cuil,
      tipo_doc,
      nro_doc,
      apellido,
      nombre,
      domicilio,
      localidad,
      provincia,
      beneficio(beneficio_seleccionado),
      fecha_pedido_alta(beneficio_seleccionado),
      duracion_meses(beneficio_seleccionado),
      campo_extra
    ].compact.join(',')
  end

  def self.delegate_field(campo_obligatorio)
    define_method(campo_obligatorio) do |*args|
      if type == "no_#{campo_obligatorio}"
        ''
      else
        ok_registry.send campo_obligatorio, *args
      end
    end
  end

  %w[tipo_doc nro_doc apellido nombre domicilio localidad provincia beneficio].each do |campo_obligatorio|
    delegate_field(campo_obligatorio)
  end

  def cuil
    case type
    when 'menos_campos'
      nil
    when 'no_cuil'
      ''
    else
      ok_registry.cuil
    end
  end

  def fecha_pedido_alta
    ok_registry.fecha_pedido_alta
  end

  def duracion_meses
    ok_registry.duracion_meses
  end

  def campo_extra
    return 'campo basura' if type == 'campo_extra'
  end

end

OptionParser.new do |parser|

  parser.banner = "Usage: postulantes [options] [directory]"

  parser.on('--beneficios archivo_beneficios', 'archivo maestro de beneficios (por defecto beneficios.mae)') do |file_name|
    params[:maestro_beneficios] = file_name
  end

  parser.on('-o outputfile', 'archivo de salida (por defecto STDOUT)') do |file_name|
    params[:target_file] = File.open(file_name, 'w')
  end

  parser.on_tail('-h', '--help', "This is it!") do
    puts parser
    exit
  end

  parser.on('--reg_err tipos', 'Genera registros con errores a nivel registro de tipo') do |tipos|
    params[:registros].concat(tipos.split(':').map {|t| RegistryError.new(t) })
  end

  parser.on('--reg_ok cant') do |cant|
    registro_ok = RegistryOk.new
    cant.to_i.times do |_|
      params[:registros] << registro_ok
    end
  end

end.parse!(ARGV)

Beneficio = Struct.new(:codigo, :inicio, :fin, :duracion_maxima)

beneficios = File.readlines(params[:maestro_beneficios]).map do |beneficio|
  _, codigo, _, inicio, fin, duracion_maxima = beneficio.split(',')
  Beneficio.new(codigo, Date.parse(inicio), Date.parse(fin), duracion_maxima.to_i)
end

params[:registros].each do |registro|
  params[:target_file] << registro.build(beneficios)
  params[:target_file] << "\n"
end

params[:target_file].close unless params[:target_file] == $stdout

