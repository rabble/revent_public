# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def countries_for_select
    CountryCodes::countries_for_select('name', 'a3').map{|a| [a[0],a[1].downcase]}.sort.unshift(['All Countries', 'all'])
  end
  def calendar_select
    Site.current.sorted_calendars.reject {|c| c.archived?}.collect{|c| [c.name, c.permalink]}
  end
end
