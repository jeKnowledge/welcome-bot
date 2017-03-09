require './auth'
require './bot'

run Rack::Cascade.new [API, Auth]
