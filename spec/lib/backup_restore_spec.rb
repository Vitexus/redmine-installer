require 'spec_helper'

DATABASE_DUMP = File.join(Dir.tmpdir, 'redmine_installer_database_backup.sql')

RSpec.describe 'RedmineInstaller backup / restore', order: :defined do

  let(:project_count) { 5 }

  it 'create backup', :install_first, command: 'backup' do
    # First ensure `project_count` project
    Dir.chdir(@redmine_root) do
      out = `bundle exec rails runner "
        Project.delete_all

        #{project_count}.times do |i|
          p = Project.new
          p.name = 'Test ' + i.to_s
          p.identifier = 'test_' + i.to_s
          p.save(validate: false)
        end

        puts Project.count
      "`
      expect($?.success?).to be_truthy
      expect(out.to_i).to eq(project_count)
    end

    # Backup database
    expected_output('Path to redmine root:')
    write(@redmine_root)
    expected_output('Data backup')
    go_down
    expected_output('‣ Only database')
    select_choice
    expected_output('Where to save backup:')
    write(@backup_dir)
    expected_output('Database backuping')
    expected_output('Database backed up')

    # Ensure 0 project (database is shared with all tests)
    Dir.chdir(@redmine_root) do
      out = `bundle exec rails runner "
        Project.delete_all
        puts Project.count
      "`
      expect($?.success?).to be_truthy
      expect(out.to_i).to eq(0)
    end

    # Save backup (after test end - all backup will be deleted)
    dump = Dir.glob(File.join(@backup_dir, '*', '*')).last
    expect(dump).to end_with("#{ENV.fetch('MYSQL_DATABASE', 'test')}.sql")

    FileUtils.rm_f(DATABASE_DUMP)
    FileUtils.cp(dump, DATABASE_DUMP)
  end

  it 'restore', command: 'install', args: [package_v503, '--database-dump', DATABASE_DUMP] do
    expected_output('Path to redmine root:')
    write(@redmine_root)

    expected_successful_configuration

    expected_output('Database dump will be loaded.')
    expected_output('‣ Skip dump loading')

    go_down
    expected_output('‣ I am aware of this.')
    select_choice

    expected_output_in('Redmine was installed', 240)

    Dir.chdir(@redmine_root) do
      out = `bundle exec rails runner "puts Project.count"`
      expect(out.to_i).to eq(project_count)
    end
  end

end
