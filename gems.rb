source 'https://rubygems.org'

# Specify your gem's dependencies in redmine-installer.gemspec
gemspec

# if File.exist?(File.join(__dir__, '.local'))
#   group :development, :test do
#     gem 'pry'
#     gem 'rspec'
#     gem 'childprocess'
#   end
# end
gem "pry", group: [:development, :test]
