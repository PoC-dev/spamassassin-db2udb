CREATE TABLE txrep (
  username varchar(16) NOT NULL WITH DEFAULT '',
  email varchar(132) NOT NULL WITH DEFAULT '',
  ip varchar(16) NOT NULL WITH DEFAULT '',
  count int NOT NULL WITH DEFAULT 0,
  totscore float NOT NULL WITH DEFAULT 0,
  last_hit timestamp NOT NULL WITH DEFAULT CURRENT_TIMESTAMP,
  signedby char(1) WITH DEFAULT '',
  PRIMARY KEY (username,email,ip)
)
CREATE INDEX txrep_last_hit ON txrep (last_hit)
