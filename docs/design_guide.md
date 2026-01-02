# Ruby on Rails Application Design Guide

A practical guide to building maintainable, scalable Rails applications using proven design patterns.

---

## Table of Contents

1. [Core Principles](#1-core-principles)
2. [Model Architecture](#2-model-architecture)
3. [Authentication & Authorization](#3-authentication--authorization)
4. [Multi-Tenancy](#4-multi-tenancy)
5. [Service Layer](#5-service-layer)
6. [Value Objects & Custom Types](#6-value-objects--custom-types)
7. [Query Patterns](#7-query-patterns)
8. [Background Processing](#8-background-processing)
9. [Configuration Management](#9-configuration-management)
10. [File Organization](#10-file-organization)
11. [Testing Strategy](#11-testing-strategy)

---

## 1. Core Principles

### 1.1 Skinny Controllers, Rich Domain

Controllers should only handle HTTP concerns. Business logic belongs in models, service objects, or dedicated classes.

```ruby
# ❌ Avoid: Fat controller
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    @order.total = calculate_total(order_params[:items])
    @order.tax = @order.total * tax_rate_for(current_user.address)
    @order.shipping = ShippingCalculator.new(@order).calculate
    
    if @order.save
      OrderMailer.confirmation(@order).deliver_later
      InventoryService.reserve(@order.items)
      redirect_to @order
    else
      render :new
    end
  end
end

# ✅ Prefer: Thin controller, rich domain
class OrdersController < ApplicationController
  def create
    @order = Order.place(order_params, customer: current_user)
    
    if @order.persisted?
      redirect_to @order
    else
      render :new
    end
  end
end
```

### 1.2 Composition Over Inheritance

Use modules and concerns to share behavior rather than deep inheritance hierarchies.

```ruby
# ❌ Avoid: Deep inheritance
class AdminUser < User < Person < ApplicationRecord
end

# ✅ Prefer: Composition via concerns
class User < ApplicationRecord
  include Authenticatable
  include Authorizable
  include Trackable
end
```

### 1.3 Explicit Over Implicit

Make dependencies and behavior visible. Avoid hidden side effects.

```ruby
# ❌ Avoid: Hidden dependencies
class Report
  def generate
    data = ApiClient.fetch  # Hidden global dependency
    format(data)
  end
end

# ✅ Prefer: Explicit dependencies
class Report
  def initialize(api_client: ApiClient.new)
    @api_client = api_client
  end
  
  def generate
    data = @api_client.fetch
    format(data)
  end
end
```

---

## 2. Model Architecture

### 2.1 Concerns for Behavior Composition

Extract cohesive sets of functionality into concerns. Each concern should have a single responsibility.

**File Structure**:

```
app/models/
├── user.rb
└── user/
    ├── authenticatable.rb
    ├── avatar.rb
    ├── named.rb
    └── role.rb
```

**Implementation Pattern**:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Avatar, Named, Role, Authenticatable
  
  belongs_to :account
  belongs_to :identity
end

# app/models/user/named.rb
module User::Named
  extend ActiveSupport::Concern

  included do
    # Class-level configuration: scopes, validations, callbacks
    scope :alphabetically, -> { order("lower(name)") }
    validates :name, presence: true
  end

  # Instance methods
  def first_name
    name.split(/\s/).first
  end

  def last_name
    name.split(/\s/, 2).last
  end

  def initials
    name.scan(/\b\p{L}/).join.upcase
  end

  class_methods do
    # Class methods if needed
    def search_by_name(query)
      where("name ILIKE ?", "%#{query}%")
    end
  end
end
```

**When to Extract a Concern**:

- 3+ related methods that could be reused
- Behavior that might apply to multiple models
- Code that can be tested in isolation
- Feature-specific logic (avatars, soft-delete, versioning)

### 2.2 Nested Classes for Subordinate Concepts

Place tightly-coupled classes within their parent's namespace.

```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  has_many :invoices, class_name: "Subscription::Invoice"
end

# app/models/subscription/invoice.rb
class Subscription::Invoice < ApplicationRecord
  belongs_to :subscription
end

# app/models/subscription/plan.rb
class Subscription::Plan
  TIERS = %w[free basic premium enterprise].freeze
  
  attr_reader :name, :price, :features
  
  def initialize(name:, price:, features:)
    @name = name
    @price = price
    @features = features
  end
end
```

### 2.3 Current Attributes for Request Context

Use `ActiveSupport::CurrentAttributes` to manage request-scoped state without passing context everywhere.

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :account
  attribute :request_id, :user_agent, :ip_address

  # Cascading setters for related attributes
  def session=(value)
    super
    self.user = value&.user
    self.account = value&.account
  end

  # Scoping helpers
  def with_account(account, &block)
    with(account: account, &block)
  end

  # Computed attributes
  def admin?
    user&.admin?
  end
end

# Usage in controllers
class ApplicationController < ActionController::Base
  before_action :set_current_attributes

  private

  def set_current_attributes
    Current.session = find_session
    Current.request_id = request.request_id
    Current.ip_address = request.remote_ip
  end
end

# Usage anywhere in the application
class AuditLog < ApplicationRecord
  before_create :set_actor

  private

  def set_actor
    self.user = Current.user
    self.ip_address = Current.ip_address
  end
end
```

---

## 3. Authentication & Authorization

### 3.1 Separate Identity from User

In multi-tenant applications, separate the authentication identity from account membership.

```ruby
# Identity = A person (unique by email)
class Identity < ApplicationRecord
  has_many :users           # Memberships in accounts
  has_many :sessions        # Login sessions
  has_many :accounts, through: :users
  
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

# User = Membership in an account
class User < ApplicationRecord
  belongs_to :identity
  belongs_to :account
  
  # Role and permissions are per-account
  enum :role, %i[owner admin member]
end

# Session = Authentication state
class Session < ApplicationRecord
  belongs_to :identity
  
  # Track login metadata
  attribute :ip_address
  attribute :user_agent
end
```

### 3.2 Authentication Concern for Controllers

Extract authentication logic into a reusable concern.

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_unauthenticated_access(**options)
      allow_unauthenticated_access(**options)
      before_action :redirect_authenticated_user, **options
    end
  end

  private

  def authenticated?
    Current.session.present?
  end

  def current_user
    Current.user
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    if session = Session.find_by_token(cookies.signed[:session_token])
      Current.session = session
    end
  end

  def request_authentication
    session[:return_to] = request.url
    redirect_to login_path
  end

  def redirect_authenticated_user
    redirect_to root_path if authenticated?
  end

  def start_session(identity)
    session = identity.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    Current.session = session
    cookies.signed.permanent[:session_token] = {
      value: session.token,
      httponly: true,
      same_site: :lax
    }
    session
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_token)
  end
end
```

### 3.3 Role-Based Permissions

Implement permissions as methods on the user model.

```ruby
# app/models/user/role.rb
module User::Role
  extend ActiveSupport::Concern

  included do
    enum :role, {
      owner: "owner",
      admin: "admin",
      member: "member",
      guest: "guest"
    }

    # Scopes for querying by role
    scope :owners, -> { where(role: :owner) }
    scope :admins, -> { where(role: [:owner, :admin]) }
    scope :active_members, -> { where(role: [:owner, :admin, :member]) }
  end

  # Permission checks
  def admin?
    owner? || role == "admin"
  end

  def can_manage_users?
    admin?
  end

  def can_delete_account?
    owner?
  end

  def can_modify?(resource)
    return true if admin?
    resource.respond_to?(:user_id) && resource.user_id == id
  end

  # Scoped permission checks
  def can_administer?(other_user)
    return false if other_user == self
    return false if other_user.owner?
    admin?
  end
end
```

---

## 4. Multi-Tenancy

### 4.1 Account-Scoped Resources

Scope all tenant data to accounts using associations and default scopes.

```ruby
# app/models/account.rb
class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :documents, dependent: :destroy

  # Factory method for account creation
  def self.create_with_owner(account_params:, owner_params:)
    transaction do
      create!(account_params).tap do |account|
        account.users.create!(owner_params.merge(role: :owner))
      end
    end
  end
end

# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :account
  
  # Ensure account context
  validates :account, presence: true
  
  # Default scope (use sparingly)
  default_scope { where(account: Current.account) if Current.account }
end
```

### 4.2 Account Switching

Handle users with access to multiple accounts.

```ruby
# app/controllers/concerns/account_switching.rb
module AccountSwitching
  extend ActiveSupport::Concern

  included do
    before_action :set_current_account
    helper_method :current_account, :available_accounts
  end

  private

  def set_current_account
    Current.account = find_current_account
    
    unless Current.account
      redirect_to account_selector_path
    end
  end

  def find_current_account
    if account_id = session[:current_account_id]
      current_user.accounts.find_by(id: account_id)
    else
      current_user.accounts.first
    end
  end

  def current_account
    Current.account
  end

  def available_accounts
    current_user.accounts
  end

  def switch_to_account(account)
    if current_user.accounts.include?(account)
      session[:current_account_id] = account.id
      Current.account = account
    end
  end
end
```

---

## 5. Service Layer

### 5.1 Form Objects for Complex Input

Use form objects when dealing with multiple models or complex validation.

```ruby
# app/models/registration.rb
class Registration
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :email, :string
  attribute :name, :string
  attribute :company_name, :string
  attribute :plan, :string, default: "free"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :company_name, presence: true
  validates :plan, inclusion: { in: %w[free basic premium] }

  attr_reader :identity, :account, :user

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      create_identity
      create_account
      create_user
      send_welcome_email
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  private

  def create_identity
    @identity = Identity.find_or_create_by!(email: email.downcase.strip)
  end

  def create_account
    @account = Account.create!(name: company_name, plan: plan)
  end

  def create_user
    @user = account.users.create!(
      identity: identity,
      name: name,
      role: :owner
    )
  end

  def send_welcome_email
    RegistrationMailer.welcome(@user).deliver_later
  end
end

# Usage in controller
class RegistrationsController < ApplicationController
  def create
    @registration = Registration.new(registration_params)
    
    if @registration.save
      start_session(@registration.identity)
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

### 5.2 Service Objects for Business Operations

Use service objects for complex operations that don't fit in a model.

```ruby
# app/services/application_service.rb
class ApplicationService
  def self.call(...)
    new(...).call
  end
end

# app/services/order_processor.rb
class OrderProcessor < ApplicationService
  def initialize(order, payment_method:)
    @order = order
    @payment_method = payment_method
  end

  def call
    ApplicationRecord.transaction do
      validate_inventory!
      process_payment!
      reserve_inventory!
      send_notifications
    end

    Result.success(order: @order)
  rescue InsufficientInventoryError => e
    Result.failure(error: "Items unavailable: #{e.items.join(', ')}")
  rescue PaymentError => e
    Result.failure(error: "Payment failed: #{e.message}")
  end

  private

  def validate_inventory!
    unavailable = @order.items.reject(&:in_stock?)
    raise InsufficientInventoryError.new(unavailable) if unavailable.any?
  end

  def process_payment!
    @payment = PaymentGateway.charge(
      amount: @order.total,
      method: @payment_method
    )
    @order.update!(payment_id: @payment.id, status: :paid)
  end

  def reserve_inventory!
    @order.items.each(&:reserve!)
  end

  def send_notifications
    OrderMailer.confirmation(@order).deliver_later
    SlackNotifier.new_order(@order).deliver_later
  end
end

# Simple result object
class Result
  attr_reader :data, :error

  def self.success(**data)
    new(success: true, **data)
  end

  def self.failure(error:)
    new(success: false, error: error)
  end

  def initialize(success:, error: nil, **data)
    @success = success
    @error = error
    @data = data
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
```

### 5.3 Interactors for Multi-Step Workflows

For complex workflows, consider the interactor pattern.

```ruby
# app/interactors/onboard_customer.rb
class OnboardCustomer
  include Interactor::Organizer

  organize CreateAccount,
           SetupBilling,
           ProvisionResources,
           SendWelcomeKit,
           NotifySalesTeam
end

# app/interactors/create_account.rb
class CreateAccount
  include Interactor

  def call
    account = Account.create!(
      name: context.company_name,
      plan: context.plan
    )
    context.account = account
  rescue ActiveRecord::RecordInvalid => e
    context.fail!(error: e.message)
  end
end
```

---

## 6. Value Objects & Custom Types

### 6.1 Value Objects for Domain Concepts

Encapsulate domain concepts that aren't entities.

```ruby
# app/models/money.rb
class Money
  include Comparable

  attr_reader :cents, :currency

  def initialize(cents, currency = "USD")
    @cents = cents.to_i
    @currency = currency.to_s.upcase
  end

  def dollars
    cents / 100.0
  end

  def +(other)
    ensure_same_currency!(other)
    Money.new(cents + other.cents, currency)
  end

  def -(other)
    ensure_same_currency!(other)
    Money.new(cents - other.cents, currency)
  end

  def *(multiplier)
    Money.new((cents * multiplier).round, currency)
  end

  def <=>(other)
    ensure_same_currency!(other)
    cents <=> other.cents
  end

  def to_s
    format("$%.2f", dollars)
  end

  def self.from_dollars(amount, currency = "USD")
    new((amount.to_f * 100).round, currency)
  end

  private

  def ensure_same_currency!(other)
    raise CurrencyMismatchError unless currency == other.currency
  end
end
```

### 6.2 Custom ActiveRecord Types

Create custom types for automatic serialization.

```ruby
# lib/types/money_type.rb
class MoneyType < ActiveRecord::Type::Integer
  def cast(value)
    case value
    when Money
      value
    when Hash
      Money.new(value[:cents], value[:currency])
    when Integer
      Money.new(value)
    when String
      Money.from_dollars(value.delete("$,"))
    end
  end

  def serialize(value)
    value&.cents
  end

  def deserialize(value)
    Money.new(value) if value
  end
end

# config/initializers/types.rb
ActiveRecord::Type.register(:money, MoneyType)

# Usage in model
class Product < ApplicationRecord
  attribute :price, :money
end
```

### 6.3 Encapsulated Token Logic

Group related logic into modules.

```ruby
# app/models/verification_code.rb
module VerificationCode
  ALPHABET = "0123456789ABCDEFGHJKMNPQRSTUVWXYZ".chars.freeze  # Excludes I, L, O
  LENGTH = 6
  
  # Substitutions for user-friendly input
  SUBSTITUTIONS = {
    "I" => "1",
    "L" => "1", 
    "O" => "0"
  }.freeze

  class << self
    def generate
      Array.new(LENGTH) { ALPHABET.sample }.join
    end

    def normalize(code)
      return nil if code.blank?

      code.to_s
          .upcase
          .then { |c| apply_substitutions(c) }
          .then { |c| remove_invalid_chars(c) }
          .then { |c| c.length == LENGTH ? c : nil }
    end

    private

    def apply_substitutions(code)
      SUBSTITUTIONS.reduce(code) { |result, (from, to)| result.tr(from, to) }
    end

    def remove_invalid_chars(code)
      code.gsub(/[^#{ALPHABET.join}]/, "")
    end
  end
end

# Usage
code = VerificationCode.generate        # => "K7NM2P"
VerificationCode.normalize("k7nm2p")    # => "K7NM2P"
VerificationCode.normalize("K7NM2O")    # => "K7NM20" (O -> 0)
```

---

## 7. Query Patterns

### 7.1 Scopes for Reusable Queries

Define scopes for common query patterns.

```ruby
class Article < ApplicationRecord
  # Status scopes
  scope :draft, -> { where(status: :draft) }
  scope :published, -> { where(status: :published) }
  scope :archived, -> { where(status: :archived) }

  # Time-based scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :published_after, ->(date) { where("published_at > ?", date) }
  scope :published_this_month, -> { 
    where(published_at: Time.current.beginning_of_month..Time.current) 
  }

  # Filtering scopes
  scope :by_author, ->(author) { where(author: author) }
  scope :tagged_with, ->(tag) { joins(:tags).where(tags: { name: tag }) }
  scope :search, ->(query) { 
    where("title ILIKE ? OR body ILIKE ?", "%#{query}%", "%#{query}%") 
  }

  # Eager loading scopes
  scope :with_associations, -> { includes(:author, :tags, :comments) }

  # Composite scopes
  scope :featured, -> { published.where(featured: true).recent.limit(5) }
end

# Usage - scopes chain naturally
Article.published
       .by_author(current_user)
       .tagged_with("ruby")
       .recent
       .limit(10)
```

### 7.2 Query Objects for Complex Queries

Extract complex queries into dedicated classes.

```ruby
# app/queries/application_query.rb
class ApplicationQuery
  def initialize(relation = default_relation)
    @relation = relation
  end

  def call
    @relation
  end

  def self.call(...)
    new(...).call
  end

  private

  def default_relation
    raise NotImplementedError
  end
end

# app/queries/articles/search_query.rb
class Articles::SearchQuery < ApplicationQuery
  def initialize(relation = Article.all, params: {})
    super(relation)
    @params = params
  end

  def call
    @relation
      .then { |r| filter_by_status(r) }
      .then { |r| filter_by_author(r) }
      .then { |r| filter_by_date_range(r) }
      .then { |r| filter_by_search_term(r) }
      .then { |r| apply_sorting(r) }
  end

  private

  def default_relation
    Article.all
  end

  def filter_by_status(relation)
    return relation if @params[:status].blank?
    relation.where(status: @params[:status])
  end

  def filter_by_author(relation)
    return relation if @params[:author_id].blank?
    relation.where(author_id: @params[:author_id])
  end

  def filter_by_date_range(relation)
    relation = relation.where("created_at >= ?", @params[:from]) if @params[:from]
    relation = relation.where("created_at <= ?", @params[:to]) if @params[:to]
    relation
  end

  def filter_by_search_term(relation)
    return relation if @params[:q].blank?
    relation.where("title ILIKE :q OR body ILIKE :q", q: "%#{@params[:q]}%")
  end

  def apply_sorting(relation)
    case @params[:sort]
    when "oldest" then relation.order(created_at: :asc)
    when "title" then relation.order(:title)
    else relation.order(created_at: :desc)
    end
  end
end

# Usage
Articles::SearchQuery.call(
  params: {
    status: :published,
    q: "ruby",
    sort: "oldest"
  }
)
```

---

## 8. Background Processing

### 8.1 Job Organization

Structure jobs by domain area.

```
app/jobs/
├── application_job.rb
├── notifications/
│   ├── email_job.rb
│   ├── push_job.rb
│   └── slack_job.rb
├── billing/
│   ├── charge_job.rb
│   └── invoice_job.rb
└── maintenance/
    ├── cleanup_job.rb
    └── stats_job.rb
```

### 8.2 Job Implementation Pattern

```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  # Retry with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  # Discard if record no longer exists
  discard_on ActiveRecord::RecordNotFound

  # Log job execution
  around_perform do |job, block|
    Rails.logger.tagged(job.class.name, job.job_id) do
      Rails.logger.info "Starting job"
      result = block.call
      Rails.logger.info "Completed job"
      result
    end
  end
end

# app/jobs/billing/charge_job.rb
class Billing::ChargeJob < ApplicationJob
  queue_as :critical
  
  retry_on PaymentGateway::RateLimitError, wait: 1.minute, attempts: 3
  discard_on PaymentGateway::InvalidCardError

  def perform(subscription_id)
    subscription = Subscription.find(subscription_id)
    
    Billing::ChargeService.call(subscription)
  end
end
```

### 8.3 Recurring Tasks

Use Solid Queue's recurring tasks for scheduled jobs.

```yaml
# config/recurring.yml
production:
  daily_cleanup:
    class: Maintenance::CleanupJob
    schedule: every day at 3am
    
  hourly_stats:
    class: Maintenance::StatsJob
    schedule: every hour

  weekly_report:
    class: Reports::WeeklyJob
    schedule: every monday at 9am
    args:
      - report_type: summary
```

---

## 9. Configuration Management

### 9.1 Environment Variables with Defaults

```ruby
# app/models/app_config.rb
class AppConfig
  class << self
    def mailer_from
      ENV.fetch("MAILER_FROM", "noreply@example.com")
    end

    def max_upload_size
      ENV.fetch("MAX_UPLOAD_SIZE", 10).to_i.megabytes
    end

    def feature_enabled?(name)
      ENV.fetch("FEATURE_#{name.to_s.upcase}", "false") == "true"
    end

    def redis_url
      ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
    end
  end
end

# Usage
AppConfig.mailer_from
AppConfig.feature_enabled?(:new_dashboard)
```

### 9.2 Model Constants

Define domain constants within models.

```ruby
class MagicLink < ApplicationRecord
  CODE_LENGTH = 6
  EXPIRATION_DURATION = 15.minutes
  MAX_ATTEMPTS = 3

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.code ||= generate_code
    self.expires_at ||= EXPIRATION_DURATION.from_now
  end

  def generate_code
    VerificationCode.generate
  end
end
```

---

## 10. File Organization

### 10.1 Model Directory Structure

```
app/models/
├── application_record.rb
├── current.rb                    # CurrentAttributes
│
├── account.rb                    # Main model file
├── account/
│   ├── billing.rb               # Concern
│   ├── seeder.rb                # Service-like class
│   └── settings.rb              # Nested model or value object
│
├── user.rb
├── user/
│   ├── avatar.rb                # Concern
│   ├── named.rb                 # Concern
│   ├── role.rb                  # Concern
│   └── preferences.rb           # Nested model
│
├── identity.rb
├── identity/
│   ├── access_token.rb          # Nested ActiveRecord model
│   └── joinable.rb              # Concern
│
└── concerns/                    # Shared concerns (used by multiple models)
    ├── trackable.rb
    ├── soft_deletable.rb
    └── sluggable.rb
```

### 10.2 Complete Application Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── concerns/
│   │   ├── authentication.rb
│   │   └── authorization.rb
│   ├── sessions_controller.rb
│   └── api/
│       └── v1/
│           └── base_controller.rb
│
├── models/
│   └── (see above)
│
├── services/
│   ├── application_service.rb
│   ├── billing/
│   │   └── charge_service.rb
│   └── notifications/
│       └── dispatcher.rb
│
├── queries/
│   ├── application_query.rb
│   └── articles/
│       └── search_query.rb
│
├── jobs/
│   ├── application_job.rb
│   └── (domain organized)
│
├── mailers/
│   ├── application_mailer.rb
│   └── user_mailer.rb
│
├── helpers/
│   ├── application_helper.rb
│   └── formatting_helper.rb
│
└── views/
    └── (standard Rails structure)

lib/
├── rails_ext/                   # Rails/ActiveRecord extensions
│   └── custom_type.rb
└── tasks/
    └── maintenance.rake

config/
├── initializers/
│   ├── extensions.rb            # Load lib/rails_ext
│   └── types.rb                 # Register custom types
└── locales/
    └── en.yml
```

---

## 11. Testing Strategy

### 11.1 Model Tests

```ruby
# test/models/user_test.rb
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Test validations
  test "requires name" do
    user = User.new(name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  # Test scopes
  test ".admins returns owners and admins" do
    owner = users(:owner)
    admin = users(:admin)
    member = users(:member)

    admins = User.admins

    assert_includes admins, owner
    assert_includes admins, admin
    assert_not_includes admins, member
  end

  # Test instance methods
  test "#initials extracts first letter of each word" do
    user = User.new(name: "John David Smith")
    assert_equal "JDS", user.initials
  end

  # Test permissions
  test "#can_administer? returns false for self" do
    admin = users(:admin)
    assert_not admin.can_administer?(admin)
  end
end
```

### 11.2 Service/Form Object Tests

```ruby
# test/models/registration_test.rb
require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "creates identity, account, and user" do
    registration = Registration.new(
      email: "new@example.com",
      name: "New User",
      company_name: "New Company"
    )

    assert_difference -> { Identity.count } => 1,
                      -> { Account.count } => 1,
                      -> { User.count } => 1 do
      assert registration.save
    end

    assert_equal "new@example.com", registration.identity.email
    assert_equal "New Company", registration.account.name
    assert registration.user.owner?
  end

  test "reuses existing identity" do
    existing = identities(:one)

    registration = Registration.new(
      email: existing.email,
      name: "New User",
      company_name: "New Company"
    )

    assert_no_difference -> { Identity.count } do
      assert registration.save
    end

    assert_equal existing, registration.identity
  end

  test "validates email format" do
    registration = Registration.new(email: "invalid")
    assert_not registration.valid?
    assert_includes registration.errors[:email], "is invalid"
  end
end
```

### 11.3 Integration Tests

```ruby
# test/integration/registration_flow_test.rb
require "test_helper"

class RegistrationFlowTest < ActionDispatch::IntegrationTest
  test "complete registration flow" do
    # Start registration
    get new_registration_path
    assert_response :success

    # Submit email
    post registrations_path, params: {
      registration: { email: "test@example.com" }
    }
    assert_redirected_to verify_registration_path

    # Get magic link code (from email in test)
    mail = ActionMailer::Base.deliveries.last
    code = extract_code_from(mail)

    # Verify code
    post verify_registration_path, params: { code: code }
    assert_redirected_to complete_registration_path

    # Complete profile
    patch complete_registration_path, params: {
      registration: {
        name: "Test User",
        company_name: "Test Company"
      }
    }
    assert_redirected_to dashboard_path

    # Verify logged in
    get dashboard_path
    assert_response :success
    assert_select "h1", "Welcome, Test User"
  end
end
```

---

## Quick Reference

| Pattern | When to Use | Example |
|---------|-------------|---------|
| **Concern** | Share behavior across models | `User::Named`, `Trackable` |
| **Current Attributes** | Request-scoped context | `Current.user`, `Current.account` |
| **Form Object** | Multi-model forms, complex validation | `Registration`, `Signup` |
| **Service Object** | Complex business operations | `OrderProcessor`, `BillingService` |
| **Value Object** | Immutable domain concepts | `Money`, `DateRange`, `Address` |
| **Query Object** | Complex, reusable queries | `Articles::SearchQuery` |
| **Custom Type** | Automatic serialization | `MoneyType`, `UuidType` |
| **Factory Method** | Complex object creation | `Account.create_with_owner` |
| **Scopes** | Reusable query fragments | `published`, `recent`, `by_author` |
| **Nested Classes** | Tightly coupled subordinates | `Subscription::Invoice` |

---

## Final Guidelines

1. **Start simple** — Don't over-engineer. Extract patterns when complexity demands it.

2. **Name things well** — Clear names reduce the need for documentation.

3. **Keep models focused** — If a model file exceeds 200 lines, consider extracting concerns.

4. **Test behavior, not implementation** — Focus on what the code does, not how it does it.

5. **Prefer composition** — Build complex behavior from simple, tested pieces.

6. **Make dependencies explicit** — Avoid hidden globals and implicit state.

7. **Document the why** — Code shows *what*; comments should explain *why*.
