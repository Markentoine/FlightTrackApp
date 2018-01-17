require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

class FlightTrackApp < Sinatra::Application

  get '/' do
    'ok'
  end
end
