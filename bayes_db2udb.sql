CREATE TABLE bayes_expire (
  id int NOT NULL WITH DEFAULT 0,
  runtime int NOT NULL WITH DEFAULT 0
)
CREATE INDEX bayes_expire_idx1 ON bayes_expire (id)
CREATE ALIAS BAYES_EXP FOR BAYES00001

CREATE TABLE bayes_global_vars (
  variable varchar(8) NOT NULL WITH DEFAULT '',
  value char(1) NOT NULL WITH DEFAULT '',
  PRIMARY KEY (variable)
)
INSERT INTO bayes_global_vars VALUES ('VERSION','3')
CREATE ALIAS BAYES_GLOB FOR BAYES00003

CREATE TABLE bayes_seen (
  id int NOT NULL WITH DEFAULT 0,
  msgid varchar(64) NOT NULL WITH DEFAULT '',
  flag char(1) NOT NULL WITH DEFAULT '',
  PRIMARY KEY (id, msgid)
)

CREATE TABLE bayes_token (
  id int NOT NULL WITH DEFAULT 0,
  token char(5) FOR BIT DATA NOT NULL WITH DEFAULT '',
  spam_count FOR COLUMN spamcnt int NOT NULL WITH DEFAULT 0,
  ham_count FOR COLUMN hamcnt int NOT NULL WITH DEFAULT 0,
  atime int NOT NULL WITH DEFAULT 0,
  PRIMARY KEY (id, token)
)
CREATE INDEX bayes_token_idx1 ON bayes_token (id, atime)
CREATE INDEX bayes_token_idx2 ON bayes_token (id, atime, token)
CREATE INDEX bayes_token_idx3 ON bayes_token (id, spam_count, ham_count)
CREATE ALIAS BAYES_TOKN FOR BAYES00004

CREATE TABLE bayes_vars (
  id int NOT NULL WITH DEFAULT 0,
  username varchar(16) NOT NULL WITH DEFAULT '',
  spam_count FOR COLUMN spamcnt int NOT NULL WITH DEFAULT 0,
  ham_count FOR COLUMN hamcnt int NOT NULL WITH DEFAULT 0,
  token_count FOR COLUMN token_cnt int NOT NULL WITH DEFAULT 0,
  last_expire int NOT NULL WITH DEFAULT 0,
  last_atime_delta FOR COLUMN ls_atime int NOT NULL WITH DEFAULT 0,
  last_expire_reduce FOR COLUMN ls_expire int NOT NULL WITH DEFAULT 0,
  oldest_token_age FOR COLUMN old_tok_ag int NOT NULL WITH DEFAULT 2147483647,
  newest_token_age FOR COLUMN new_tok_ag int NOT NULL WITH DEFAULT 0,
  PRIMARY KEY (id)
)
CREATE UNIQUE INDEX bayes_vars_idx1 ON bayes_vars (username)
