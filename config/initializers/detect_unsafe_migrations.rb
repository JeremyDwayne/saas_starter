# frozen_string_literal: true

# Load the unsafe migration detection module
require Rails.root.join("lib/active_record/detect_unsafe_migrations")

# Apply the module to ActiveRecord::Migration
ActiveRecord::Migration.prepend(ActiveRecord::DetectUnsafeMigrations)

Rails.logger.info "Unsafe migration detection enabled" if Rails.logger
