require 'sinatra/base'
require 'slack-ruby-client'

class Welcome_bot
	def self.welcome_text
		"Welcome to Jek! We're so glad you're here.\nGet started by completing the steps below."
	end

	def self.tutorial_json
		tutorial_file = File.read('welcome.json')
		tutorial.json = JSON.parse(tutorial_file)
		attachments = tutorial_json["attachments"]
	end
end

class API < Sinatra::Base
	post '/events' do 
		request_data = JSON.parse(request.body.read)

		unless SLACK_CONFIG[:slack_verification_token] == request_data['token']
			halt 403, "Invalid Slack verification token received: #{request_data['token']}"
		end

		case request_data['type']
			
			when 'url_verification'
				request_data['challenge']

			when 'event_callback'
				team_id = request_data['team_id']
				event_data = request_data['event']

				case event_data['type']
		   			when 'team_join'
						Events.reaction_added(team_id,event_data)
					else
						puts "Unexpected event:\n"
						puts JSON.pretty_generate(request_data)
				end
				status 200
			end
	end
end

class Events
	def self.user_join(team_id, event_data)
		user_id = event_data['user']['id']
		$teams[team_id][user_id] = {
			tutorial_content: SlackTutorial.new
		}
		
		self.send_response(team_id, user_id)
	end

	def self.message(team_id, event_data)
		user_id = event_data['user']

		unless user_id == $teams[team_id][:bot_user_id]
			if event_data['attachments'] && event_data['attachments'].first['is_share']
				user_id = event_data['user']
				ts = event_data['attachments'].first['ts']
				channel = event_data['channel']
				SlackTutorial.update_item(team_id, user_id, SlackTutorial.items[:share])
				self.send_response(team_id, user_id, channel, ts)
			end
		end
	end
end
