require 'bcrypt'
require 'rfc822'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'FileUtils'
require 'yaml'

require_relative('./user.rb')

class FlightTrackApp < Sinatra::Application

  configure do
    enable :sessions
    set :secret_sessions, 'not a good secret'
    set :erb, escape_html: true
  end

  helpers do

    def confirmation_inputs(inputs)
      password, confirm_password = inputs[0], inputs[2]
      email, confirm_email = inputs[1], inputs[3]
      if password != confirm_password
        'Please check, the password confirmation is not correct.'
      elsif email != confirm_email
        'Please check, the email confirmation is not correct.'
      else
         false
      end
    end

    def invalid_inputs(inputs)
      username, password, email = *inputs
      validations = { username: valid_username?(username),
                      password: valid_password?(password),
                      email: valid_email?(email) }
      if validations.values.all? { |value| value == true }
        [] # all inputs valid
      else
        validations.select { |_, value| value == false }.keys # allows to know which field(s) cause(s) error.
      end
    end

    def valid_username?(current_username)
      path = File.join(@data_path, 'users/authorized_users.yml')
      list_of_users = YAML.load_file(Pathname(path))
      list_of_users.keys.none? { |user| user == current_username }
    end

    def errors_in_password(password)
      requirements = { length: password.match(/.{8,}/),
                       digit: password.match(/\d{1,}/),
                       downcase: password.match(/[a-z]{1,}/),
                       upcase: password.match(/[A-Z]{1,}/),
                       specialchar: password.match(/[&#@*]{1,}/) }
      requirements.select { |_, result| result.nil? }.keys
    end

    def hints_for_correct_password
      beginning_message = 'your password must contain at least'
      @errors_in_password.map do |error|
        if error == :length
          "#{beginning_message}" + ' 8 characters long.'
        elsif error == :digit
          "#{beginning_message}" + ' one digit.'
        elsif error == :downcase
          "#{beginning_message}" + ' one downcased letter.'
        elsif error == :upcase
          "#{beginning_message}" + ' one upcased letter.'
        elsif error == :specialchar
          "#{beginning_message}" + ' one special character : &#*@'
        end
      end
    end

    def valid_password?(password)
      @errors_in_password = errors_in_password(password)
      @errors_in_password.empty?
    end

    def valid_email?(email)
      email.is_email?
    end

    def create_user(infos) # have to refactor : split and simple methods
      path = File.join(@data_path, 'users/authorized_users.yml')
      @list_users ||= YAML.load_file(path)
      username, uncrypted_password, email = *infos
      password = BCrypt::Password.create(uncrypted_password).to_s
      user_infos = { username => { password: password, email: email } }
      updated_list = @list_users.merge(user_infos)
      File.write(Pathname(path), updated_list.to_yaml)
      session[:user] = User.new(username, email) # create a user in the session
    end

    def data_path
      if ENV["RACK_ENV"] == "test"
        File.expand_path('../test/data', __FILE__)
      else
        File.expand_path('../public/data', __FILE__)
      end
    end

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
    @authorized_users = YAML.load_file(File.join(@data_path, 'users/authorized_users.yml'))
    session[:signed] ||= false
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

  post '/FlightTrackApp/users/sign_in' do
    if @authorized_users.keys.include?(params[:username]) &&
      BCrypt::Password.new(@authorized_users[params[:username]][:password]) == params[:password]
      session[:success] = "Welcome #{params[:username]}!"
      session[:username] = params[:username]
      session[:signed] = true
      redirect '/FlightTrackApp'
    else
      session[:alert] = "Invalid Credentials"
      status 422
      erb :sign
    end
  end

  post '/FlightTrackApp/users/signout' do
    session[:signed] = false
    session[:user] = nil
    session[:success] = 'You have been signed out.'
    redirect '/FlightTrackApp'
  end

  post '/FlightTrackApp/users/sign_up' do
    @users_infos = [params[:username], params[:password], params[:email],
                    params[:confirm_password], params[:confirm_email]]
    @invalid_infos = invalid_inputs(@users_infos[0..2])
    confirmation_error = confirmation_inputs(@users_infos[1..4])
    if @users_infos.any? { |info| info == '' }
      session[:alert] = 'Please, fill all the fields, thank you.'
      erb :sign
    elsif confirmation_error
      session[:alert] = confirmation_error
      erb :sign
    elsif @invalid_infos.empty?  # success
      create_user(@users_infos)
      session[:success] = 'Thank you for signing up!'
      redirect '/FlightTrackApp'
    else
      session[:alert] = "Sorry but some informations are incorrect. Please check #{ @invalid_infos.join(', ') }."
      invalid_password = @invalid_infos.include?(:password)
      session[:hints] = hints_for_correct_password if invalid_password
      erb :sign
    end
  end

  get '/FlightTrackApp/user_page' do
    'user page'
  end
end
