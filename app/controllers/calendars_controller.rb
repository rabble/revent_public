class CalendarsController < ApplicationController
  helper MapsHelper
  caches_page_unless_flash :show

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create ],
         :redirect_to => { :action => :list }

  def show
    # event query is in events_controller#flashmap or inline in themes/#{theme}/views/calendars/show.rhtml
    @flashmap_data_url = url_for(:permalink => @calendar.permalink, :controller => 'events', :action => 'flashmap', :only_path => true)
  end
  
  def num_users
    render :inline => Site.current.users.length.to_s
  end
end
