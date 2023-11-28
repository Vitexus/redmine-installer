require 'ostruct'
require 'yaml'

module RedmineInstaller
  class Profile < OpenStruct
    PROFILES_FILE = File.join(Dir.home, '.redmine-installer-profiles.yml')

    def self.get!(profile_id)
      data = YAML.load_file(PROFILES_FILE, aliases: true) rescue nil

      if data.is_a?(Hash) && data.has_key?(profile_id)
        Profile.new(profile_id, data[profile_id])
      else
        raise RedmineInstaller::ProfileError, "Profile ID=#{profile_id} does not exist"
      end
    end

    attr_reader :id

    def initialize(id=nil, data={})
      super(data)
      @id = id
    end

    def save
      FileUtils.touch(PROFILES_FILE)

      all_data = YAML.load_file(PROFILES_FILE, aliases: true)
      all_data = {} unless all_data.is_a?(Hash)

      @id ||= all_data.keys.last.to_i + 1

      all_data[@id] = to_h

      File.write(PROFILES_FILE, YAML.dump(all_data))

      puts "Profile was saved under ID=#{@id}"
    rescue => e
      puts "Profile could not be save due to #{e.message}"
    end

  end
end
