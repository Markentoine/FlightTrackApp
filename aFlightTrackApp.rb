require 'bcrypt'
require 'fileutils'
require 'rfc822'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative 'users.rb'
require_relative 'search.rb'
require_relative 'validations.rb'

class FlightTrackApp < Sinatra::Base
  helpers Sinatra::Validations

  configure(:development) do
    register Sinatra::Reloader
    also_reload 'search.rb'
    also_reload 'users.rb'
  end

  configure do
    enable :sessions
    set :secret_sessions, 'not a good secret'
    set :erb, escape_html: true
  end

  def data_path
    if ENV['RACK_ENV'] == 'test'
      File.expand_path('../test/data', __FILE__)
    else
      File.expand_path('../public/data', __FILE__)
    end
  end

  helpers do
    def self.data_path
      if ENV['RACK_ENV'] == 'test'
        File.expand_path('../test/data', __FILE__)
      else
        File.expand_path('../public/data', __FILE__)
      end
    end

    def self.root
      File.expand_path('..', __FILE__)
    end
  end

  before do
    @data_path = data_path
    @invalid_infos ||= []
    session[:in_sign] = false

    @search = Search.new(logger)
    @users = Users.new(logger)
  end

  after do
    @search.disconnect
  end

  get '/' do
    redirect '/FlightTrackApp'
  end

  get '/FlightTrackApp' do
    erb :landing
  end

  get '/FlightTrackApp/users/sign' do
    session[:in_sign] = true
    erb :sign
  end

  post '/FlightTrackApp/users/signin' do
    username = params[:username]
    password = params[:password]

    if @users.valid_credentials?(username, password)
      session[:success] = "Welcome #{params[:username]}!"
      session[:username] = params[:username]
      redirect '/FlightTrackApp'
    else
      session[:alert] = 'Invalid Credentials'
      status 422
      erb :sign
    end
  end

  post '/FlightTrackApp/users/signout' do
    session[:username] = nil
    session[:success] = 'You have been signed out.'
    redirect '/FlightTrackApp'
  end

  post '/FlightTrackApp/users/signup' do
    @users_infos = [params[:username], params[:password],
                    params[:confirm_password]]
    @invalid_infos = invalid_inputs(@users_infos)

    confirmation_error = confirmation_inputs(@users_infos)

    if @users_infos.any? { |info| info.strip.empty? }
      session[:alert] = 'Please, fill all the fields, thank you.'

      status 422
      erb :sign
    elsif confirmation_error
      session[:alert] = confirmation_error

      status 422
      erb :sign
    elsif !@invalid_infos.empty?
      session[:alert] = "Some informations are incorrect.
                         Please check #{@invalid_infos.join(', ')}."
      invalid_password = @invalid_infos.include?(:password)

      if invalid_password
        errors = errors_in_password(params[:password])
        session[:hints] = hints_for_correct_password(errors)
      end

      status 422
      erb :sign
    else # success
      @users.create_user(@users_infos)
      session[:success] = 'Thank you for register. Please sign in.'

      status 302
      redirect '/FlightTrackApp'
    end
  end

  get '/autocomplete' do
    content_type :json

    query =
      params.select do |field, value|
        value.is_a?(String) && value.length > 1
      end

    field, input_string = query.to_a.flatten

    autocomplete_method = "autocomplete_#{field}_list"
    @search.send(autocomplete_method, input_string).to_json
  end

  get '/FlightTrackApp/airports' do
    erb :airports
  end

  post '/FlightTrackApp/searchairport' do
    country = params[:from_country].to_s
    city = params[:from_city].to_s
    
    session[:results] = @search.query_airports(country, city)
    redirect '/FlightTrackApp/airports'
  end

  get '/FlightTrackApp/detailsairport/:id' do |id|
    @airport_infos = @search.airport_details(id)
    @airport_infos = [:name, :city, :country, :iata, :icao, :latitude, :longitude, :altitude, :timezone].zip(*@airport_infos).to_h
    erb :detailairport
  end

  get '/FlightTrackApp/airlines' do
    erb :airlines
  end

  post '/FlightTrackApp/searchairline' do
  end

  get '/FlightTrackApp/routes' do
    erb :routes
  end

  post 'FlightTrackApp/searchroute' do
  end

  get '/FlightTrackApp/userpage' do
    'user page'
  end
end
