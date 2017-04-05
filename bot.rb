require 'sinatra/base'
require 'slack-ruby-client'

class Welcome_bot
  class << self
    def welcome_text
      "Welcome to Jek! We're so glad you're here.\nGet started by completing the steps below."
    end

    def questions_json
      tutorial_file = File.read('welcome.json')
      tutorial_json = JSON.parse(tutorial_file)
      attachments = tutorial_json["attachments"]
    end

    def items
      {reaction: 0, pin: 1, share: 2}
    end

    def new
      self.tutorial_json.deep_dup
    end

    def update_item(team_id,user_id, item_index)
      puts "JAAAAA"
      tutorial_item = $teams[team_id][user_id][:tutorial_content][item_index]
      tutorial_item['text'].sub!(':white_large_square:', ':white_check_mark:')
      tutorial_item['color'] = '#439FE0'
    end
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
						Events.user_join(team_id, event_data)
          when 'reaction_added'
            Events.reaction_added(team_id, event_data)
      		else
						puts "Unexpected event:\n"
						puts JSON.pretty_generate(request_data)
				end
				status 200
			end
	end
end

class Events
  class << self
    def user_join(team_id, event_data)
      user_id = event_data['user']['id']
      $teams[team_id][user_id] = {
        tutorial_content: Welcome_bot.new
      }
      send_response(team_id, user_id)
    end

    def reaction_added(team_id, event_data)
      user_id = event_data['user']
      puts "@@@@@@@@@@@@@@@@@"
      puts event_data
      puts "##########"
      puts $teams
      puts "##########"
      puts user_id
      if $teams[team_id][user_id]
        puts "#########"
        channel = event_data['item']['channel']
        ts = event_data['item']['ts']
        Welcome_bot.update_item(team_id, user_id, Welcome_bot.items[:reaction])
        send_response(team_id, user_id, channel, ts)
      end
    end

    def send_response(team_id, user_id, channel = user_id, ts = nil)
      if ts
        $teams[team_id]['client'].chat_update(
          as_user: 'true',
          channel: channel,
          ts: ts,
          text: Welcome_bot.welcome_text,
          attachments: $teams[team_id][user_id][:tutorial_content]
        )
      else
        $teams[team_id]['client'].chat_postMessage(
          as_user: 'true',
          channel: channel,
          text: Welcome_bot.welcome_text,
          attachments: $teams[team_id][user_id][:tutorial_content]
        )
      end
    end
  end
end
