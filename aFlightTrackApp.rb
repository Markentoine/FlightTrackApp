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

  helpers do

  end

  get '/' do
    redirect '/FlightTrackApp'
  end

  get '/FlightTrackApp' do
    erb :landing
  end

  post '/FlightTrackApp/users/sign_in' do

  end

  post '/FlightTrackApp/users/sign_up' do

  end
end
