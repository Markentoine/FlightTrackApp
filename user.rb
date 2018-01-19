class User

  attr_accessor :username, :email

  def initialize(username, email, password)
    @username = username
    @email = email
    @password = password
  end

end
