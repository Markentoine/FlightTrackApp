require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'bcrypt'
require 'fileutils'
require 'wikipedia'

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
      jpg_images_urls = filter_jpg_urls(images_urls)
      nb_images = jpg_images_urls.size
      if wikipedia_page && summary && jpg_images_urls
        jpg_images_urls = nb_images > 3 ? jpg_images_urls.first(3) : jpg_images_urls
        return [summary, jpg_images_urls]
      elsif wikipedia_page && summary
        return [summary, []]
      else
        return [ nil, []]
      end
    end

    def filter_jpg_urls(urls)
      urls.reduce([]) { |result, url| result << url if url.match(/.jpg/); result }
    end
  end

  before do
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
    country = params[:from_country].to_s.capitalize
    if params[:from_city].length > 0
      city = params[:from_city].to_s.capitalize
      raw_results = @search.query_airports(country, city)
      results = raw_results.map { |airport_infos| [:id, :name, :latitude, :longitude]
                                                  .zip(airport_infos)
                                                  .to_h }
      session[:airports] = results
      redirect '/FlightTrackApp/airports'
    else
      cities_with_airport = @search.all_cities_with_airports_in_a_country(country)
      session[:cities] = cities_with_airport.flatten.uniq
      redirect '/FlightTrackApp/airports'
    end
  end

  get '/FlightTrackApp/detailsairport/:id' do |id|
    raw_airport_infos = @search.airport_details(id)
    @airport_infos = [:name, :city, :country, :iata, :icao, :latitude, :longitude, :altitude, :timezone]
                     .zip(*raw_airport_infos)
                     .to_h
    @airport_summary, @airport_images = fetch_from_wikipedia(@airport_infos[:name])
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
