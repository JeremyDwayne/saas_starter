module Madmin
  class DashboardController < Madmin::ApplicationController
    def show
      @metrics = BusinessMetricsService.new.call
    end
  end
end
