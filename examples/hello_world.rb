require 'bundler/setup'
require 'voke'

class HelloWorld
  include Voke

  def hello(name = "world", options)
    puts "hello #{ name }"
  end
end

test = HelloWorld.new
test.voke("hello", *ARGV)
