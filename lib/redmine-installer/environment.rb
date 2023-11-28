module RedmineInstaller
  class Environment < TaskModule

    def check
      if user_is_root? && !task.options.enable_user_root
        error 'You cannot install redmine under root. Please change user.'
      end

      if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(RedmineInstaller::MIN_SUPPORTED_RUBY)
        error "You are using unsupported ruby. Please install ruby v#{RedmineInstaller::MIN_SUPPORTED_RUBY}."
      end

      if mysql_version =~ /^mysql\s+Ver\s(8\.\d)/
        unless mysql_version.include? "Percona"
          puts pastel.on_red 'WARNING: It seems you are using MySQL 8.x, but ER / EP supported only Percona 8 db.'
        end
      else
        error 'Only Percona 8.x db server is supported!.'
      end

      logger.info 'Environment checked'
    end

    def user_is_root?
      Process.euid == 0
    end

    def mysql_version
      `mysql --version`
    rescue StandardError
      ""
    end

  end
end
