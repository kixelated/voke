require 'bundler/setup'
require 'voke'

class Arguments
  include Voke

  def self.list(*args, options)
    puts "arguments: #{ args.inspect }"
    puts "options: #{ options.inspect }"
  end
end

Arguments.voke("list", *ARGV)
