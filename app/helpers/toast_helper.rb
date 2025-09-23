module ToastHelper
  def toast_border_color(type)
    case type.to_s
    when 'success', 'notice'
      'border-green-400'
    when 'error', 'alert'
      'border-red-400'
    when 'warning'
      'border-yellow-400'
    when 'info'
      'border-blue-400'
    else
      'border-gray-400'
    end
  end

  def toast_title_color(type)
    case type.to_s
    when 'success', 'notice'
      'text-green-800'
    when 'error', 'alert'
      'text-red-800'
    when 'warning'
      'text-yellow-800'
    when 'info'
      'text-blue-800'
    else
      'text-gray-800'
    end
  end

  def toast_text_color(type)
    case type.to_s
    when 'success', 'notice'
      'text-green-700'
    when 'error', 'alert'
      'text-red-700'
    when 'warning'
      'text-yellow-700'
    when 'info'
      'text-blue-700'
    else
      'text-gray-700'
    end
  end

  def toast_progress_color(type)
    case type.to_s
    when 'success', 'notice'
      'bg-green-200'
    when 'error', 'alert'
      'bg-red-200'
    when 'warning'
      'bg-yellow-200'
    when 'info'
      'bg-blue-200'
    else
      'bg-gray-200'
    end
  end

  def toast_progress_bg_color(type)
    case type.to_s
    when 'success', 'notice'
      'bg-green-500'
    when 'error', 'alert'
      'bg-red-500'
    when 'warning'
      'bg-yellow-500'
    when 'info'
      'bg-blue-500'
    else
      'bg-gray-500'
    end
  end

  def render_flash_toasts
    content = ""
    flash.each do |type, message|
      next if message.blank?

      content += render('shared/toast', type: type, message: message)
    end
    content.html_safe
  end
end