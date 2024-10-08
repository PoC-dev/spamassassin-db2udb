CREATE TABLE awl (
  username varchar(16) NOT NULL WITH DEFAULT '',
  email varchar(132) NOT NULL WITH DEFAULT '',
  ip varchar(16) NOT NULL WITH DEFAULT '',
  msgcount int NOT NULL WITH DEFAULT 0,
  totscore float NOT NULL WITH DEFAULT 0,
  signedby char(48) NOT NULL WITH DEFAULT '',
  last_hit timestamp NOT NULL WITH DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (username,email,signedby,ip)
);
CREATE INDEX awl_last_hit ON awl (last_hit);
