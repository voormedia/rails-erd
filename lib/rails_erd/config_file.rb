module RailsERD
  class ConfigFile
    USER_WIDE_CONFIG_FILE = File.expand_path(".erdconfig", ENV["HOME"])

    attr_reader :options

    def self.load
      new.load
    end

    def initialize
      @options = {}
    end

    def load
      if File.exists?(USER_WIDE_CONFIG_FILE)  
        @options = YAML.load_file(USER_WIDE_CONFIG_FILE)
      end
      @options
    end
  end
end
