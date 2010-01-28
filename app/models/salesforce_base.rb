require 'active_record/connection_adapters/asf_active_record'

class SalesforceBase < ActiveRecord::Base
  include ActiveSalesforce::ActiveRecord::Mixin
  self.abstract_class = true
end
