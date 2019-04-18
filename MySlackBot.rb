$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'SlackBot'

mention = "@matsubot"

class MySlackBot < SlackBot
    #<string>と言ってをパース
    def parrot(str)
        idx_say = str.rindex("と言って")
        return str.slice(0..(idx_say - 1))
    end
end

slackbot = MySlackBot.new

set :environment, :production

get '/' do
  "SlackBot Server"
end

post '/slack' do
    content_type :json
    str = params[:text]
    if str.start_with?(mention)
        instruction = str.slice(mention.length..-1)
        params[:text] = slackbot.parrot(instruction)
        slackbot.post_message(params[:text], username: "Matsubot")
    end
end
