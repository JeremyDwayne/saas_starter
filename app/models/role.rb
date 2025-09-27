class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def has_permission?(permission_name)
    permissions.exists?(name: permission_name)
  end

  def has_permission_for?(resource, action)
    permissions.exists?(resource: resource, action: action)
  end
end
