module RedmineInstaller
  class Database
    extend Utils

    def self.create_config(redmine)
      # Maybe: enum_select
      klass = prompt.select('What database do you want use?') do |menu|
        menu.choice 'MySQL', MySQL
        menu.choice 'PostgreSQL', PostgreSQL
      end

      # Get parameters and create configuration
      database = klass.new(redmine)
      database.get_parameters
      database.make_config
      database
    end

    def self.init(redmine)
      unless File.exist?(redmine.database_yml_path)
        error "Database configuration files does not exist on #{redmine.root}."
      end

      definitions = YAML.load_file(redmine.database_yml_path, aliases: true)
      definition = definitions['production']

      unless definition.is_a?(Hash)
        error 'Unknow database definition'
      end

      case definition['adapter']
      when 'mysql', 'mysql2'
        klass = MySQL
      when 'pg', 'postgresql'
        klass = PostgreSQL
      else
        error "Unknow database adapter #{definition['adapter']}."
      end

      database = klass.new(redmine)
      database.set_paramaters(definition)
      database
    end

    class Base
      include RedmineInstaller::Utils

      attr_reader :backup

      def initialize(redmine)
        @redmine = redmine
      end

      def backuped?
        @backup && File.exist?(@backup)
      end

      def get_parameters
        @database = prompt.ask('Database:', required: true)
        @host = prompt.ask('Host:', default: 'localhost', required: true)
        @username = prompt.ask('Username:', default: '')
        @password = prompt.mask('Password:', default: '')
        @encoding = prompt.ask('Encoding:', default: 'utf8mb4', required: true)
        @port = prompt.ask('Port:', default: default_port, convert: lambda(&:to_i), required: true)
      end

      def set_paramaters(definition)
        @database = definition['database']
        @username = definition['username']
        @password = definition['password']
        @encoding = definition['encoding']
        @host = definition['host']
        @port = definition['port']
      end

      def make_config
        File.open(@redmine.database_yml_path, 'w') do |f|
          f.puts(YAML.dump(build))
        end
      end

      def make_backup(dir)
        puts 'Database backuping'
        @backup = File.join(dir, "#{@database}.sql")
        Kernel.system backup_command(@backup)
      end

      # Recreate database should be done in 2 commands because of
      # postgre's '--command' options which can do only 1 operations.
      # Otherwise result is unpredictable.
      def do_restore(file)
        puts 'Database cleaning'
        Kernel.system drop_database_command
        Kernel.system create_database_command

        puts 'Database restoring'
        Kernel.system restore_command(file)
      end

      def build
        data = {}
        data['adapter'] = adapter_name
        data['database'] = @database
        data['username'] = @username if @username.present?
        data['password'] = @password if @password.present?
        data['encoding'] = @encoding
        data['host'] = @host
        data['port'] = @port

        {
          'production' => data,
          'development' => data
        }
      end

      def to_s
        "<#{class_name} #{@username}@#{@host}:#{@port} (#{@encoding})>"
      end

    end

    class MySQL < Base

      def default_port
        3306
      end

      def adapter_name
        'mysql2'
      end

      def command_args
        args = []
        args << "--host=#{@host}"         unless @host.to_s.empty?
        args << "--port=#{@port}"         unless @port.to_s.empty?
        args << "--user=#{@username}"     unless @username.to_s.empty?
        args << "--password=#{@password}" unless @password.to_s.empty?
        args.join(' ')
      end

      def create_database_command
        "mysql #{command_args} --execute=\"create database #{@database}\""
      end

      def drop_database_command
        "mysql #{command_args} --execute=\"drop database #{@database}\""
      end

      def backup_command(file)
        "mysqldump --add-drop-database --compact --result-file=#{file} #{command_args} #{@database}"
      end

      def restore_command(file)
        "mysql #{command_args} #{@database} < #{file}"
      end

    end

    class PostgreSQL < Base

      def default_port
        5432
      end

      def adapter_name
        'postgresql'
      end

      def command_args
        args = []
        args << "--host=#{@host}"         unless @host.to_s.empty?
        args << "--port=#{@port}"         unless @port.to_s.empty?
        args << "--username=#{@username}" unless @username.to_s.empty?
        args.join(' ')
      end

      def cli_password
        if @password.present?
          "PGPASSWORD=\"#{@password}\""
        else
          ''
        end
      end

      def create_database_command
        "#{cli_password} psql #{command_args} --command=\"create database #{@database};\""
      end

      def drop_database_command
        "#{cli_password} psql #{command_args} --command=\"drop database #{@database};\""
      end

      def backup_command(file)
        "#{cli_password} pg_dump --clean #{command_args} --format=custom --file=#{file} #{@database}"
      end

      def restore_command(file)
        "#{cli_password} pg_restore --clean #{command_args} --dbname=#{@database} #{file} 2>/dev/null"
      end

    end

  end
end
