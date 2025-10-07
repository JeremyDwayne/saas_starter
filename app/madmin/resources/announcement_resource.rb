class AnnouncementResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :title
  attribute :body, index: false
  attribute :announcement_type
  attribute :published_at
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Scopes
  scope :all
  scope :published
  scope :unpublished
end
