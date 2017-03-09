require 'sinatra/base'
require 'slack-ruby-client'

SLACK_CONFIG = {
	slack_client_id: ENV['2770728157.126776116850'],
	slack_api_secret: ENV['c443a77aa5ce11581c13bceeea480e6c'],
	slack_redirect_uri: ENV['https://ccd5a831.ngrok.io/finish_auth'],
	slack_verification_token: ENV['J7ZN5FGrdMj6SO6quQnJwyn2']
}

missing_params = SLACK_CONFIG.select { |key, value| value.nil? }
if missing_params.any?
	error_msg = missing_params.keys.join(", ").upcase
	raise "Missing Slack config variables: #{error_msg}"
end
