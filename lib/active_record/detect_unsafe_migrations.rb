# frozen_string_literal: true

module ActiveRecord::DetectUnsafeMigrations
  include ActionView::Helpers::NumberHelper

  ROW_COUNT_LIMIT = 5_000_000
  STORE_SIZE_LIMIT = 5.gigabyte

  def exec_migration(conn, direction)
    # We need to do this so that the command recorder gets every individual change and not just the bulk "change_table" with a proc
    temp_conn = conn.pool.db_config.new_connection
    temp_conn.define_singleton_method(:supports_bulk_alter?) { false }
    recorder = ActiveRecord::Migration::CommandRecorder.new(temp_conn)
    suppress_messages { super(recorder, direction) }
    temp_conn.close

    commands = recorder.commands
    table_name = commands.map { |_, args| args.first }.first

    if commands.any? { |operation, _| operation == :execute }
      raise(
        ActiveRecord::UnsafeDirectMigration,
        error_message(
          table: table_name,
          version: version,
          direction: direction,
          reason: "`execute` is never supported in migrations without review"
        )
      )
    end

    return super(conn, direction) if ENV["FORCE_MIGRATION"] == "true" || Rails.env.development? || Rails.env.test?
    return super(conn, direction) if commands.blank?
    return super(conn, direction) if commands.any? { |operation, _| operation == :create_table }

    row_count = get_table_row_count(conn, table_name)
    store_size = get_table_size(conn, table_name)

    if commands.any? { |operation, _| operation == :drop_table } && row_count >= 2000
      self.instance_eval <<~RUBY
        def change
          execute "ALTER TABLE #{quote_table_name(table_name)} RENAME TO #{quote_table_name("_#{version}_#{table_name}_del")}"
        end
      RUBY
      return super(conn, direction)
    end

    if commands.any? { |operation, _| operation == :change_column } && row_count >= 2000
      raise(
        ActiveRecord::UnsafeDirectMigration,
        error_message(
          table: table_name,
          version: version,
          direction: direction,
          reason: "change_column is no longer supported for in-place migrations on large tables"
        )
      )
    end

    if row_count >= ROW_COUNT_LIMIT || store_size >= STORE_SIZE_LIMIT
      raise(
        ActiveRecord::UnsafeDirectMigration,
        error_message(
          table: table_name,
          version: version,
          direction: direction,
          reason: unsafe_migration_reason(table_name, row_count, store_size)
        )
      )
    end

    super(conn, direction)
  end

  private def unsafe_migration_reason(table_name, row_count, store_size)
    return "`#{table_name}` is estimated to have #{number_to_human(row_count).downcase} rows which is greater than the cutoff limit of #{number_to_human(ActiveRecord::DetectUnsafeMigrations::ROW_COUNT_LIMIT).downcase}" if row_count >= ROW_COUNT_LIMIT
    "`#{table_name}` is estimated to occupy #{number_to_human_size(store_size)} which is greater than the cutoff limit of #{number_to_human_size(ActiveRecord::DetectUnsafeMigrations::STORE_SIZE_LIMIT)}" if store_size >= STORE_SIZE_LIMIT
  end

  private def get_table_row_count(conn, table)
    return 0 unless table_exists?(conn, table)

    if sqlite_connection?(conn)
      # SQLite doesn't have EXPLAIN like MySQL, so we use a different approach
      # For development, we can do a quick count or use ANALYZE statistics
      result = conn.exec_query("SELECT COUNT(*) as count FROM #{conn.quote_table_name(table)}")
      result.first["count"] || 0
    else
      # For other databases (MySQL, PostgreSQL), use EXPLAIN or similar
      conn.exec_query("EXPLAIN SELECT COUNT(*) FROM #{conn.quote_table_name(table)}").to_a.first&.dig("rows") || 0
    end
  rescue ActiveRecord::StatementInvalid
    # If table doesn't exist or query fails, assume it's safe
    0
  end

  private def get_table_size(conn, table)
    return 0 unless table_exists?(conn, table)

    if sqlite_connection?(conn)
      # SQLite approach: use page_count * page_size for approximate size
      begin
        page_size = conn.exec_query("PRAGMA page_size").first["page_size"] || 4096
        page_count_result = conn.exec_query("SELECT COUNT(*) as page_count FROM pragma_page_count('#{table}')")
        page_count = page_count_result.first["page_count"] || 0
        page_size * page_count
      rescue ActiveRecord::StatementInvalid
        # Fallback: estimate based on row count
        row_count = get_table_row_count(conn, table)
        row_count * 100 # Rough estimate: 100 bytes per row
      end
    else
      # MySQL/PostgreSQL approach using information_schema
      query_result = conn.exec_query(<<~SQL.squish)
        SELECT (data_length + index_length) AS size
        FROM information_schema.tables
        WHERE table_schema = '#{conn.current_database}'
          AND table_name = '#{table}'
      SQL

      row = query_result.to_a.first
      row.present? ? row["size"] : 0
    end
  rescue ActiveRecord::StatementInvalid
    # If query fails, assume it's safe
    0
  end

  private def table_exists?(conn, table)
    conn.table_exists?(table)
  end

  private def sqlite_connection?(conn)
    conn.adapter_name.downcase.include?("sqlite")
  end

  private def error_message(table:, version:, direction:, reason:)
    <<~MESSAGE
      Direct #{direction} migration #{version} of table `#{table}` is unsafe!
      Reason: #{reason}.

      To bypass this check in development, set FORCE_MIGRATION=true
      For production deployments, consider using online migration tools.
    MESSAGE
  end
end

class ActiveRecord::UnsafeDirectMigration < ActiveRecord::ActiveRecordError; end
