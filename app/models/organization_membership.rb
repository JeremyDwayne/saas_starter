class OrganizationMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :organization

  # Enums
  enum :role, { admin: 0, member: 1 }, default: :member

  # Validations
  validates :user_id, uniqueness: { scope: :organization_id }
end
