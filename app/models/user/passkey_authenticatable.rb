module User::PasskeyAuthenticatable
  extend ActiveSupport::Concern

  included do
    has_many :passkeys, dependent: :destroy
  end
end
