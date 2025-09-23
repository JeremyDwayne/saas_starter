Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development? || Rails.env.test?
  provider :google_oauth2, Rails.application.credentials.dig(:auth, :google, :client_id), Rails.application.credentials.dig(:auth, :google, :secret)
  provider :github, Rails.application.credentials.dig(:auth, :github, :client_id), Rails.application.credentials.dig(:auth, :github, :secret), scope: "user:email"
end
