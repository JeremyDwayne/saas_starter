class RolePermission < ApplicationRecord
  belongs_to :role
  belongs_to :permission

  validates :role_id, uniqueness: { scope: :permission_id }

  # Cache invalidation - clear cache for all users with this role when permissions change
  after_commit :clear_role_users_cache

  private

  def clear_role_users_cache
    role.users.each do |user|
      user.send(:clear_role_permission_cache)
    end
  end
end
