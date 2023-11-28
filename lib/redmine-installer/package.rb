require 'rubygems/package'
require 'net/http'
require 'zlib'
require 'uri'

module RedmineInstaller
  class Package < TaskModule

    SUPPORTED_ARCHIVE_FORMATS = ['.zip', '.gz', '.tgz']
    TAR_LONGLINK = '././@LongLink'

    attr_reader :package, :temp_dir

    def initialize(task, package)
      super(task)
      @package = package.to_s
    end

    def ensure_and_valid_package
      if package.empty?
        @package = prompt.ask('Path to package:', required: true)
      end

      if !File.exist?(@package)
        if @package =~ /\Av?(\d\.\d\.\d)\Z/
          @package = download_redmine_version($1)
        elsif valid_url?(@package)
          @package = download_from_url(@package)
        else
          error "File doesn't exist #{@package}"
        end
      end

      @type = File.extname(@package)
      unless SUPPORTED_ARCHIVE_FORMATS.include?(@type)
        error "File #{@package} must have format: #{SUPPORTED_ARCHIVE_FORMATS.join(', ')}"
      end
    end

    def extract
      print_title('Extracting redmine package')

      @temp_dir = Dir.mktmpdir

      case @type
      when '.zip'
        extract_zip
      when '.gz', '.tgz'
        extract_tar_gz
      end

      logger.info("Package was loaded into #{@temp_dir}.")
    end

    # Move files from temp dir to target. First check if folder contains redmine
    # or contains folder which contains redmine.
    #
    # Package can have format:
    # |-- redmine-2
    #     |-- app
    #     `-- config
    # ...
    #
    def redmine_root
      root = @temp_dir

      loop {
        ls = Dir.glob(File.join(root, '*'))

        if ls.size == 1
          root = ls.first
        else
          break
        end
      }

      root
    end

    def clean_up
      @temp_dir && FileUtils.remove_entry_secure(@temp_dir)
      @temp_file && FileUtils.remove_entry_secure(@temp_file)
    end

    private

      def valid_url?(string)
        uri = URI.parse(string)
        %w[http https].include?(uri.scheme)
      rescue URI::BadURIError, URI::InvalidURIError
        false
      end

      def download_redmine_version(version)
        url = "https://www.redmine.org/releases/redmine-#{version}.zip"
        download_from_url(url)
      end

      def download_from_url(url)
        uri = URI.parse(url)

        @temp_file = Tempfile.new(%w[redmine .zip])
        @temp_file.binmode

        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          head = http.request_head(uri)

          unless head.is_a?(Net::HTTPSuccess)
            error "Cannot download #{uri}"
          end

          print_title("Downloading #{uri}")
          progressbar = TTY::ProgressBar.new(PROGRESSBAR_FORMAT, total: head['content-length'].to_i, frequency: 2, clear: true)

          http.get(uri) do |data|
            @temp_file.write(data)
            progressbar.advance(data.size)
          end

          progressbar.finish
        end

        logger.info("#{uri} downloaded")

        @temp_file.close
        @temp_file.path
      end

      def extract_zip
        Zip::File.open(@package) do |zip_file|
          # Progressbar
          progressbar = TTY::ProgressBar.new(PROGRESSBAR_FORMAT, total: zip_file.size, frequency: 2, clear: true)

          zip_file.each do |entry|
            dest_file = File.join(@temp_dir, entry.name)
            FileUtils.mkdir_p(File.dirname(dest_file))

            entry.extract(dest_file)
            progressbar.advance(1)
          end

          progressbar.finish
        end

      end

      # Extract .tar.gz archive
      # based on http://dracoater.blogspot.cz/2013/10/extracting-files-from-targz-with-ruby.html
      #
      # Originally tar did not support paths longer than 100 chars. GNU tar is better and they
      # implemented support for longer paths, but it was made through a hack called ././@LongLink.
      # Shortly speaking, if you stumble upon an entry in tar archive which path equals to above
      # mentioned ././@LongLink, that means that the following entry path is longer than 100 chars and
      # is truncated. The full path of the following entry is actually the value of the current entry.
      #
      def extract_tar_gz
        Gem::Package::TarReader.new(Zlib::GzipReader.open(@package)) do |tar|

          # Progressbar
          progressbar = TTY::ProgressBar.new(PROGRESSBAR_FORMAT, total: tar.count, frequency: 2, clear: true)

          # tar.count move position pointer to end
          tar.rewind

          dest_file = nil
          tar.each do |entry|

            if entry.full_name == TAR_LONGLINK
              dest_file = File.join(@temp_dir, entry.read.strip)
              next
            end

            # Pax header
            # "%d %s=%s\n", <length>, <keyword>, <value>
            if entry.header.typeflag == 'x'

              pax_headers = entry.read.split("\n")
              pax_headers.each do |header|
                meta, value = header.split('=', 2)
                length, keyword = meta.split(' ', 2)

                if keyword == 'path'
                  dest_file = File.join(@temp_dir, value)
                  next
                end
              end

              # If there is no header with keyword "path"
              next
            end

            dest_file ||= File.join(@temp_dir, entry.full_name)
            if entry.directory?
              FileUtils.rm_rf(dest_file) unless File.directory?(dest_file)
              FileUtils.mkdir_p(dest_file, mode: entry.header.mode, verbose: false)
            elsif entry.file?
              FileUtils.rm_rf(dest_file) unless File.file?(dest_file)
              File.open(dest_file, 'wb') do |f|
                f.write(entry.read)
              end
              FileUtils.chmod(entry.header.mode, dest_file, verbose: false)
            elsif entry.header.typeflag == '2' # symlink
              File.symlink(entry.header.linkname, dest_file)
            end

            dest_file = nil
            progressbar.advance(1)
          end

          progressbar.finish
        end
      end

  end
end
