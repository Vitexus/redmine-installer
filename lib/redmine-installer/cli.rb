require 'commander'

module Commander
  module UI
    # Disable paging for 'classic' help
    def self.enable_paging
    end
  end
end

module RedmineInstaller
  class CLI
    include Commander::Methods

    def run
      program :name, 'Ruby installer'
      program :version, RedmineInstaller::VERSION
      program :description, 'Easy way how install/upgrade redmine or plugin.'

      global_option('-d', '--debug', 'Logging message to stdout') { $DEBUG = true }
      global_option('-s', '--silent', 'Be less version in output') { $SILENT_MODE = true }
      global_option('-e', '--env', 'For backward compatibility. Production is now always use.')
      global_option('--run-easycheck', 'Run easycheck.sh from https://github.com/easyredmine/easy_server_requirements_check') do
        RedmineInstaller::Easycheck.run
      end

      default_command :help

      # --- Environment checker -----------------------------------------------
      # This command is very specify to Easy Redmine
      command :env_check do |c|
        c.syntax = 'env_check'
        c.description = <<~DESC
          Check current environment if it meet requirements for Easy Redmine / Easy Project.

          See: https://www.easyredmine.com/documentation-of-easy-redmine/article/hardware-and-software-requirements-for-the-server-solution
        DESC
        c.action do |_args|
          task = RedmineInstaller::Task.new
          RedmineInstaller::Environment.new(task).check
          puts task.pastel.green "OK"
        rescue StandardError => e
          puts task.pastel.red e.message

          puts "\n\nCheck: https://www.easyredmine.com/documentation-of-easy-redmine/article/hardware-and-software-requirements-for-the-server-solution#Software%20requirements for more info."
        end
      end

      alias_command :check, :env_check

      # --- Install -----------------------------------------------------------
      command :install do |c|
        c.syntax = 'install [PACKAGE] [REDMINE_ROOT] [options]'
        c.description = 'Install redmine or easyredmine'

        c.example 'Install from archive',
                  'redmine install ~/REDMINE_PACKAGE.zip'
        c.example 'Install package from internet',
                  'redmine install https://server.tld/REDMINE_PACKAGE.zip'
        c.example 'Install specific version from internet',
                  'redmine install v3.1.0'
        c.example 'Install package to new dir',
                  'redmine install ~/REDMINE_PACKAGE.zip redmine_root'

        c.option '--enable-user-root', 'Skip root as root validation'
        c.option '--bundle-options OPTIONS', String, 'Add options to bundle command'
        c.option '--database-dump DUMP', String, 'Load dump before migration (experimental function)'

        c.action do |args, options|
          options.default(enable_user_root: false)

          RedmineInstaller::Install.new(args[0], args[1], **options.__hash__).run
        end
      end
      alias_command :i, :install

      # --- Upgrade -----------------------------------------------------------
      command :upgrade do |c|
        c.syntax = 'upgrade [PACKAGE] [REDMINE_ROOT] [options]'
        c.description = 'Upgrade redmine or easyredmine'

        c.example 'Upgrade with new package',
                  'redmine upgrade ~/REDMINE_PACKAGE.zip'
        c.example 'Upgrade with package from internet',
                  'redmine upgrade ~/REDMINE_PACKAGE.zip redmine_root'
        c.example 'Upgrade',
                  'redmine upgrade https://server.tld/REDMINE_PACKAGE.zip redmine_root'
        c.example 'Upgrade and keep directory',
                  'redmine upgrade --keep git_repositories'

        c.option '--enable-user-root', 'Skip root as root validation'
        c.option '--bundle-options OPTIONS', String, 'Add options to bundle command'
        c.option '-p', '--profile PROFILE_ID', Integer, 'Use saved profile'
        c.option '--keep PATH(s)', Array, 'Keep paths, use multiple options or separate values by comma (paths must be relative)', &method(:parse_keep_options)
        c.option '--copy-files-with-symlink', 'Files will be referenced by symlinks instead of copying files. Only for advance users.'

        c.action do |args, options|
          options.default(enable_user_root: false, copy_files_with_symlink: false)

          RedmineInstaller::Upgrade.new(args[0], args[1], **options.__hash__).run
        end
      end
      alias_command :u, :upgrade

      # --- Verify log --------------------------------------------------------
      command :'verify-log' do |c|
        c.syntax = 'verify-log LOGFILE'
        c.description = 'Verify redmine installer log file'

        c.example 'Verify log',
                  'redmine verify-log LOGFILE'

        c.action do |args, _|
          RedmineInstaller::Logger.verify(args[0])
        end
      end

      # --- Backup ------------------------------------------------------------
      command :backup do |c|
        c.syntax = 'backup [REDMINE_ROOT]'
        c.description = 'Backup redmine'

        c.example 'Backup',
                  'redmine backup /srv/redmine'

        c.option '--enable-user-root', 'Skip root as root validation' # just for consistency

        c.action do |args, options|
          options.default(enable_user_root: false)

          RedmineInstaller::Backup.new(args[0]).run
        end
      end
      alias_command :b, :backup

      # --- Restore db --------------------------------------------------------
      command :'restore-db' do |c|
        c.syntax = 'restore-db DATABASE_DUMP [REDMINE_ROOT] [options]'
        c.description = 'Restore database and delete old data'

        c.example 'Restore DB',
                  'redmine restore-db /srv/redmine.sql'

        c.option '--enable-user-root', 'Skip root as root validation'

        c.action do |args, options|
          options.default(enable_user_root: false)

          RedmineInstaller::RestoreDB.new(args[0], args[1]).run
        end
      end

      run!
    end

    # For multiple user --keep option
    def parse_keep_options(values)
      proxy_options = Commander::Runner.instance.active_command.proxy_options

      saved = proxy_options.find { |switch, _| switch == :keep }
      if saved
        saved[1].concat(values)
      else
        proxy_options << [:keep, values]
      end
    end

  end
end
