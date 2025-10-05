class Current < ActiveSupport::CurrentAttributes
  attribute :session, :organization, :membership

  delegate :user, to: :session, allow_nil: true

  # Get the user's role in the current organization
  # @return [Symbol, nil] The role (:owner, :admin, :member) or nil
  def role
    membership&.role
  end

  # Check if user is an owner of the current organization
  # @return [Boolean]
  def owner?
    role == :owner || organization&.owner_id == user&.id
  end

  # Check if user is an admin (or higher) in the current organization
  # @return [Boolean]
  def admin?
    owner? || role == :admin
  end

  # Check if user is a member (any role) in the current organization
  # @return [Boolean]
  def member?
    membership.present?
  end
end
