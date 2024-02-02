lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'redmine-installer/version'

Gem::Specification.new do |spec|
  spec.name = 'redmine-installer'
  spec.version = RedmineInstaller::VERSION
  spec.authors = ['Ondřej Moravčík', 'Easy Software Ltd.']
  spec.email = ['developers@easysoftware.com']
  spec.summary = %q{Easy way how install/upgrade Redmine, EasyRedmine or EasyProject.}
  spec.description = %q{}
  spec.homepage = 'https://github.com/easyredmine/redmine-installer'
  spec.license = 'MIT'
  spec.metadata = {
    "source_code_uri" => "https://github.com/easyredmine/redmine-installer",
    "changelog_uri" => "https://github.com/easyredmine/redmine-installer/blob/master/CHANGELOG.md",
  }

  files = `git ls-files -z`.split("\x0") - Dir.glob("{spec/**/*,docker-compose.yml,.github/**/*}")
  spec.files = files
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1.2'

  spec.add_runtime_dependency 'bundler', '>= 2.3.7'
  spec.add_runtime_dependency 'commander'
  spec.add_runtime_dependency 'pastel', '~> 0.8.0'
  spec.add_runtime_dependency 'rubyzip'
  spec.add_runtime_dependency 'tty-progressbar', '~> 0.18.2'
  spec.add_runtime_dependency 'tty-prompt', '~> 0.23.1'
  spec.add_runtime_dependency 'tty-spinner', '~> 0.8.0'

  spec.add_development_dependency 'childprocess', '~> 4.1.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.11.0'
end
