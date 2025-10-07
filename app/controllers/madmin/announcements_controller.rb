module Madmin
  class AnnouncementsController < Madmin::ResourceController
    def new
      super
      # Set to beginning of today in UTC
      @record.published_at ||= Time.current.beginning_of_day
    end
  end
end
