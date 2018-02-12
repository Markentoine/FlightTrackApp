require 'pg'

class Search
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            initialize_local_database
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def query_airports(country, city='')
    city_query = ' AND city ILIKE $2'

    sql = <<~SQL
      SELECT id, name, latitude, longitude
      FROM airports
      WHERE country ILIKE $1
    SQL

    if city.strip.empty?
      query(sql, country).values
    else
      sql += city_query
      query(sql, country, city).values
    end
  end

  def query_airport_details(id)
    sql = <<~SQL
      SELECT name, city, country, iata, icao,
             latitude, longitude, altitude,timezone
      FROM airports
      WHERE id = $1
    SQL

    query(sql, id).each.first
  end

  def query_all_cities_with_airports_in_a_country(country)
    sql = <<~SQL
      SELECT city
      FROM airports
      WHERE country ILIKE $1
    SQL

    query(sql, "#{country}%").values
  end

  def query_locations_all_airports_world
      sql = <<~SQL
        SELECT latitude, longitude
        FROM airports
      SQL

      query(sql).values
  end

  def autocomplete_airport_list(string)
    return [] if invalid_string?(string)

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
    return [] if invalid_string?(string)

    sql = "SELECT DISTINCT country FROM airports WHERE country ILIKE $1"

    query(sql, "#{string}%").column_values(0).compact
  end

  def autocomplete_city_list(city, _, country)
    sql = <<~SQL
      SELECT DISTINCT city
        FROM airports
       WHERE country ILIKE $1 AND city ILIKE $2
    SQL

    query(sql, country,"#{city}%").column_values(0).compact
  end

  def latitude_longitude(iata)
    sql = <<~SQL
      SELECT latitude, longitude
        FROM airports WHERE iata = $1
    SQL

    result = query(sql, iata).values[0]
    return false if result.nil?
    
    result.map(&:to_f)
  end

  private

  def invalid_string?(string)
    string.nil? || string.length < 2
  end

  def initialize_local_database
    begin
      PG.connect(dbname: "flights")
    rescue PG::ConnectionBad
      PG.connect.exec('CREATE DATABASE flights')
      db = PG.connect(dbname: "flights")

      schema_sql = File.read('schema.sql')
      db.exec(schema_sql)

      import_airports_data!(db)
      db
    end
  end

  def import_airports_data!(db)
    airports_data_path = Dir.getwd + '/public/data/airports_parsed.csv'

    fields = '(id,name,city,country,iata,icao,latitude,longitude,altitude,timezone,dst,tz,type,source)'

    sql = "COPY airports #{fields} FROM \'#{airports_data_path}\' WITH CSV HEADER;"
    db.exec(sql)
  end
end
