# Changelog


## [3.0.3] - 2023-01-16
### Fixed
- rubygems < 3.3.12 still unable to install gem on some machines, try another way to define ruby dependency [#40](https://github.com/easyredmine/redmine-installer/issues/40)
## [3.0.2] - 2023-01-02
### Fixed
- with rubygems < 3.3.12 unable to install gem [#40](https://github.com/easyredmine/redmine-installer/issues/40)
## [3.0.1] - 2022-12-14
### Fixed
- do not show warning if Percona
## [3.0.0] - 2022-12-13
### Added
- docker-compose for testing [#37](https://github.com/easyredmine/redmine-installer/pull/37)
- .github workflow for CI
- `env_check` for test server environment
### Fixed
- ruby 3.x support [#35](https://github.com/easyredmine/redmine-installer/pull/35)
- Psych aliases while parsing `database.yml`
### Changed
- required ruby version = 3.1.2 [#36](https://github.com/easyredmine/redmine-installer/pull/36)
- required redmine version = 5.0.4+ [#36](https://github.com/easyredmine/redmine-installer/pull/36)

## [2.4.0] - 2022-09-07
### Added
- allow the administrator to manually empty the root directory [#33](https://github.com/easyredmine/redmine-installer/pull/33)

## [2.3.0.beta] - 2019-06-10

### Added
- Gems are required via Bundler
- Easycheck for server requirenments
- Validation for the package for upgrading

### Changed
- Gemfile was renamed to gems.rb
- Installer is now asking if user wants to copy missing plugins
- Tests aren't using system redmine-installer

### Deprecated
- Ruby <= 2.3

### Removed

### Fixed

### Security

