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
      # Add transactions link if user can accept payments or has onboarding started
      if Current.user&.merchant_processor.present?
        items.insert(1, {
          name: "Transactions",
          path: charges_path,
          icon: "chart-bar",
          active: current_page?(charges_path) || request.path.start_with?("/charges")
        })
      end

      # Add invoicing links if user is subscribed
      if Current.user&.on_trial_or_subscribed?
        items << {
          name: "Invoices",
          path: invoices_path,
          icon: "document-text",
          active: current_page?(invoices_path) || request.path.start_with?("/invoices")
        }
        items << {
          name: "Customers",
          path: customers_path,
          icon: "users",
          active: current_page?(customers_path) || request.path.start_with?("/customers")
        }
        items << {
          name: "Products",
          path: products_path,
          icon: "cube",
          active: current_page?(products_path) || request.path.start_with?("/products")
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
