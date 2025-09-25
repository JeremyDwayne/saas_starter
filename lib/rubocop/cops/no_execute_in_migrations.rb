# frozen_string_literal: true

require "rubocop"

module Cops
  class NoExecuteInMigrations < RuboCop::Cop::Base
    MSG = "Using `execute` to run arbitrary SQL in migrations is not allowed. Use ActiveRecord migration methods instead."

    def_node_matcher :execute_call?, <<~PATTERN
      (send nil? :execute ...)
    PATTERN

    def on_send(node)
      return unless execute_call?(node)

      add_offense(node)
    end
  end
end
