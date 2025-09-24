# OmniAuth test configuration
if Rails.env.test?
  # Disable CSRF protection in test environment
  OmniAuth.config.test_mode = true

  # Configure test mode to skip CSRF
  OmniAuth.config.request_validation_phase = nil
  OmniAuth.config.allowed_request_methods = [ :get, :post ]

  # Set up mock auth hash for tests
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: "google_oauth2",
    uid: "123456789",
    info: {
      email: "test@example.com",
      name: "Test User"
    }
  })

  OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
    provider: "github",
    uid: "987654321",
    info: {
      email: "github_user@example.com",
      name: "GitHub User"
    }
  })
end
