module IconHelper
  def icon(name, **options)
    # Default classes
    default_class = "h-6 w-6 shrink-0"

    # Merge provided classes with defaults
    options[:class] = [ default_class, options[:class] ].compact.join(" ")

    # Render the icon partial
    render partial: "shared/icons/#{name}", locals: options
  rescue ActionView::MissingTemplate
    # Fallback if icon doesn't exist
    content_tag :div, "?", class: options[:class], title: "Missing icon: #{name}"
  end
end
