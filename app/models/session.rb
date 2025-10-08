class Session < ApplicationRecord
  belongs_to :user
  belongs_to :impersonator, class_name: "User", optional: true

  # Check if this session is impersonating anyone
  # @return [Boolean]
  def impersonating?
    impersonating_user? || impersonating_role?
  end

  # Check if this session is impersonating a specific user
  # @return [Boolean]
  def impersonating_user?
    impersonator_id.present?
  end

  # Check if this session is impersonating a role
  # @return [Boolean]
  def impersonating_role?
    impersonated_role.present?
  end
end
