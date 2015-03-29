require "bundler"
Bundler.require

use Rack::Deflater
use Rack::Csrf

enable :sessions
set :haml, format: :html5
set :scss, style: :compact

set :bind, "0.0.0.0"
set :session_secret,          ENV["SESSION_SECRET_KEY"]
set :slack_invite_api_url,    "https://slack.com/api/users.admin.invite"
set :team_name,               ENV.fetch("SLACK_TEAM_NAME", "Team Name")
set :team_desc,               ENV.fetch("SLACK_TEAM_DESC", "Your Team description is here.")

helpers do
  def invite_request_to_slack
    response = Excon.post(settings.slack_invite_api_url,
                body: URI.encode_www_form(
                        token: ENV["SLACK_TOKEN"],
                        email: @email,
                        set_active: true
                      ),
                headers: { "Content-Type" => "application/x-www-form-urlencoded" })
    @result = response.status == 200 && MultiJson.load(response.body)["ok"]
    logger.info { response.body } unless @result
    @result
  end
end

get("/application.css") { scss :"stylesheets/application" }

get "/" do
  haml :index
end

post "/invite" do
  @email = params[:email]
  @result = invite_request_to_slack
  haml :invite
end
