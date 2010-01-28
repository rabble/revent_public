class Admin::CategoriesController < AdminController 
  def index
  end
  
  active_scaffold :category do |config|
   	config.list.columns = [:name, :description, :calendar, :site]
  	config.columns = [:name, :description, :calendar, :site]
  	columns[:calendar].ui_type = :select
  	columns[:site].ui_type = :select
  end   
end
