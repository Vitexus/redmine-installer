require 'childprocess'

class InstallerProcess

  attr_reader :stdout, :last_get_return

  def initialize(command, *args)
    tempfile_out = File.open('redmine-installer-out', 'w')
    tempfile_err = File.open('redmine-installer-err', 'w')

    tempfile_out.sync = true
    tempfile_err.sync = true

    args = args.flatten.compact

    if ['install', 'upgrade'].include?(command)
      args << '--bundle-options' << '--without rmagick'
    end

    redmine_bin_file = File.expand_path('../bin/redmine', __dir__)

    @process = ChildProcess.build(redmine_bin_file, command, *args)
    # @process = ChildProcess.build('bin/redmine', command, *args)
    # @process = ChildProcess.build('redmine', command, *args)
    @process.io.stdout = tempfile_out
    @process.io.stderr = tempfile_err
    @process.environment['REDMINE_INSTALLER_SPEC'] = '1'
    @process.environment['REDMINE_INSTALLER_LOGFILE'] = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log.log'))
    @process.duplex = true
    @process.detach = true

    # Because of file description is shared with redmine installer
    # so changing posiiotn has effect fot both processes
    @stdout = File.open(tempfile_out.path)

    @last_get_return = ''
    @buffer = ''
    @seek = 0
  end

  def run
    Bundler.with_unbundled_env {
      start
      yield
    }
  ensure
    stop
  end

  def start
    @process.start
  end

  def stop
    @process.stop
  end

  def write(text)
    @process.io.stdin << text

    # @process.io.stdin.puts(text)
    # @process.io.stdin.flush

    # @process.io.stdin.syswrite(text + "\n")
    # @process.io.stdin.flush

    # @process.io.stdin.write_nonblock(text + "\n")
  end

  def get(text, **args)
    @last_get_return = _get(text, **args)
  end

  private

  # max_wait in s
  def _get(text, max_wait: 180)
    wait_to = Time.now + max_wait
    while Time.now < wait_to
      @buffer << @stdout.read
      index = @buffer.rindex(text)

      if index
        break
        # return @buffer.slice!(0, index+text.size)
      else
        sleep 0.5
      end
    end

    @buffer
  end

end
