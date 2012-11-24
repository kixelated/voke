require "voke/version"

module Voke
  def self.included(klass)
    # adds static methods as well
    klass.extend(self)
  end

  def voke(*argv)
    command, arguments, options = voke_parse(*argv)
    voke_method(command, arguments, options)
  end

  def voke_method(command, arguments, options)
    raise "Show help" unless command
    method = method(command.to_sym)

    method_arity = method.arity
    method_parameters = method.parameters

    if method_arity < 0
      method_req = -method_arity - 1
      method_opt = method_parameters.size - method_req
    else
      method_req = method_arity
      method_opt = 0
    end

    arg_req = arguments.length

    last_type, _ = method_parameters.last
    last_req = (last_type == :req) ? 1 : 0

    if arg_req >= method_req + method_opt
      method.call(*arguments)
    elsif arg_req + last_req >= method_req
      method.call(*arguments, options)
    else
      raise ArgumentError, "wrong number of arguments (#{ arg_req + last_req } for #{ method_req })"
    end
  end

  def voke_parse(*argv)
    command = argv.shift
    arguments = Array.new
    options = Hash.new

    argv.each do |arg|
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
