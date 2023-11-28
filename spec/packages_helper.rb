module PackagesHelper

  def packages_dir
    File.expand_path(File.join(__dir__, 'packages'))
  end

  def package_v345
    File.join(packages_dir, 'redmine-3.4.5.zip')
  end

  def package_v345_rys
    File.join(packages_dir, 'redmine-3.4.5-rys.zip')
  end

  def package_v503
    File.join(packages_dir, 'redmine-5.0.3.zip')
  end

  def package_someting_else
    File.join(packages_dir, 'something-else.zip')
  end

  def package_high_installer_version
    File.join(packages_dir, 'high-installer-version.zip')
  end

  def package_default_db
    File.join(packages_dir, 'redmine-3.4.5-default-db.zip')
  end

end
