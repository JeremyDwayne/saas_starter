class Organization < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :organization_invitations, dependent: :destroy

  # Business data associations
  has_many :merchant_customers, dependent: :destroy
  has_many :merchant_products, dependent: :destroy
  has_many :merchant_invoices, dependent: :destroy
  has_many :platform_transactions, dependent: :destroy
  has_many :custom_platform_fees, dependent: :destroy

  # Pay gem - subscriptions and Connect accounts
  pay_customer stripe_attributes: ->(pay_customer) { { metadata: { organization_id: pay_customer.owner_id } } }
  pay_merchant

  # Validations
  validates :name, presence: true
  validates :slug, uniqueness: true, allow_nil: true

  # Callbacks
  before_validation :generate_slug, on: :create

  private

  def generate_slug
    return if slug.present?

    base_slug = name.to_s.parameterize
    candidate_slug = base_slug
    counter = 1

    while Organization.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
