require 'sinatra/base'
require 'slack-ruby-client'

SLACK_CONFIG = {
  slack_client_id: '2770728157.126776116850',
  slack_api_secret: 'c443a77aa5ce11581c13bceeea480e6c',
  slack_redirect_uri: 'https://98674d4a.ngrok.io/finish_auth', 
  slack_verification_token: 'J7ZN5FGrdMj6SO6quQnJwyn2',
}

missing_params = SLACK_CONFIG.select { |_, value| value.nil? }
if missing_params.any?
  error_msg = missing_params.keys.join(", ").upcase
  raise "Missing Slack config variables: #{error_msg}"
end

BOT_SCOPE = 'bot'

$teams = {}

def create_slack_client(slack_api_secret)
  Slack.configure do  |config|
    config.token = slack_api_secret
    fail 'Missing API token' unless config.token
  end
  Slack::Web::Client.new
end

class Auth < Sinatra::Base
  SLACK_BUTTON = %(
    <a href="https://slack.com/oauth/authorize?scope=#{BOT_SCOPE}&client_id=#{SLACK_CONFIG[:slack_client_id]}&redirect_uri=#{SLACK_CONFIG[:redirect_uri]}\">
      <img alt=\"Add to Slack\" height=\"40\" width=\"139\" src=\"https://platform.slack-edge.com/img/add_to_slack.png\"/>
    </a>
  )

  get '/' do
    redirect '/begin_auth'
  end

  get '/begin_auth' do
    status 200
    body SLACK_BUTTON
  end

  get '/finish_auth' do
    client = Slack::Web::Client.new

    begin 
      response = client.oauth_access(
        {
          client_id: SLACK_CONFIG[:slack_client_id],
          client_secret: SLACK_CONFIG[:slack_api_secret],
          redirect_uri: SLACK_CONFIG[:slack_redirect_uri],
          code: params[:code]
        }
      )
      team_id = response['team_id']
      $teams[team_id] = {
        user_access_token: response['access_token'],
        bot_user_id: response['bot']['bot_user_id'],
        bot_access_token: response['bot']['bot_access_token']
      }

      $teams[team_id]['client'] = create_slack_client(response['bot']['bot_access_token'])

      status 200
      body "Yay! Auth succeeded! You're awesome!"
    rescue Slack::Web::Api::Error => e
      status 403
      body "Auth failed! Reason: #{e.message}<br/>#{add_to_slack_button}"
    end
  end
end
