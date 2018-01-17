require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'FileUtils'

class FlightTrackApp < Sinatra::Application

  configure do
    enable :sessions
    enable :secret_sessions, 'not a good secret'
    enable :erb, escape_html: true
  end

  get '/' do
    redirect '/FlightTrackApp'
  end

  get '/FlightTrackApp' do
    erb :layout
  end
end
