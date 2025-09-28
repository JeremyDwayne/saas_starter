class ReferralConfiguration < ApplicationRecord
  validates :reward_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :name, presence: true
  validates :max_credits_per_referral, numericality: { greater_than: 0 }, allow_nil: true
  validates :credit_expiry_days, numericality: { greater_than: 0 }, allow_nil: true

  scope :enabled, -> { where(enabled: true) }

  def self.current
    enabled.first || new(
      reward_percentage: 10.0,
      enabled: true,
      name: "Default Configuration"
    )
  end

  def calculate_reward_amount(subscription_amount_cents)
    return 0 unless enabled?

    reward_amount = (subscription_amount_cents * (reward_percentage / 100.0)).round

    if max_credits_per_referral.present?
      [ reward_amount, max_credits_per_referral ].min
    else
      reward_amount
    end
  end

  def credits_expire?
    credit_expiry_days.present?
  end

  def credit_expiry_date(from_date = Time.current)
    return nil unless credits_expire?
    from_date + credit_expiry_days.days
  end

  def reward_percentage_display
    "#{reward_percentage}%"
  end

  def max_credits_display
    if max_credits_per_referral.present?
      "$#{max_credits_per_referral / 100.0}"
    else
      "No limit"
    end
  end

  def expiry_display
    if credit_expiry_days.present?
      "#{credit_expiry_days} days"
    else
      "No expiry"
    end
  end
end
