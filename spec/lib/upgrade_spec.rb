require 'spec_helper'

RSpec.describe RedmineInstaller::Upgrade, :install_first, command: 'upgrade' do

  it 'bad redmine root', args: [] do
    FileUtils.remove_entry(File.join(@redmine_root, 'app'))
    write(@redmine_root)

    expected_output("Redmine #{@redmine_root} is not valid.")
  end

  it 'upgrading with full backup' do
    # This should not be a problem because file still could be deleted
    unwritable_file = File.join(@redmine_root, 'unwritable_file')
    FileUtils.touch(unwritable_file)
    FileUtils.chmod(0400, unwritable_file)

    test_test_dir = File.join(@redmine_root, 'test_test')
    test_test_file = File.join(test_test_dir, 'test.txt')
    FileUtils.mkdir_p(test_test_dir)
    FileUtils.touch(test_test_file)

    expect(File.exist?(test_test_file)).to be_truthy

    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_output('Path to package:')
    write(package_v503)

    expected_output('Extracting redmine package')
    expected_output('Data backup')

    expected_output('‣ Full (redmine root and database)')
    select_choice

    expected_output('Where to save backup:')
    write(@backup_dir)

    expected_output('Files backuping')
    expected_output('Files backed up')
    expected_output('Database backuping')
    expected_output('Database backed up')

    expected_successful_upgrade

    expected_redmine_version('5.0.3')

    expect(File.exist?(test_test_file)).to be_falsey

    last_backup = Dir.glob(File.join(@backup_dir, '*')).sort.last
    backuped = Dir.glob(File.join(last_backup, '*'))

    expect(backuped.map { |f| File.zero?(f) }).to all(be_falsey)
  end

  it 'upgrade with no backup and files keeping', args: ['--keep', 'test_test'] do
    test_test_dir = File.join(@redmine_root, 'test_test')
    test_test_file = File.join(test_test_dir, 'test.txt')
    FileUtils.mkdir_p(test_test_dir)
    FileUtils.touch(test_test_file)

    expect(File.exist?(test_test_file)).to be_truthy

    wait_for_stdin_buffer
    write(@redmine_root)

    wait_for_stdin_buffer
    write(package_v503)

    wait_for_stdin_buffer

    go_down
    go_down
    expected_output('‣ Nothing')
    select_choice

    expected_output('Are you sure you dont want backup?')
    write('y')

    expected_successful_upgrade

    expected_redmine_version('5.0.3')

    expect(File.exist?(test_test_file)).to be_truthy
  end

  it 'copy files with symlink ', args: ['--copy-files-with-symlink'] do
    files_dir = File.join(@redmine_root, 'files')
    files = (0..10).map { |i| File.join(files_dir, "file_#{i}.txt") }
    FileUtils.touch(files)

    wait_for_stdin_buffer
    write(@redmine_root)

    wait_for_stdin_buffer
    write(package_v503)

    wait_for_stdin_buffer

    go_down
    go_down
    expected_output('‣ Nothing')
    select_choice

    expected_output('Are you sure you dont want backup?')
    write('y')

    expected_successful_upgrade

    expected_redmine_version('5.0.3')

    # Not bullet-prof but at least check if files are still there
    expect(Dir.glob(File.join(files_dir, '*.txt')).sort).to eq(files.sort)
  end

  it 'upgrade rys and modify bundle/index' do
    skip 'old version not supporting Ruby >3'
    wait_for_stdin_buffer
    write(@redmine_root)

    wait_for_stdin_buffer
    write(package_v345_rys)

    wait_for_stdin_buffer

    go_down
    go_down
    expected_output('‣ Nothing')
    select_choice

    expected_output('Are you sure you dont want backup?')
    write('y')

    expected_successful_upgrade

    expected_redmine_version('3.4.5')

    index = YAML.load_file(File.join(@redmine_root, '.bundle/plugin/index'), aliases: true)

    load_paths = index['load_paths']['rys-bundler']
    expect(load_paths.size).to eq(1)

    load_path = load_paths.first
    expect(load_path).to start_with(@redmine_root)

    plugin_paths = index['plugin_paths']['rys-bundler']
    expect(plugin_paths).to start_with(@redmine_root)
  end

  it 'upgrading something else' do
    wait_for_stdin_buffer
    write(@redmine_root)

    wait_for_stdin_buffer
    write(package_someting_else)

    wait_for_stdin_buffer
    expected_output('is not valid')
  end

  context 'missing plugins' do

    def upgrade_it(answer, result)
      # Create some plugins
      plugin_name = 'new_plugin'
      plugin_dir = File.join(@redmine_root, 'plugins', plugin_name)
      FileUtils.mkdir_p(plugin_dir)
      FileUtils.touch(File.join(plugin_dir, 'init.rb'))

      wait_for_stdin_buffer
      write(@redmine_root)

      wait_for_stdin_buffer
      write(package_v503)

      go_down
      go_down
      expected_output('‣ Nothing')
      select_choice
      write('y')

      expected_output("Your application contains plugins that are not present in the package (#{plugin_name}). Would you like to copy them?")

      write(answer)
      expected_successful_upgrade
      expected_redmine_version('5.0.3')

      expect(Dir.exist?(plugin_dir)).to be(result)
    end

    it 'yes' do
      upgrade_it('y', true)
    end

    it 'no' do
      upgrade_it('n', false)
    end

  end

end
