module RedmineInstaller
  class PackageConfig
    include Utils

    CONFIG_DIR = '_package'

    def initialize(redmine)
      @redmine = redmine
    end

    def min_version
      options['min_version']
    end

    def dump_type
      options['dump_type']
    end

    def dump_file
      File.join(@redmine.root, CONFIG_DIR, options['dump_file'].to_s)
    end

    def dump_attached?
      File.exist?(dump_file)
    end

    def sql_dump_file
      if defined?(@sql_dump_file)
        return @sql_dump_file
      end

      if !dump_attached?
        @sql_dump_file = nil
      end

      if dump_file.end_with?('.gz')
        @sql_dump_file = File.join(@redmine.root, CONFIG_DIR, 'dump.sql')

        Zlib::GzipReader.open(dump_file) { |gz|
          File.binwrite(@sql_dump_file, gz.read)
        }
      else
        @sql_dump_file = dump_file
      end

      @sql_dump_file
    end

    def dump_compatible?(database)
      database.adapter_name.start_with?(dump_type.to_s)
    end

    def options
      @options ||= _options
    end

    def check_version
      if min_version && Gem::Version.new(min_version) > Gem::Version.new(RedmineInstaller::VERSION)
        error "You are using an old version of installer. Min version is #{min_version} (current: #{RedmineInstaller::VERSION}). Please run `gem install redmine-installer`."
      end
    end

    private

      def _options
        config_file = File.join(@redmine.root, CONFIG_DIR, 'redmine-installer.yaml')

        if File.exist?(config_file)
          YAML.load_file(config_file, aliases: true)
        else
          {}
        end
      end

  end
end
