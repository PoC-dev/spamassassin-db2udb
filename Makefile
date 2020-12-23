.PHONY: install diff

install:
	install -o root -g root -m 644 DB2UDB.pm /usr/share/perl5/Mail/SpamAssassin/BayesStore/DB2UDB.pm
	install -o root -g root -m 644 SQLBasedAddrList.pm /usr/share/perl5/Mail/SpamAssassin/SQLBasedAddrList.pm
	install -o root -g root -m 644 awl_db2udb.sql bayes_db2udb.sql txrep_db2udb.sql userpref_db2udb.sql /usr/share/doc/spamassassin/sql

diff:
	-colordiff -B -U10 DB2UDB.pm /usr/share/perl5/Mail/SpamAssassin/BayesStore/DB2UDB.pm
	-colordiff -B -U10 SQLBasedAddrList.pm /usr/share/perl5/Mail/SpamAssassin/SQLBasedAddrList.pm
