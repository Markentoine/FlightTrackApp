require 'pg'

class Search
  def initialize
    @db = PG.connect(dbname: 'flights')
  end
end
