json.array!(@scenarios) do |scenario|
  json.extract! scenario, :id, :name
  json.url scenario_url(scenario, format: :json)
end
