module SidebarHelper
  def sidebar_navigation_items
    [
      {
        name: "Dashboard",
        path: "/dashboard",
        icon: "home",
        active: current_page?("/dashboard")
      },
      {
        name: "Settings",
        path: settings_path,
        icon: "settings",
        active: current_page?(settings_path)
      }
    ].tap do |items|
      # Add billing link only if user is subscribed
      if Current.user&.subscribed?
        items << {
          name: "Billing",
          path: "/pay/subscriptions",
          icon: "credit-card",
          active: false # Pay routes don't have easy current_page check
        }
      end
    end
  end

  def sidebar_nav_item_classes(active: false)
    base_classes = "group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold transition-colors"

    if active
      "#{base_classes} bg-gray-50 text-blue-600"
    else
      "#{base_classes} text-gray-700 hover:text-blue-600 hover:bg-gray-50"
    end
  end
end
