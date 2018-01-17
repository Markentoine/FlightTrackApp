require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'FileUtils'

class FlightTrackApp < Sinatra::Application

  get '/' do
    redirect '/FlightTrackApp'
  end

  get '/FlightTrackApp' do
    erb :layout
  end
end
