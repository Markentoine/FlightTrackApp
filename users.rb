require 'bcrypt'
require 'pg'

class Users
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "flights")
          end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec(statement, params)
  end

  def username_available?(username)
    sql = "SELECT username FROM users WHERE username = $1"
    result = query(sql, username)
    result.values.flatten.empty?
  end

  def create_user(users_info)
    username, password, _ = users_info
    password = encrypt_password(password)

    sql = "INSERT INTO users (username, password)
           VALUES ($1, $2)"
    query(sql, username, password)
  end

  def valid_credentials?(username, password)
    username_sql = "SELECT username FROM users WHERE username = $1"
    username_match_result = query(username_sql, username)
    return false if username_match_result.values.flatten.empty?

    password_sql = "SELECT password FROM users WHERE username = $1"
    encrypted_password = query(password_sql, username).values[0][0]
    BCrypt::Password.new(encrypted_password) == password
  end

  private

  def encrypt_password(password)
    BCrypt::Password.create(password).to_s
  end
end