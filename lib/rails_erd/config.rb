require "yaml"

module RailsERD
  class Config
    USER_WIDE_CONFIG_FILE = File.expand_path(".erdconfig", ENV["HOME"])
    CURRENT_CONFIG_FILE   = File.expand_path(".erdconfig", Dir.pwd)

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

    def self.font_names_based_on_os
      if use_os_x_fonts?
        { normal: "ArialMT",
          bold:   "Arial BoldMT",
          italic: "Arial ItalicMT" }
      else
        { normal: "Arial",
          bold:   "Arial Bold",
          italic: "Arial Italic" }
      end
    end

    private

    def load_file(path)
      if File.exist?(path)
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
      when :filetype, :notation
        value.to_sym

      # [<string>]
      when :only, :exclude
        Array(value).join(",").split(",").map { |v| v.strip }

      # true | false
      when :disconnected, :indirect, :inheritance, :markup, :polymorphism,
           :warn, :cluster
        !!value

      # nil | <string>
      when :filename, :orientation
        value.nil? ? nil : value.to_s

      # true | false | <string>
      when :title
        value.is_a?(String) ? value : !!value

      else
        value
      end
    end

    def self.use_os_x_fonts?
      host = RbConfig::CONFIG['host_os']
      return true if host == "darwin"

      if host.include? "darwin"
        darwin_version_array = host.split("darwin").last.split(".").map(&:to_i)

        return true if darwin_version_array[0] >= 13
        return true if darwin_version_array[0] == 12 && darwin_version_array[1] >= 5
      end

      false
    end
  end
end
