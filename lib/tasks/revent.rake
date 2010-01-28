namespace :revent do
  desc "Load sites table with local domains"
  task :setup_sites do
    load 'config/environment.rb'
    domain = "." + ( ENV['DOMAIN'] || "local_revent.org" )
    Site.find(:all).each do |s| 
      name = s.theme || s.host[/.+\.(.+)\.[^\.]+$/,1]
      s.update_attribute(:host, name + domain) 
    end
  end

  task :consolidate_yaml do
    config_sites_dir = File.join(RAILS_ROOT,'config','sites')
    FileUtils.mkdir_p(config_sites_dir) unless File.exists?(config_sites_dir)
    Site.find(:all).each do |site|
      config = {}
      Dir["#{Site.config_path(site.id)}/*.yml"].each do |old_config_file|
        resource = old_config_file[/(.*)-config/, 1]
        next if File.exists?(site.config_file) && 
                YAML.load_file(site.config_file)[resource]
        config[resource] = YAML.load_file(old_config_file)
      end
      File.open(site.config_file, "a") {|f| YAML.dump(config, f)}
    end
  end
end
