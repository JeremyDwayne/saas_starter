class Current < ActiveSupport::CurrentAttributes
  attribute :session, :organization, :membership

  delegate :user, to: :session, allow_nil: true

  # Get the impersonator user (the real admin user)
  # @return [User, nil]
  def impersonator
    return nil unless session&.impersonating_user?
    session.impersonator
  end

  # Get the impersonated role (if impersonating a role without a user)
  # @return [String, nil]
  def impersonated_role
    session&.impersonated_role
  end

  # Check if currently impersonating
  # @return [Boolean]
  def impersonating?
    session&.impersonating? || false
  end

  # Get the user's role in the current organization
  # Checks impersonated_role first if impersonating
  # @return [Symbol, nil] The role (:owner, :admin, :member) or nil
  def role
    # If impersonating a role, return that role
    return impersonated_role.to_sym if impersonated_role.present?

    membership&.role
  end

  # Check if user is an owner of the current organization
  # @return [Boolean]
  def owner?
    # If impersonating a role, check if it's owner
    return true if impersonated_role == "owner"

    role == :owner || organization&.owner_id == user&.id
  end

  # Check if user is an admin (or higher) in the current organization
  # @return [Boolean]
  def admin?
    # If impersonating a role, check if it's admin or owner
    return true if [ "admin", "owner" ].include?(impersonated_role)

    owner? || role == :admin
  end

  # Check if user is a member (any role) in the current organization
  # @return [Boolean]
  def member?
    # If impersonating a role, always true
    return true if impersonated_role.present?

    membership.present?
  end
end
