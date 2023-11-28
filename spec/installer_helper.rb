module InstallerHelper

  def db_username
    ENV['MYSQL_USER'].to_s
  end

  def db_password
    ENV['MYSQL_PASSWORD'].to_s
  end

  def expected_output(text)
    expect(@process).to have_output(text)
  end

  def expected_output_in(text, max_wait)
    expect(@process).to have_output_in(text, max_wait)
  end

  def write(text)
    @process.write(text + "\n")
  end

  # Be carefull - this could have later unpredictable consequences on stdin
  def select_choice
    # @process.write(' ')
    @process.write("\r")
    # @process.write("\r\n")
  end

  def go_up
    @process.write("\e[A")
  end

  def go_down
    # write(TTY::Reader::Keys.keys[:down])
    # write("\e[B")
    @process.write("\e[B")
  end

  def email_username
    'username'
  end

  def email_password
    'password'
  end

  def email_address
    'address'
  end

  def email_port
    '123'
  end

  def email_domain
    'domain'
  end

  def email_authentication
    'plain'
  end

  def email_openssl_verify_mode
    'none'
  end

  def email_enable_tls
    false
  end

  def email_enable_starttls
    true
  end

  def expected_successful_configuration(email: false)
    expected_output('Creating database configuration')
    expected_output('What database do you want use?')
    expected_output('‣ MySQL')

    # go_down
    # expected_output('‣ PostgreSQL')
    select_choice

    expected_output('Database:')
    write(ENV.fetch('MYSQL_DATABASE', 'test'))

    expected_output('Host: (localhost)')
    write(ENV['DB_HOST'].to_s)

    expected_output('Username:')
    write(db_username)

    expected_output('Password:')
    write(db_password)

    expected_output('Encoding: (utf8mb4)')
    write('')

    expected_output('Port: (3306)')
    write('')

    expected_output('Creating email configuration')
    expected_output('Which service to use for email sending?')

    if email
      go_up
      go_up
      go_up
      expected_output('‣ Custom configuration (SMTP)')
      select_choice

      expected_output('Username:')
      write(email_username)

      expected_output('Password:')
      write(email_password)

      expected_output('Address:')
      write(email_address)

      expected_output('Port:')
      write(email_port)

      expected_output('Domain:')
      write(email_domain)

      expected_output('Authentication:')
      write(email_authentication)

      expected_output('Openssl verify mode:')
      write(email_openssl_verify_mode)

      expected_output('Enable tls?: (y/N)')
      write(email_enable_tls ? 'y' : 'n')

      expected_output('Enable starttls?: (Y/n)')
      write(email_enable_starttls ? 'y' : 'n')
    else
      expected_output('‣ Nothing')
      select_choice
    end
  end

  def expected_successful_installation_or_upgrade(db_creating: false, after_create: nil)
    expected_output_in('--> Bundle install', 900)
    expected_output_in('--> Database creating', 900) if db_creating
    after_create&.call
    expected_output_in('--> Database migrating', 900)
    expected_output_in('--> Plugins migration', 900)
    expected_output_in('--> Generating secret token', 900)

    expected_output_in('Cleaning root ... OK', 900)
    expected_output_in('Moving redmine to target directory ... OK', 900)
    expected_output_in('Cleanning up ... OK', 900)
    expected_output_in('Moving installer log ... OK', 900)
  end

  def expected_successful_installation(**options)
    expected_output('Redmine installing')
    expected_successful_installation_or_upgrade(db_creating: true, **options)
    expected_output('Redmine was installed')
  end

  def expected_successful_upgrade
    expected_output('Redmine upgrading')
    expected_successful_installation_or_upgrade
    expected_output('Redmine was upgraded')

    expected_output('Do you want save steps for further use?')
    write('n')
  end

  def expected_redmine_version(version)
    Dir.chdir(@redmine_root) do
      out = `bundle exec rails r -e production 'puts Redmine::VERSION.to_s'`
      expect($?.success?).to be_truthy
      expect(out).to include(version)
    end
  end

  def expected_email_configuration
    Dir.chdir(@redmine_root) do
      configuration = YAML.load_file('config/configuration.yml', aliases: true)['default']['email_delivery']
      smtp_settings = configuration['smtp_settings']

      expect(configuration['delivery_method']).to eq(:smtp)
      expect(smtp_settings['address']).to eq(email_address)
      expect(smtp_settings['port']).to eq(email_port.to_i)
      expect(smtp_settings['authentication']).to eq(email_authentication.to_sym)
      expect(smtp_settings['domain']).to eq(email_domain)
      expect(smtp_settings['user_name']).to eq(email_username)
      expect(smtp_settings['password']).to eq(email_password)
      expect(smtp_settings['tls']).to eq(email_enable_tls)
      expect(smtp_settings['enable_starttls_auto']).to eq(email_enable_starttls)
      expect(smtp_settings['openssl_verify_mode']).to eq(email_openssl_verify_mode)
    end
  end

  def wait_for_stdin_buffer
    sleep 0.5
  end

end
