require 'sinatra/base'

module Sinatra
  module Validations
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
      beginning_message = 'Your password must contain at least'
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
  end

  helpers Validations
end
