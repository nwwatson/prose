class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user
  attribute :subscriber
  attribute :identity
  attribute :site_setting
end
