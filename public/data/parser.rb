raw_data = File.read('airports_raw.csv')

cleaned =
  raw_data.gsub!(/\\N/, '')
          .gsub!(/\,\s/, '')
          .gsub!(/N\/A/, '')
          .delete!("\"")

File.write('airports_parsed.csv', cleaned)