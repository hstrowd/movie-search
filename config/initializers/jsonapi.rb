# frozen_string_literal: true

JSONAPI.configure do |config|
  config.json_key_format = :underscored_key
  config.route_format = :underscored_route
end
