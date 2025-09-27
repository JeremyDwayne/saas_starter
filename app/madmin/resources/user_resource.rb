class UserResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :avatar_url
  attribute :created_at, form: false
  attribute :email_address
  attribute :name
  attribute :updated_at, form: false
  attribute :password, index: false, show: false
  attribute :password_confirmation, index: false, show: false

  # Associations
  attribute :sessions
  attribute :omni_auth_identities
  attribute :pay_customers
  attribute :pay_charges
  attribute :pay_subscriptions
  attribute :payment_processor
  attribute :pay_merchants
  attribute :merchant_processor

  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
