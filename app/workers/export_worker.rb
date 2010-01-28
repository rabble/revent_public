class ExportWorker < Workling::Base
  def export_users(args)
    site_id = args[:site_id]
    start = args[:start]
    Site.current = Site.find(site_id)
    @users = Site.current.users.find(:all, :include => [:custom_attributes, :attending, :events])
    @attribute_names = @users.inject([]) {|names, u| names << u.custom_attributes.map {|a| a.name }; names.flatten.compact.uniq }
    tmpfile = File.join(RAILS_ROOT, 'tmp', "#{Site.current.theme}_users_#{start}.tmp")
    require 'fastercsv'
    FasterCSV.open(tmpfile, "w") do |csv|
      csv << ["Email", "First_Name", "Last_Name", "Phone", "Street", "Street_2", "City", "State", "Postal_Code", "Partner_Code", "Events_Hosting_IDS", "Events_Attending_IDS"] + @attribute_names
      @users.each do |user|
        csv << [user.email, user.first_name, user.last_name, user.phone, user.street, user.street_2, user.city, user.state, user.postal_code, user.partner_id] + [ user.event_ids.join(','), user.attending_ids.join(',') ] + @attribute_names.map {|a| user.custom_attributes_data.send(a.to_sym) }
      end
    end
    csvfile = File.join(RAILS_ROOT, 'tmp', "#{Site.current.theme}_users_#{start}.csv")
    FileUtils.mv(tmpfile, csvfile)
  end
end
