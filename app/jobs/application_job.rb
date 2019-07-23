class ApplicationJob < ActiveJob::Base
  include SymbolSerializer

  discard_on ActiveJob::DeserializationError do |job, error|
    logger.warn("Discarding job because of #{error.class.name}: #{error}")
  end
end
