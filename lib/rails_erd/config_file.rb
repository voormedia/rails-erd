module RailsERD
  class ConfigFile
    USER_WIDE_CONFIG_FILE = File.expand_path(".erdconfig", ENV["HOME"])
    CURRENT_CONFIG_FILE = File.expand_path(".erdconfig", Dir.pwd)

    attr_reader :options

    def self.load
      new.load
    end

    def initialize
      @options = {}
    end

    def load
      load_file(USER_WIDE_CONFIG_FILE)
      load_file(CURRENT_CONFIG_FILE)
      @options
    end

    private

    def load_file(path)
      if File.exists?(path)  
        YAML.load_file(path).each do |key, value|
          key = key.to_sym
          @options[key] = normalize_value(key, value)
        end
      end
    end

    def normalize_value(key, value)
      case key
      # <symbol>[,<symbol>,...] | false
      when :attributes
        if value == false
          return value
        else
          # Comma separated string and strings in array are OK.
          Array(value).join(",").split(",").map { |v| v.strip.to_sym }
        end
      
      # <symbol>
      when :filetype, :notation, :orientation
        value.to_sym

      # true | false
      when :disconnected, :indirect, :inheritance, :markup, :polymorphism, :warn
        !!value
      
      # nil | <string>
      when :filename, :only, :exclude
        value.nil? ? nil : value.to_s

      # true | false | <string>
      when :title
        value.is_a?(String) ? value : !!value

      else
        value
      end
    end
  end
end
