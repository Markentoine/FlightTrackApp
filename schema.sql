CREATE TABLE airports (
  id serial PRIMARY KEY,
  name varchar(256) NOT NULL,
  city varchar(128) NOT NULL,
  country varchar(64) NOT NULL,
  iata char(3) CHECK (iata = UPPER(iata)) NOT NULL,
  icao char(4),
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  altitude integer,
  timezone numeric(3,1),
  dst char(1),
  tz char(64),
  type varchar(32),
  source varchar(11)
);