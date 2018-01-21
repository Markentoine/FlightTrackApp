require 'pg'

class Search
  def initialize(logger)
    @db = PG.connect(dbname: 'flights')
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
