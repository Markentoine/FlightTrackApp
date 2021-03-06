require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'bcrypt'
require 'fileutils'
require 'wikipedia'
require 'geokit'

require_relative 'users.rb'
require_relative 'search.rb'
require_relative 'validations.rb'

class FlightTrackApp < Sinatra::Base
  helpers Sinatra::ContentFor
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
    def self.root
      File.expand_path('..', __FILE__)
    end

    def fetch_from_wikipedia(name)
      wikipedia_page = Wikipedia.find(name)
      summary = wikipedia_page.summary
      images_urls = wikipedia_page.image_urls
      jpg_images_urls = filter_jpg_urls(images_urls)[0..2] if images_urls

      if wikipedia_page && summary
        jpg_images_urls = jpg_images_urls[0..2]
        [summary, jpg_images_urls]
      else
        [ nil, []]
      end
    end

    def filter_jpg_urls(urls)
      return [] if urls.nil?
      urls.reduce([]) do |result, url|
        result << url if url.match(/.jpg/)
        result
      end
    end

    def homepage?
      request.path_info == "/FlightTrackApp"
    end

    def routes_submitted?(from, to)
      !from.nil? && !from.empty? && !to.nil? && !to.empty?
    end
  end

  before do
    @invalid_infos ||= []
    session[:in_sign] = false

    @search = Search.new(logger)
    @users = Users.new(logger)
  end

  before '/FlightTrackApp/airports' do
    @locations_all_airports = File.open(File.join(data_path, 'locations_airports.json')).read
  end

  after do
    @search.disconnect
  end

  get '/' do
    redirect '/FlightTrackApp'
  end

  get '/FlightTrackApp' do
    erb :landing, layout: false
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
      session[:username] = username
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
    @users_infos = [params[:username],
                    params[:password],
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
      session[:alert] = "Some information are invalid."\
      " Please check #{@invalid_infos.join(', ')}."
      invalid_password = @invalid_infos.include?(:password)

      if invalid_password
        errors = errors_in_password(params[:password])
        session[:hints] = hints_for_correct_password(errors)
      end

      status 422
      erb :sign
    else # success
      @users.create_user(@users_infos)
      session[:username] = @users_infos[0]
      session[:success] = 'Congratulations, your account has been created!'

      status 302
      redirect '/FlightTrackApp'
    end
  end

  get '/autocomplete' do
    content_type :json

    query =
      params.select do |field, value|
        value.is_a?(String) && value.length >= 1
      end

    field, *inputs = query.to_a.flatten

    autocomplete_method = "autocomplete_#{field}_list"
    @search.send(autocomplete_method, *inputs).to_json
  end

  get '/FlightTrackApp/airports' do
    erb :airports
  end

  post '/FlightTrackApp/searchairport' do
    country = params[:from_country]
    city = params[:from_city]

    raw_results = @search.query_airports(country, city)

    if raw_results.size > 20
      session[:alert] = "Too many results. Please narrow your search criteria"
      halt erb :airports
    end

    results =
      raw_results.map do |airport_infos|
        [:id, :name, :latitude, :longitude]
          .zip(airport_infos)
          .to_h
      end

    session[:airports] = results
    redirect '/FlightTrackApp/airports'
  end

  get '/FlightTrackApp/detailsairport/:id' do |id|
    @airport_infos = @search.query_airport_details(id)
    @airport_summary, @airport_images = fetch_from_wikipedia(@airport_infos['name'])
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

  post '/FlightTrackApp/searchroute' do
    @from_iata = params[:from][0, 3].upcase
    @to_iata = params[:to][0, 3].upcase

    @coord_from = @search.latitude_longitude(@from_iata)
    @coord_to = @search.latitude_longitude(@to_iata)

    unless @coord_from && @coord_to
      session[:alert] = 'Route not found, please try again.'
      halt erb :routes
    end

    geokit_from = Geokit::LatLng.new(*@coord_from)
    geokit_to = Geokit::LatLng.new(*@coord_to)

    @distance = geokit_from.distance_to(geokit_to)
    geokit_midpoint = geokit_from.midpoint_to(geokit_to)

    @coordinate_from, @coordinate_to, @coordinate_midpoint =
      [geokit_from, geokit_to, geokit_midpoint].map do |geokit|
        [:lat, :lng].zip(geokit.to_a).to_h
      end

    erb :routes
  end

  get '/FlightTrackApp/userpage' do
    'user page'
  end
end
