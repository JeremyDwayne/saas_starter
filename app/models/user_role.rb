class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id }

  # Cache invalidation - clear cache when user-role associations change
  after_commit :clear_user_cache

  private

  def clear_user_cache
    user.send(:clear_role_permission_cache) if user
  end
end
