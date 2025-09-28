class ReferralReward < ApplicationRecord
  belongs_to :referrer, class_name: "User"
  belongs_to :referee, class_name: "User"

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending available used expired] }
  validates :subscription_id, presence: true
  validates :earned_at, presence: true

  scope :available, -> { where(status: "available") }
  scope :used, -> { where(status: "used") }
  scope :pending, -> { where(status: "pending") }
  scope :expired, -> { where(status: "expired") }

  def amount_dollars
    amount / 100.0
  end

  def mark_as_available!
    update!(status: "available")
  end

  def mark_as_used!(used_at: Time.current, notes: nil)
    update!(status: "used", used_at: used_at, notes: notes)
  end

  def mark_as_expired!
    update!(status: "expired")
  end

  def available?
    status == "available"
  end

  def used?
    status == "used"
  end

  def pending?
    status == "pending"
  end

  def expired?
    status == "expired"
  end
end
