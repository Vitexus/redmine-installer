RSpec.shared_context 'run installer' do

  around(:each) do |example|
    @process = InstallerProcess.new(example.metadata[:command], *((example.metadata[:args] || []) << "--enable_user_root"))
    @process.run do
      Dir.mktmpdir('redmine_root') do |dir|
        @redmine_root = dir
        example.run
      end
    end
  end

end
