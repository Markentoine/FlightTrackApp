require 'bcrypt'
require 'rfc822'
require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'fileutils'
require 'yaml'

require_relative 'users.rb'
require_relative 'search.rb'

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'search.rb'
  also_reload 'users.rb'
end

class FlightTrackApp < Sinatra::Application

  configure do
    enable :sessions
    set :secret_sessions, 'not a good secret'
    set :erb, escape_html: true
  end

  def confirmation_inputs(inputs)
    password, confirm_password = inputs[1], inputs[2]
    if password != confirm_password
      return 'Please check, the password confirmation is not correct.'
    end
    false
  end

  def invalid_inputs(inputs)
    username, password, _ = *inputs
    validations = { username: valid_username?(username),
                    password: valid_password?(password) }

    validations.select { |_, value| value == false }.keys
    # allows to know which field(s) cause(s) error. If all values are true, this statement returns [].
  end

  def valid_username?(username)
    @users.username_available?(username)
  end

  def valid_password?(password)
    errors_in_password(password).empty?
  end

  def errors_in_password(password)
    requirements = { length: password.match(/.{8,}/),
                     digit: password.match(/\d{1,}/),
                     downcase: password.match(/[a-z]{1,}/),
                     upcase: password.match(/[A-Z]{1,}/),
                     specialchar: password.match(/[!&#@*]{1,}/) }
    requirements.select { |_, result| result.nil? }.keys
  end

  def hints_for_correct_password(errors_in_password)
    beginning_message = 'your password must contain at least'
    errors_in_password.map do |error|
      case error
      when :length
        "#{beginning_message}" + ' 8 characters long.'
      when :digit
        "#{beginning_message}" + ' one digit.'
      when :downcase
        "#{beginning_message}" + ' one downcased letter.'
      when :upcase
        "#{beginning_message}" + ' one upcased letter.'
      when :specialchar
        "#{beginning_message}" + ' one special character : !&#*@'
      end
    end
  end

  def data_path
    if ENV["RACK_ENV"] == "test"
      File.expand_path('../test/data', __FILE__)
    else
      File.expand_path('../public/data', __FILE__)
    end
  end

  helpers do
    def self.data_path
      if ENV["RACK_ENV"] == "test"
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
      session[:alert] = "Invalid Credentials"
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
      session[:alert] = "Sorry but some informations are incorrect. Please check #{ @invalid_infos.join(', ') }."
      invalid_password = @invalid_infos.include?(:password)

      if invalid_password
        errors = errors_in_password(params[:password])
        session[:hints] = hints_for_correct_password(errors)
      end

      status 422
      erb :sign
    else # success
      @users.create_user(@users_infos)
      session[:success] = 'Thank you for signing up!'

      status 302
      redirect '/FlightTrackApp'
    end
  end

  get '/autocomplete' do
    content_type :json
    @search.autocomplete_airport_list(params[:query]).to_json
  end

  get '/FlightTrackApp/airports' do
    erb :airports
  end

  post '/FlightTrackApp/searchairport' do

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
