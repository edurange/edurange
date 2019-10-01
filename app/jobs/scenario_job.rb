class ScenarioJob < ApplicationJob
  queue_as :scenario
  # we don't want to repeat starting/stopping a scenario if it fails.
  discard_on StandardError
end
