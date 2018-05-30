module RedmineInstaller
  class Task
    include Utils

    attr_reader :options

    def initialize(**options)
      @options = OpenStruct.new(options)

      logger.info "#{class_name} initialized with #{options}"
      logger.info "RUBY_VERSION: #{RUBY_VERSION}"
      logger.info "USER: #{env_user}"
    end

    def run
      up
    rescue => e
      @error = e

      logger.error(e.message)
      logger.error(*e.backtrace)

      puts pastel.red(e.message)

      down
    end

    def up
      raise NotImplementedError
    end

    def down
    end

  end
end
