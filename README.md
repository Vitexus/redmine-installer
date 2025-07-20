# Redmine installer

> [!WARNING]
> :exclamation: THIS TOOL IS NO LONGER MAINTAINED.
> Easy Software Ltd. has stopped maintaining this tool. We are switching to dockerized installation and upgrade process. Please use our docker images for installation.
>
> Feel free to contact our support if you have any questions.

Easy way hot to install/upgrade Redmine, Easy Redmine or Easy Project.

Please do not run installer on background. It may happen that process will be paused by some event. For example database may require enter password during backuping database.

> ⚠️ Current version support only **ruby 3.1.2**, **Percona 8** as DB server and **redmine 5.0.3+**

Version **v3.x** is designed primarily for work with Easy Redmine / Easy Project **v12.x**.

## Installation

Install tool into your server environment by:
```bash
gem install redmine-installer
```

> ⚠️ Version `v3.0.0` and higher require ruby 3.1.2 and its designed for Easy Redmine / Easy Project v12 and Redmine 5.0.3+ respectively.
## Examples

To display global documentation for installer.

```bash
redmine help
```

You can also check more detailed documentation for each command.

```bash
redmine help [COMMAND]
```

### Environment checker
Check your server environment if it meets our requirements for best Easy Redmine experience.
```bash
redmine env_check
```

### Installing

Create new project on empty directory. All argument are optional. Directory should be empty because installer delete all content for ensuring correct installation. If directory does not exist, current user must have privileges to create it.

```bash
redmine help install
redmine install [PACKAGE PATH or URL] [REDMINE_ROOT] [options]
```

```
--bundle-options OPTIONS   Options for bundle install
--silent                   Less verbose installation
```

Examples:

Install Redmine. Installer will ask for every required parameters.
- `redmine install`

Install Redmine from internet
- `redmine install https://server.tld/REDMINE_PACKAGE.zip /srv/redmine`

Install Redmine from redmine.zip package into /srv/redmine folder.
- `redmine install redmine.zip /srv/redmine`

Install Redmine without rmgaick dependencies.
- `redmine install redmine.zip /srv/redmine --bundle-options "--without rmagick"`

### Upgrading

Upgrade existing project with new package. Full and correct upgrading is ensured by these steps:
1. project is build on temporary directory
2. previous root is deleted
3. projects is moved to target location

Since current root is deleted you should use option `--keep` if you want preserved some files.


```
redmine help upgrade
redmine upgrade [PACKAGE PATH or URL] [REDMINE_ROOT] [options]
```

```
--bundle-options OPTIONS   Options for bundle install
--silent                   Less verbose upgrading
--profile PROFILE_ID       Using saved profile
--keep PATH(s)             Keep selected files or directories
```

Examples:

Upgrade Redmine located on /srv/redmine with package redmine2.zip
- `redmine upgrade redmine2.zip /srv/redmine`

Upgrade Redmine from internet
- `redmine upgrade https://server.tld/REDMINE_PACKAGE.zip /srv/redmine`

Upgrade Redmine and keep directory.
- `redmine upgrade redmine2.zip /srv/redmine --keep directory_i_want_keep`

Once you've saved profile you can use previouse "answer" again.
- `redmine upgrade redmine2.zip /srv/redmine --profile 1`

### Backuping

Backup existing project. You can backup full redmine with database or just database.

```
redmine help backup
redmine backup [REDMINE_ROOT]
```

Examples:

Backup project located in /srv/redmine
- `redmine upgrade /srv/redmine`

### Restoring database

Restore database dump to redmine.

```
redmine help restore-db
redmine restore-db DATABASE_DUMP [REDMINE_ROOT] [options]
```

Examples:

Restore database db.dump for redmine in /srv/redmine
- `redmine restore-db db.dump /srv/redmine`

## Testing

Just run:
```bash
docker compose up --build --exit-code-from redmine_installer
```
This will build docker image from current code and run tests against _percona8_.

note: Require Docker of course.
