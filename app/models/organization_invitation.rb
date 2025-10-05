class OrganizationInvitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: %w[member admin] }
  validates :status, presence: true, inclusion: { in: %w[pending accepted declined revoked] }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :valid_invitations, -> { pending.where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def accept!(user)
    return false if expired? || !pending?

    transaction do
      membership = organization.organization_memberships.create!(
        user: user,
        role: role
      )

      update!(status: "accepted")
      membership
    end
  end

  def revoke!
    update!(status: "revoked")
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end
end
