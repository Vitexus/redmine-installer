ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../gems.rb', __dir__)

require 'bundler'
Bundler.require(:default, :development)

lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(lib) if !$LOAD_PATH.include?(lib)

require 'redmine-installer'

require 'custom_matchers'
require 'shared_contexts'

require 'installer_process'
require 'installer_helper'
require 'packages_helper'

RSpec.configure do |config|
  config.default_formatter = 'doc'
  config.color = true
  config.tty = true

  config.disable_monkey_patching!

  config.include_context 'run installer', :command

  config.include PackagesHelper
  config.extend PackagesHelper
  config.include InstallerHelper

  config.before(:all, :install_first) do
    @redmine_root = @origin_redmine = Dir.mktmpdir('redmine_root')
    @backup_dir = Dir.mktmpdir('backup_dir')
    @process = InstallerProcess.new('install', package_v503, @origin_redmine, "--enable_user_root")
    @process.run do
      expected_successful_configuration
      expected_successful_installation

      expected_redmine_version('5.0.3')
    end
  end

  config.after(:all, :install_first) do
    FileUtils.remove_entry(@origin_redmine, true)
    FileUtils.remove_entry(@backup_dir, true)
  end

  config.before(:each, :install_first) do
    FileUtils.cp_r(File.join(@origin_redmine, '.'), @redmine_root)
  end
end
