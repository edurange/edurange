class ScenarioJob < ApplicationJob
  queue_as :scenario
  discard_on StandardError
end
