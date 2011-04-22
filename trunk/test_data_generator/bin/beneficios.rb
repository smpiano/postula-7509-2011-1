#!/usr/bin/env ruby -KU
require 'optparse'
require 'set'
require "forgery"

params = {
  count: 50,
  target_file: $stdout
}

OptionParser.new do |parser|

  parser.banner = "Usage: agencias [options] [directory]"

  parser.on('-n count', 'genera <count> agencias (por defecto 50)') do |count|
    params[:count] = count.to_i
  end

  parser.on('-o outputfile', 'archivo de salida (por defecto STDOUT)') do |file_name|
    params[:target_file] = File.open(file_name, 'w')
  end

  parser.on_tail('-h', '--help', "This is it!") do
    puts parser
    exit
  end

end.parse!(ARGV)

key_chars     = ('a'..'z').to_a + ('0'..'9').to_a
existing_keys = Set.new
sponsors      = %w[Banco\ Mundial Naciones\ Unidas Presidencia Fontar Fontsoft]
new_key = nil

params[:count].times do |i|
  new_key = key_chars.sample(5).join('') while new_key.nil? || existing_keys.include?(new_key) 
  existing_keys << new_key
  initial_date = Date.today - 15 * rand(100) + 750
  params[:target_file] << [
    i + 1,
    new_key,
    sponsors.sample,
    initial_date,
    initial_date + 365 * (rand(4) + 1),
    rand(24) + 1
  ].join(',')
  params[:target_file] << "\n"
end

params[:target_file].close unless params[:target_file] == $stdout
