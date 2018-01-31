require 'pg'

class Search
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "flights")
          end
    @logger = logger
  end

  def disconnect
    @db.finish
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def autocomplete_airport_list(string)
    return [] if valid_string?(string)

    sql = <<~SQL
      SELECT
            ((CASE WHEN iata IS NULL THEN ' ' ELSE iata END)||
            ' ' ||
            name ||
             ', ' ||
            city)
        FROM airports
       WHERE iata ILIKE $1 OR name ILIKE $1 OR city ILIKE $1;
    SQL

    query(sql, "#{string}%").column_values(0).compact
  end

  def autocomplete_country_list(string)
    return [] if valid_string?(string)

    sql = "SELECT DISTINCT country FROM airports WHERE country ILIKE $1"

    query(sql, "#{string}%").column_values(0).compact
  end

  def autocomplete_city_list(string)
    return [] if valid_string?(string)

    sql = "SELECT DISTINCT city FROM airports WHERE city ILIKE $1"

    query(sql, "#{string}%").column_values(0).compact
  end

  def airport_details(id)
    sql = <<~SQL
      SELECT name, city, country, iata, icao, 
             latitude, longitude, altitude,timezone
        FROM airports
       WHERE id = $1
    SQL

    query(sql, id).values
  end

  def query_airports(country, city)
    sql = <<~SQL
      SELECT id, name
        FROM airports
       WHERE country = $1
         AND city = $2
    SQL

    query(sql, country, city).values
  end

  private

  def valid_string?(string)
    string.nil? || string.length <= 2
  end
end
