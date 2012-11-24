require 'bundler/setup'
require 'voke'

class HelloWorld
  include Voke

  def hello(name, params = Hash.new)
    puts "instance says 'hello #{ name }!'"
  end

  def self.hello(name, params = Hash.new)
    puts "static says 'hello #{ name }!'"
  end
end

puts "-- you can invoke static methods from the command line --"
HelloWorld.voke("hello", *ARGV)
puts

puts "-- you can invoke instance methods from the command line --"
test = HelloWorld.new
test.voke("hello", *ARGV)
puts

puts "-- and of course, you can call these methods normally --"
HelloWorld.hello(*ARGV)
test.hello(*ARGV)
puts
