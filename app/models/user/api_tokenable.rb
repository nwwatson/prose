module User::ApiTokenable
  extend ActiveSupport::Concern

  included do
    has_many :api_tokens, dependent: :destroy
  end

  def generate_api_token!(name:)
    ApiToken.generate_for(self, name: name)
  end
end
