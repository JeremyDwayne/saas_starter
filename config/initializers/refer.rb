# Refer gem configuration
Rails.application.config.to_prepare do
  # Make Refer model classes available at the top level
  # The gem's main module expects ReferralCode and Referral without namespace
  unless defined?(ReferralCode)
    ReferralCode = Refer::ReferralCode
  end

  unless defined?(Referral)
    Referral = Refer::Referral
  end
end
