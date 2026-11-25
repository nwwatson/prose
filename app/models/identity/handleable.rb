module Identity::Handleable
  extend ActiveSupport::Concern

  included do
    validates :handle, uniqueness: { case_sensitive: false, allow_nil: true },
      format: { with: /\A[a-zA-Z0-9_]+\z/, message: :handle_format, allow_nil: true },
      length: { minimum: 3, maximum: 30, allow_nil: true }

    normalizes :handle, with: ->(handle) { handle.strip.downcase }
  end
end
