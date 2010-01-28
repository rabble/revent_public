class ServiceObject < ActiveRecord::Base
  belongs_to :mirrored, :polymorphic => true
  belongs_to :remote,   :polymorphic => true
  validates_presence_of :mirrored_type, :mirrored_id, :remote_service, :remote_type, :remote_id
end
