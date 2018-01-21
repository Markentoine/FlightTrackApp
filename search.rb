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
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
  # attr_accessor :from_country, :from_town, :from_airport,
  #               :to_country, :to_town, :to_airport

  # def initialize(from_infos, to_infos, username)
  #   @from_country, @from_town, @from_airport = from_infos
  #   @to_country, @to_town, @to_airport = to_infos
  #   @username = username
  # end

end
