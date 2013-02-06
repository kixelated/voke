require "voke/version"

module Voke
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  def self.extended(klass)
    klass.extend(ClassMethods)
  end

  def help(command, *args)
    command = command.to_sym rescue nil

    if command and respond_to?(command)
      methods = [ command ]
    else
      methods = self.class.public_instance_methods(false)
    end

    methods.each do |method_name|
      method = self.method(method_name)
      parameters = method.parameters

      # remove the options parameter
      parameters.pop

      parts = parameters.collect do |type, name|
        case type
        when :req
          name
        when :opt
          "[#{ name }]"
        when :part
          "#{ name }*"
        end
      end
    end
  end

  def voke(*args)
    args = ARGV if args.empty?

    command, arguments, options = voke_parse(*args)
    voke_call(command, arguments, options)
  end

  def voke_call(command, arguments, options)
    begin
      method = method(command.to_sym)
    rescue
      return help(command, *arguments, options)
    end

    method.call(*arguments, options)
  end

  def voke_parse(*args)
    command = args.shift
    arguments = Array.new
    options = Hash.new

    args.each do |arg|
      if arg =~ /^--(\w+)(?:=(.*))?$/
        key = $1.to_sym

        value = true
        value = voke_parse_value($2) if $2

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

  module ClassMethods
    def voke_config(name)
      @voke_config ||= Hash.new
      @voke_config[name] ||= { :defaults => Hash.new }
    end

    def description(method = :voke_next, string)
      config = voke_config(method)
      config[:description] = string
    end

    def default(*args, &block)
      value = block || args.pop
      argument = args.pop
      method = args.pop || :voke_next

      config = voke_config(method)
      config[:defaults][argument] = value
    end

    def method_added(method)
      config = voke_config(method)

      return if config[:added]
      return if not public_method_defined?(method)

      config[:added] = true

      if next_config = @voke_config.delete(:voke_next)
        config[:description] ||= next_config[:description]
        config[:defaults] = next_config[:defaults].merge(config[:defaults])
      end

      orig_method = instance_method(method)

      define_method(method) do |*args, &block|
        if args.last.is_a?(Hash)
          options = args.pop

          config = self.class.voke_config(method)
          config[:defaults].each do |key, value|
            unless options[key]
              value = value.call(options) if value.is_a?(Proc) or value.is_a?(Method)
              options[key] = value
            end
          end

          args.push(options)
        end

        orig_method.bind(self).call(*args, &block)
      end
    end
  end
end
