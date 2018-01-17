ENV["RACK_ENV"] = 'test'

require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'rack/test'


require_relative '../aFlightTrackApp'

class TestFlightTrackApp < Minitest::Test
  include Rack::Test::Methods

  def app
    FlightTrackApp
  end

  def test_first_route
    get '/'
    assert_equal(302, last_response.status)
    get last_response['location']
    assert_equal(200, last_response.status)
  end

  def test_landing_page
    get '/FlightTrackApp'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Track Your Flight')
    assert_includes(last_response.body, 'Sign in')
    assert_includes(last_response.body, 'Sign up')
  end
end
