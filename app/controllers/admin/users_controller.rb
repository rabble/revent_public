class Admin::UsersController < AdminController  
  active_scaffold :users do |config|
    config.columns.add :effective_calendar
  	config.list.columns = 
  	    [:created_at, :email, :first_name, :last_name, :city, :state, :events, :attending, :effective_calendar, :site]
  	config.show.columns = 
  	    [:created_at, :email, :first_name, :last_name, :phone, :street, :street_2, :city, :state, :postal_code, :organization]
  	config.update.columns =     
  	    [:email, :first_name, :last_name, :phone, :street, :street_2, :city, :state, :postal_code, :organization, :admin]
    columns[:admin].ui_type = :checkbox
    config.actions.exclude :create
   	config.action_links.add 'reset_password', :label => 'Reset Password', :type => :record, :page => true
    config.list.sorting = [{ :created_at => :desc }]
  	config.columns[:created_at].label = "Created on"
  	config.columns[:events].label = "Hosting"
  	config.columns[:events].clear_link
    config.columns[:attending].clear_link    
  	columns[:effective_calendar].sort_by :method => 'effective_calendar.name'
=begin
    config.columns[:attending].set_link('nested', :parameters => {:associations => :attending})
    config.columns[:events].set_link('nested', :parameters => {:associations => :events})
=end
  end
  
  def index
    # embed active_scaffold in index.rhtml so we can provide export users link
  end 
  
  def reset_password
    @user = Site.current.users.find(params[:id])
    if request.post?      
      @user.password = params[:user][:password] if params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation] if params[:user][:password_confirmation]
      @user.activated_at = Time.now.utc
      if @user.save
        flash[:notice] = "Password reset for " + @user.full_name
      else
        flash[:notice] = "Could not reset password for " + @user.full_name
      end      
      redirect_to :action => 'index'
    end
  end

  def export
    if params[:id].blank?
      @start = Time.now.strftime("%Y%m%d%H%M%S")
      ExportWorker.async_export_users(:site_id => Site.current.id, :start => @start)
    else
      @start = params[:id]
      download_file = File.join(RAILS_ROOT, 'tmp', "#{Site.current.theme}_users_#{@start}.csv")
      unless File.exists?(download_file)
        flash[:notice] = "Export not ready to download. Check back in a few minutes"
        render && return
      end

      send_file(download_file, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{Site.current.theme}_users_#{@start}.csv") 
    end
  end
end
