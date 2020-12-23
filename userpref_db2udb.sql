CREATE TABLE userpref (
  username varchar(12) NOT NULL WITH DEFAULT '',
  preference varchar(8) NOT NULL WITH DEFAULT '',
  value varchar(8) NOT NULL WITH DEFAULT '',
  prefid int NOT NULL,
  PRIMARY KEY (prefid)
)
CREATE INDEX username on userpref (username)
