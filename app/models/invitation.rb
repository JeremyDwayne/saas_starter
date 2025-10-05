class Invitation < ApplicationRecord
  # Token generation
  has_secure_token

  # Associations
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  # Enums
  enum :role, { admin: 0, member: 1 }, default: :member

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :token, presence: true, uniqueness: true

  # Accept invitation and create membership
  def accept!(user)
    ActiveRecord::Base.transaction do
      OrganizationMembership.create!(
        user: user,
        organization: organization,
        role: role
      )
      destroy!
    end
  end

  # Use token in URLs
  def to_param
    token
  end
end
