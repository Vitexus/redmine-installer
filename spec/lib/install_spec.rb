require 'spec_helper'

RSpec.describe RedmineInstaller::Install, command: 'install' do

  it 'unreadable file', args: [] do
    FileUtils.chmod(0000, @redmine_root)

    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_output('Application root contains unreadable files')

    FileUtils.chmod(0600, @redmine_root)
  end

  it 'unwritable directory', args: [] do
    directory = File.join(@redmine_root, 'directory')
    subdirectory = File.join(directory, 'subdirectory')

    FileUtils.mkdir_p(subdirectory)
    FileUtils.chmod(0444, directory)

    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_output('Application root contains unreadable files')

    FileUtils.chmod(0700, directory)
  end

  it 'non-existinig package', args: [] do
    this_file = File.expand_path(File.join(File.dirname(__FILE__)))

    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_output('Path to package:')
    write(this_file)

    expected_output("File #{this_file} must have format: .zip, .gz, .tgz")
  end

  it 'non-existinig zip package', args: [] do
    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_output('Path to package:')
    write('aaa.zip')

    expected_output("File doesn't exist")
  end

  it 'install without arguments', args: [] do
    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_output('Path to package:')
    write(package_v345)

    expected_output('Extracting redmine package')

    expected_successful_configuration(email: true)
    expected_successful_installation

    expected_redmine_version('3.4.5')
    expected_email_configuration
  end

  it 'download redmine', args: ['v3.4.5'] do
    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_output_in('Downloading http://www.redmine.org/releases/redmine-3.4.5.zip', 30)
    expected_output('Extracting redmine package')

    expected_successful_configuration
    expected_successful_installation

    expected_redmine_version('3.4.5')
  end

  it 'installing something else', args: [package_someting_else] do
    write(@redmine_root)

    expected_output('is not valid')
  end

  it 'bad database settings', args: [package_v345] do
    write(@redmine_root)

    expected_output('Creating database configuration')
    go_down
    expected_output('‣ PostgreSQL')
    write('')

    write('test')
    write('')
    write('testtesttest')
    sleep 0.5 # wait for buffer
    write(db_password)
    write('')
    write('')

    expected_output('Creating email configuration')
    write('')

    expected_output('Redmine installing')
    expected_output_in('--> Database migrating', 60)
    expected_output('Migration end with error')
    expected_output('‣ Try again')

    go_down
    go_down
    expected_output('‣ Change database configuration')
    write('')

    go_down
    expected_output('‣ PostgreSQL')
    write('')

    write('test')
    write('')
    write(db_username)
    sleep 0.5 # wait for buffer
    write(db_password)
    write('')
    write('')

    expected_output('--> Database migrating')
    expected_output_in('Redmine was installed', 60)

    expected_redmine_version('3.4.5')
  end

  it 'high installer version', args: [package_high_installer_version] do
    write(@redmine_root)
    expected_output('You are using an old version of installer')
  end

  it 'download redmine', args: [package_default_db] do
    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_successful_configuration
    expected_successful_installation(
      after_create: proc {
        expected_output('Would you like to load default data')

        write('y')
        expected_output('Database cleaning')
        expected_output('Database restoring')
      }
    )

    expected_redmine_version('3.4.5')

    Dir.chdir(@redmine_root) do
      out = `rails runner "puts Issue.count"`.strip
      expect($?.success?).to be_truthy
      expect(out).to eq('3')
    end
  end

end
