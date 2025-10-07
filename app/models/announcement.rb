class Announcement < ApplicationRecord
  # Enums
  enum :announcement_type, { new_feature: 0, update: 1, improvement: 2, fix: 3 }, prefix: :type

  # Validations
  validates :title, presence: true
  validates :body, presence: true
  validates :announcement_type, presence: true

  # Scopes
  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :unpublished, -> { where(published_at: nil).or(where("published_at > ?", Time.current)) }
  scope :recent, -> { order(published_at: :desc, created_at: :desc) }

  # Check if announcement is published
  def published?
    published_at.present? && published_at <= Time.current
  end

  # Publish the announcement
  def publish!
    update!(published_at: Time.current) unless published?
  end

  # Color for badge based on type
  def badge_color
    case announcement_type
    when "new_feature"
      "bg-green-100 text-green-800"
    when "update"
      "bg-blue-100 text-blue-800"
    when "improvement"
      "bg-purple-100 text-purple-800"
    when "fix"
      "bg-orange-100 text-orange-800"
    end
  end

  # Human-readable type label
  def type_label
    case announcement_type
    when "new_feature"
      "New"
    when "update"
      "Update"
    when "improvement"
      "Improvement"
    when "fix"
      "Fix"
    end
  end
end
