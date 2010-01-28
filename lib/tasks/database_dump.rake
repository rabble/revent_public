namespace :db do
  desc "Dump the current database to a MySQL file" 
  task :dump do
    load 'config/environment.rb'
    configs = ActiveRecord::Base.configurations
    case configs[RAILS_ENV]["adapter"]
    when 'mysql'
      ActiveRecord::Base.establish_connection(configs[RAILS_ENV])
      File.open("db/#{RAILS_ENV}_data.sql", "w+") do |f|
        if configs[RAILS_ENV]["password"].blank?
          f << `mysqldump -h #{configs[RAILS_ENV]["host"]} -u #{configs[RAILS_ENV]["username"]} #{configs[RAILS_ENV]["database"]}`
        else
          f << `mysqldump -h #{configs[RAILS_ENV]["host"]} -u #{configs[RAILS_ENV]["username"]} -p#{configs[RAILS_ENV]["password"]} #{configs[RAILS_ENV]["database"]}`
        end
      end
    else
      raise "Task not supported by '#{configs[RAILS_ENV]['adapter']}'" 
    end
  end

  desc "Refreshes your local development environment to the current production database" 
  task :production_data_refresh do
    `cap db:remote_runner`
    `rake db:production_data_load --trace`
    `rake revent:setup_sites --trace`
  end 

  desc "Loads the production data downloaded into db/production_data.sql into your local development database" 
  task :production_data_load do
    load 'config/environment.rb'
    configs = ActiveRecord::Base.configurations
    case configs[RAILS_ENV]["adapter"]
    when 'mysql'
      ActiveRecord::Base.establish_connection(configs[RAILS_ENV])
      if configs[RAILS_ENV]["password"].blank?
        `mysql -h #{configs[RAILS_ENV]["host"]} -u #{configs[RAILS_ENV]["username"]} #{configs[RAILS_ENV]["database"]} < db/production_data.sql`
      else
        `mysql -h #{configs[RAILS_ENV]["host"]} -u #{configs[RAILS_ENV]["username"]} -p#{configs[RAILS_ENV]["password"]} #{configs[RAILS_ENV]["database"]} < db/production_data.sql`
      end
    else
      raise "Task not supported by '#{configs[RAILS_ENV]['adapter']}'" 
    end
  end
end
