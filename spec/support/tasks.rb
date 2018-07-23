# frozen_string_literal: true

require "rake"

# Task names or a :task meta value should be used to identify the target task,
# Example: `describe "foo:bar" do ... end`
module TaskExampleGroup
  extend ActiveSupport::Concern

  included do
    let(:task_name) { |example| example.metadata[:task] || self.class.top_level_description }
    let(:tasks) { Rake::Task }

    # Make the Rake task available as `task` in your examples:
    subject(:task) { tasks[task_name] }
  end
end

RSpec.configure do |config|
  # Tag Rake specs with `:task` metadata or put them in the spec/tasks dir
  config.define_derived_metadata(file_path: %r{/spec/lib/tasks/}) do |metadata|
    metadata[:type] = :task
  end

  config.include TaskExampleGroup, type: :task

  config.before(:suite) do
    Rails.application.load_tasks
  end
end
