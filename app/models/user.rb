class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :omni_auth_identities, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }
  validates :password, on: [ :registration, :password_change ],
            presence: true,
            length: { minimum: 8, maximum: 72 }
  validates :password_confirmation, on: [ :registration, :password_change ],
            presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.create_from_oauth(auth)
    email = auth.info.email
    user = self.new email_address: email, password: SecureRandom.base64(64).truncate_bytes(64)
    # TODO: you could save additional information about the user from the OAuth sign in
    # assign_names_from_auth(auth, user)

    # Save without validation context (password validations won't apply)
    user.save
    user
  end

  def signed_in_with_oauth(auth)
    # TODO: same as above, you could save additional information about the user
    # User.assign_names_from_auth(auth, self)
    # save if first_name_changed? || last_name_changed?
  end
end
