require 'bundler/setup'
require 'voke'

class Arguments
  include Voke

  default :greet, "world"
  default :excited do |options|
    options[:greet] == "world"
  end

  def list(*args, options)
    puts "arguments: #{ args.inspect }"
    puts "options: #{ options.inspect }"
  end
end

Arguments.new.voke("list", *ARGV)
