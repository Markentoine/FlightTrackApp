require 'pg'

class Search
  def initialize
    @db = PG.connect(dbname: 'flights')
  end
  # attr_accessor :from_country, :from_town, :from_airport,
  #               :to_country, :to_town, :to_airport

  # def initialize(from_infos, to_infos, username)
  #   @from_country, @from_town, @from_airport = from_infos
  #   @to_country, @to_town, @to_airport = to_infos
  #   @username = username
  # end

end
