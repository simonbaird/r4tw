
require 'test/unit'
require 'pathname'

# must be a prettier way to do this..

this_file = Pathname.new(__FILE__)#.realpath
this_dir = this_file.dirname

Dir.chdir this_dir

Dir["#{this_dir}/*.rb"].reject{|f| f == this_file.to_s}.each do |test_unit|
  require test_unit
end
