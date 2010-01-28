# time zone offset issue
#
# Future refactoring of this issue
# 1. Move this to site yaml file once we move all site config into one yaml
# 2. Once we move to rails v2.1 we can solve the time-zone issue for events
#    You can get the time-zone offset for salesforce account by using owner_id
#    on any Contact record and then looking up owner in Sforce User table
SALESFORCE_TZ_OFFSET = {
  # this is the difference in time between GMT (i.e. England)  and Washington, DC 
  # (where pascal@libertyconcepts.com time-zone is set to)
  # basically, this is used to undo the offset that salesforce adds to the start/end times
  'events.servicenation.org' => 14400  # 4 hours  
}
