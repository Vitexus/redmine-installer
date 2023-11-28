require 'fileutils'
require 'tempfile'
require 'bundler'
require 'ostruct'
require 'tmpdir'
require 'pastel'
require 'yaml'
require 'zip'

require 'tty-progressbar'
require 'tty-spinner'
require 'tty-prompt'

module RedmineInstaller
  autoload :CLI,           'redmine-installer/cli'
  autoload :Task,          'redmine-installer/task'
  autoload :Install,       'redmine-installer/install'
  autoload :Utils,         'redmine-installer/utils'
  autoload :Logger,        'redmine-installer/logger'
  autoload :TaskModule,    'redmine-installer/task_module'
  autoload :Environment,   'redmine-installer/environment'
  autoload :Redmine,       'redmine-installer/redmine'
  autoload :Package,       'redmine-installer/package'
  autoload :Database,      'redmine-installer/database'
  autoload :Configuration, 'redmine-installer/configuration'
  autoload :Upgrade,       'redmine-installer/upgrade'
  autoload :Command,       'redmine-installer/command'
  autoload :Profile,       'redmine-installer/profile'
  autoload :Backup,        'redmine-installer/backup'
  autoload :RestoreDB,     'redmine-installer/restore_db'
  autoload :PackageConfig, 'redmine-installer/package_config'
  autoload :Easycheck,     'redmine-installer/easycheck'

  # Settings
  MIN_SUPPORTED_RUBY = '3.1.2'

  def self.logger
    @logger ||= RedmineInstaller::Logger.new
  end

  def self.prompt
    @prompt ||= TTY::Prompt.new
  end

  def self.pastel
    @pastel ||= Pastel.new
  end

  def self.print_logo
    puts <<-PRINT
                __      _
    _______ ___/ /_ _  (_)__  ___
   / __/ -_) _  /  ' \\/ / _ \\/ -_)
  /_/  \\__/\\_,_/_/_/_/_/_//_/\\__/


  Powered by EasySoftware

    PRINT
  end
end


# Requirements
require 'redmine-installer/version'
require 'redmine-installer/errors'

# Patches
require 'redmine-installer/patches/ruby'
require 'redmine-installer/patches/tty'

if ENV['REDMINE_INSTALLER_SPEC']
  require 'redmine-installer/spec/spec'
end

Kernel.at_exit do
  RedmineInstaller.logger.finish
end
