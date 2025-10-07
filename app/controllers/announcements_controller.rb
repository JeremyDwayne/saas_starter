class AnnouncementsController < ApplicationController
  allow_unauthenticated_access

  def index
    @announcements = Announcement.published.recent.page(params[:page]).per(12)
  end

  def show
    @announcement = Announcement.published.find_by!(id: params[:id])
  end
end
