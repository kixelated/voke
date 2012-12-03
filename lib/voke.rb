require "voke/version"

module Voke
  def self.included(klass)
    # adds static methods as well
    klass.extend(self)
  end

  def help(command, *args)
    if respond_to?(command.to_sym)
      methods = [ command ]
    else
      methods = self.public_methods(false)
    end

    methods.each do |method_name|
      method = self.method(method_name)
      parameters = method.parameters

      parts = parameters.collect do |type, name|
        case type
        when :req
          name
        when :opt
          "[#{ name }]"
        when :part
          "[#{ name }*]"
        end
      end

      puts "#{ $0 } #{ method_name } #{ parts.join(' ') }"
    end
  end

  def voke(*args)
    args = ARGV if args.empty?

    command, arguments, options = voke_parse(*args)
    voke_method(command, arguments, options)
  end

  def voke_method(command, arguments, options)
    method = method(command.to_sym)
    method.call(*arguments, options)
  rescue
    help(command, *arguments, options)
  end

  def voke_parse(*args)
    command = args.shift
    arguments = Array.new
    options = Hash.new

    args.each do |arg|
      if arg =~ /^--(\w+)=(.*)$/
        key = $1.to_sym
        value = voke_parse_value($2)

        options[key] = value
      else
        key = nil
        value = voke_parse_value(arg)

        arguments << value
      end
    end

    [ command, arguments, options ]
  end

  def voke_parse_value(value)
    case value
    when "", "nil"
      nil
    when "true"
      true
    when "false"
      false
    when /^-?\d+$/
      value.to_i
    when /^-?\d*\.\d*$/
      value.to_f
    when /^['"](.+)['"]$/
      $1
    when /^(.*),(.*)$/
      value = value.split(',')
      value.collect { |v| voke_parse_value(v) }
    else
      value
    end
  end
end
