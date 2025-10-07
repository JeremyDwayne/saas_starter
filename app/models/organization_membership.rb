class OrganizationMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :organization

  # Enums
  enum :role, { admin: 0, member: 1 }, default: :member

  # Validations
  validates :user_id, uniqueness: { scope: :organization_id }

  # Cache invalidation
  after_commit :clear_user_organization_cache

  private

  def clear_user_organization_cache
    return unless user&.persisted?
    user.send(:clear_organization_cache)
  rescue => e
    Rails.logger.debug "Failed to clear organization cache for user #{user&.id}: #{e.message}"
  end
end
