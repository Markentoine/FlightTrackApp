CREATE TABLE airports (
  id serial PRIMARY KEY,
  name varchar(256) NOT NULL,
  city varchar(128) NOT NULL,
  country varchar(64) NOT NULL,
  iata char(3) CHECK (iata ~ '^[0-9A-Z]{3}$') NOT NULL,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  icao char(4),
  altitude integer,
  timezone numeric(3,1),
  dst char(1) CHECK (dst IN ('E', 'A', 'S', 'O', 'Z', 'N', 'U')),
  tz char(64),
  type varchar(32),
  source varchar(11)
);

CREATE TABLE users (
  id serial PRIMARY KEY,
  username varchar(32) NOT NULL,
  password char(60) NOT NULL
);
