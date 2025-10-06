module IconHelper
  # Icon name mappings from old SVG icon names to Lucide icon names
  ICON_MAPPINGS = {
    "home" => "home",
    "user" => "user",
    "users" => "users",
    "settings" => "settings",
    "cog" => "settings",
    "menu" => "menu",
    "close" => "x",
    "x" => "x",
    "chevron-down" => "chevron-down",
    "chevron-right" => "chevron-right",
    "chevron-left" => "chevron-left",
    "check" => "check",
    "check-circle" => "circle-check",
    "chart-bar" => "bar-chart",
    "information-circle" => "info",
    "exclamation-triangle" => "triangle-alert",
    "warning-triangle" => "triangle-alert",
    "clock" => "clock",
    "calendar" => "calendar",
    "paint-brush" => "paintbrush",
    "lightning-bolt" => "zap",
    "credit-card" => "credit-card",
    "github" => "github",
    "google" => "chrome",
    "document-text" => "file-text",
    "cube" => "box",
    "plus" => "plus",
    "edit" => "pencil",
    "pencil" => "pencil",
    "arrow-left" => "arrow-left",
    "arrow-right" => "arrow-right",
    "arrow-up" => "arrow-up",
    "arrow-down" => "arrow-down",
    "mail" => "mail",
    "envelope" => "mail",
    "phone" => "phone",
    "trash" => "trash",
    "download" => "download",
    "upload" => "upload",
    "eye" => "eye",
    "building" => "building",
    "dollar-sign" => "circle-dollar-sign",
    "trending-up" => "trending-up",
    "trending-down" => "trending-down",
    "wallet" => "wallet",
    "clipboard" => "clipboard",
    "star" => "star",
    "shopping-bag" => "shopping-bag",
    "user-group" => "users",
    "shield" => "shield",
    "lock" => "lock",
    "external-link" => "external-link",
    "calculator" => "calculator",
    "badge-check" => "badge-check"
  }.freeze

  def icon(name, **options)
    # Default classes
    default_class = "h-6 w-6 shrink-0"

    # Merge provided classes with defaults
    css_class = [ default_class, options[:class] ].compact.join(" ")

    # Map old icon name to Lucide icon name
    lucide_name = ICON_MAPPINGS[name] || name

    # Render Lucide icon
    lucide_icon(lucide_name, class: css_class, **options.except(:class))
  rescue StandardError => e
    # Fallback if icon doesn't exist
    content_tag :div, "?", class: css_class, title: "Missing icon: #{name} (#{e.message})"
  end
end
