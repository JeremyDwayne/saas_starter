# frozen_string_literal: true

require "rubocop"

module Cops
  class OnlyAtomicMigrations < RuboCop::Cop::Base
    MSG = "Multiple operations in a single migration are not allowed. Use change_table with `bulk: true` if making multiple changes to one table, or use multiple migrations if changing multiple tables."

    def_node_matcher :migration_creation_method?, <<~PATTERN
      {:create_join_table :create_table}
    PATTERN

    def_node_matcher :migration_modification_method?, <<~PATTERN
      {:add_column :add_index :add_timestamps :add_foreign_key :add_reference :change_column :change_column_default :change_column_null :change_table :rename_column :rename_index :rename_table}
    PATTERN

    def_node_matcher :migration_deletion_method?, <<~PATTERN
      {:drop_table :drop_join_table :remove_column :remove_columns :remove_foreign_key :remove_index :remove_reference :remove_timestamps}
    PATTERN

    def_node_matcher :migration_method?, <<~PATTERN
      {#migration_creation_method? #migration_modification_method? #migration_deletion_method?}
    PATTERN

    def_node_search :migration_operations, <<~PATTERN
      $(send nil? #migration_method? ...)
    PATTERN

    def_node_matcher :change_table_options, <<~PATTERN
      (send nil? :change_table sym $hash ...)
    PATTERN

    def_node_search :has_bulk_true?, <<~PATTERN
      (pair (sym :bulk) true)
    PATTERN

    def_node_matcher :change_table_method?, <<~PATTERN
      {:primary_key :column :index :rename_index :timestamps :change :change_default :change_null :rename :references :belongs_to :check_constraint :string :text :integer :bigint :float :decimal :numeric :datetime :timestamp :time :date :binary :boolean :foreign_key :json :virtual :remove :remove_foreign_key :remove_references :remove_belongs_to :remove_index :remove_check_constraint :remove_timestamps}
    PATTERN

    def_node_matcher :change_table_argument, <<~PATTERN
      (args (arg $_))
    PATTERN

    def_node_matcher :change_table_args_block, <<~PATTERN
      (block send $args ${begin send})
    PATTERN

    def_node_search :change_table_ops, <<~PATTERN
      $(send (lvar %1) #change_table_method? ...)
    PATTERN

    def on_def(node)
      ops = migration_operations(node).to_a
      ops.each do |op|
        if op.method_name == :change_table
          options = change_table_options(op)
          if !options || !has_bulk_true?(options)
            args, block = change_table_args_block(op.parent)
            arg_name = change_table_argument(args)
            change_table_ops = change_table_ops(block, arg_name).to_a
            if change_table_ops.size + ops.size - 1 > 1 # ops inside change_table block + ops outside change_table block - change_table block
              change_table_ops.each { |op| add_offense(op) }
            end
          end
        end
        if ops.size > 1
          add_offense(op)
        end
      end
    end
  end
end
