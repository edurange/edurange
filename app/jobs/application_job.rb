
# Rails 5 adds an ApplicationJob class and reccomends jobs extend it.
# To aid in migration use this ApplicationJob class.
# When migrating to Rails 5, delete this definition.
class ApplicationJob < ActiveJob::Base
  # The version of ActiveJobs we are using does not support serializing symbols as arguments.
  include SymbolSerializer
end

