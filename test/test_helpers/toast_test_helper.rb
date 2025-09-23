module ToastTestHelper
  # Test for toast notifications by checking flash messages
  # This is more reliable than testing DOM elements since toasts are dynamic
  def assert_flash(type, message_pattern = nil)
    assert flash[type.to_sym].present?, "Expected flash[#{type}] to be present, but it was #{flash[type.to_sym].inspect}"

    if message_pattern
      if message_pattern.is_a?(Regexp)
        assert_match message_pattern, flash[type.to_sym],
          "Expected flash[#{type}] '#{flash[type.to_sym]}' to match pattern #{message_pattern}"
      else
        assert_includes flash[type.to_sym], message_pattern.to_s,
          "Expected flash[#{type}] '#{flash[type.to_sym]}' to include '#{message_pattern}'"
      end
    end
  end

  # Specific helpers for common flash types
  def assert_notice(message_pattern = nil)
    assert_flash(:notice, message_pattern)
  end

  def assert_alert(message_pattern = nil)
    assert_flash(:alert, message_pattern)
  end

  def assert_success(message_pattern = nil)
    assert_flash(:notice, message_pattern)
  end

  def assert_error(message_pattern = nil)
    assert_flash(:alert, message_pattern)
  end

  def assert_warning(message_pattern = nil)
    assert_flash(:warning, message_pattern)
  end

  def assert_info(message_pattern = nil)
    assert_flash(:info, message_pattern)
  end

  # Check that a toast notification would be rendered in the HTML
  # This tests the actual toast HTML structure
  def assert_toast_present(type, message_pattern = nil)
    # Check that the toast helper would render the flash
    assert_flash(type, message_pattern)

    # Check that the toast HTML contains the expected structure
    toast_html = render("shared/toast", type: type, message: flash[type.to_sym])
    assert_includes toast_html, 'data-controller="toast"'
    assert_includes toast_html, "data-toast-type-value=\"#{type}\""

    if message_pattern
      if message_pattern.is_a?(Regexp)
        assert_match message_pattern, toast_html
      else
        assert_includes toast_html, message_pattern.to_s
      end
    end
  end

  # Test that no flash message of a specific type exists
  def assert_no_flash(type)
    assert flash[type.to_sym].blank?, "Expected no flash[#{type}], but found: #{flash[type.to_sym].inspect}"
  end

  def assert_no_notice
    assert_no_flash(:notice)
  end

  def assert_no_alert
    assert_no_flash(:alert)
  end

  # Helper to render toast partials in tests
  def render_toast(type, message)
    flash[type.to_sym] = message
    render("shared/toast", type: type, message: message)
  end

  # System test helpers for actual DOM interaction
  def assert_toast_displayed(message_pattern)
    if message_pattern.is_a?(Regexp)
      assert_selector '[data-controller="toast"]', text: message_pattern
    else
      assert_text message_pattern
      assert_selector '[data-controller="toast"]'
    end
  end

  def assert_toast_dismissed
    assert_no_selector '[data-controller="toast"]'
  end

  def dismiss_toast
    find('[data-action="click->toast#dismiss"]').click
  end
end
