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
    return [] if string.nil? || string.length <= 2

    sql = <<~SQL
      SELECT id, 
            ((CASE WHEN iata IS NULL THEN ' ' ELSE iata END)|| 
              ' ' || 
            trim(trailing ' Airport' from name) || 
             ', ' || 
            city) 
        FROM airports 
       WHERE iata ILIKE $1 OR name ILIKE $1 OR city ILIKE $1;
    SQL

    query(sql, "#{string}%").column_values(1).compact
  end
  # attr_accessor :from_country, :from_town, :from_airport,
  #               :to_country, :to_town, :to_airport

  # def initialize(from_infos, to_infos, username)
  #   @from_country, @from_town, @from_airport = from_infos
  #   @to_country, @to_town, @to_airport = to_infos
  #   @username = username
  # end

end
