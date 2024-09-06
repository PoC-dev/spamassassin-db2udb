This project provides two files for use with Spamassassin 3, so the DB2/UDB database coming with IBM i can be utilized as Storage Backend for AWL/TXREP and Bayes with the aid of ODBC.

**Note:** Meanwhile, Spamassassin 4 has been released, with some new code regarding database flavors in the generic SQL modules. This project has not yet been updated accordingly!

*DB2UDB.pm* is an adaption of the stock *SQL.pm* included with Spamassassin for the peculiarities of the IBM i (formerly known as IBM iSeries formerly known as AS/400) integrated DB2/UDB database and it's accompanying ODBC driver.

*SQLBasedAddrList.pm* is a patched version of the file with the same name from Spamassassin, which is meant to work with stock SQL and DB/2 UDB SQL. Function on stock SQL has not been tested extensively, but MySQL works.

Both files have been derived from Version 3.4.6 and inherit the same license as the mentioned original files.

In addition, a tiny program in positional ILE RPG has been provided for housekeeping the TXREP table. It is licensed under the GPL v2 or later versions, at your option. Upload into a source PF, compile. Run it with a scheduled job entry:
```
addjobscde job(awl_expire) cmd(call pgm(spamassass/awl_expire)) frq(*weekly) scddate(*none) scdday(*all) scdtime('04:37') text('Purge old records from Spamassassin-AWL')
```

== Rationale.
Either the ODBC driver, or the database behave differently than the code in stock SQL.pm and SQLBasedAddrList.pm expects. Peculiarities encountered:
- Return value of the execute-method is 
   - -1 for SELECTs,
   - undef for INSERTs, UPDATEs or DELETEs.
- `$sth->rows` is correct for SELECTs, but not for INSERTs, UPDATEs, DELETEs.

It seems the only reliable way to determine if an error happened is to check if `$sth->errstr` is defined.

To enable my old AS/400 to have some meaningful workload, I decided to adapt the existing files. Enhancing SQLBasedAddrList.pm wasn't too bad but extending *SQL.pm* would have bloated the code unnecessarily. So I chose to create a separate file.

== Installation
Install the ODBC packages for your particular Linux distro. Install the IBM i ODBC driver for Linux. You can download it from ESS, but you need an IBM ID for signing in. It can be obtained without a fee.
- [https://www.ibm.com/servers/eserver/ess/ProtectedServlet.wss](Login/Requesting an IBM ID)
- [https://www.ibm.com/support/pages/node/633843](Support Page for IBM i Access - Client solutions) including download links

You need the *IBMiAccess_v1r1_LinuxAP.zip*. It contains subdirectories for supported CPU architectures, in turn containing readymade DEB and RPM packages. Install the matching one with `dpkg -i` or `rpm -i`.

Example entry for */etc/odbc.ini*:
```
[Nibbler]
Driver=IBM i Access ODBC Driver
System=nibbler.pocnet.net
AllowUnsupportedChar=1
```
You can find documentation about the parameters [https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/rzaik/connectkeywords.htm](here).

You can find further explanation about the commit mode statement [https://www-01.ibm.com/support/docview.wss?uid=nas8N1017566](here).

Create an user profile (e. g. *spambays* with a default library, for example *spamassass*. Make sure you've configured TCP/IP services properly, and basic communication between the Linux install, and IBM i is working.

Test the connection with
```
isql -v Nibbler <userprofilename> <password-here>
```
Example entry for spamassassin's local.cf file for Bayes and AWL on IBM i:
```
bayes_store_module Mail::SpamAssassin::BayesStore::DB2UDB
bayes_sql_dsn DBI:ODBC:Driver={IBM i Access ODBC Driver};System=Nibbler;DBQ=SPAMASSASS
bayes_sql_username spambays
bayes_sql_password <password-here>
auto_whitelist_factory Mail::SpamAssassin::SQLBasedAddrList
user_awl_dsn DBI:ODBC:Driver={IBM i Access ODBC Driver};System=Nibbler;DBQ=SPAMASSASS
user_awl_sql_username spambays
user_awl_sql_password <password-here>
user_awl_sql_table awl
```
For creating the database tables, you can either
- copy-paste the matching sql-file's contents into an interactive SQL session (`strsql` in 5250),
- use the IBM i Access Client's "Run SQL scrips" function,
- upload the files via FTP into a source physical file and use `runsqlstm` for executing the commands in there.

Messages that a created file could not be recorded in the journal can be ignored. So far, the script(s) do not support transactional processing. This feature is planned for a later version.

Trying to create the tables traditionally with DDS did not yield tables usable by Spamassassin so far.

After everything is prepared, you might migrate your existing database (most likely from MySQL) into the IBM i database. See the Spamassassin provided `sa-learn` command. You can backup and restore a database with it.

The restore process is incredibly slow, though, because the database contents are restored in a way similar to Bayes learning. Interestingly, my tests showed that `sa-learn` on the client machine itself is occupying one core of said machine completely all the time, while the IBM i machine (a 8203-E4A) had a CPU load of around 20%.

== Bugs
I'm sure there are yet undiscovered ones. What I've tested so far:
- TXREP functionality in a production environment for several months. Spamassassin 3.4.2 from Debian 10 (Buster) onward. The Database is located on an ancient AS/400e Model 150 running OS/400 V4R5. It is accessed with the older IBM iSeries Access driver.
- A cancelled `sa-learn --restore` on the same platform. Cancelled because the restore of about 5 million tokens would have run for weeks.
- `sa-learn --restore` on the same Linux/Spamassassin combo. The database was located on a IBM Power 520 Express (8203-E4A) running IBM i 7.2. It was accessed with the IBM iAccess ODBC Driver.
- `sa-learn --restore` on the same Linux/Spamassassin combo. The database was located on a IBM 9406-800 running IBM i V5R4. It was accessed with the older IBM iSeries Access driver.

As far as I know the current iACS driver does not support connections to OS/400 versions older than V5. If you want to make use of older systems, you need to find a download source for the older iSeries Access ODBC Driver package.

Please provide feedback to my mail address, poc@pocnet.net.

== ToDo
- Better error messages. The original files had the same error messages for different error conditions in the code. This makes finding the right spot for chasing a bug unnecessary hard. Partly done.
- Implement transactional consistency with START TRANSACTION and COMMIT/ROLLBACK to make sure the database is consistent even after a program error had the database modifications done just in parts.
- Possibly convert `sa-learn --force-expire` to a local SQL or RPG program running on the IBM i machine for better performance and increased efficiency.
- After stability is proven for some time by different users, and issues have been resolved, try to integrate us into the main Spamassassin source tree.

----

08-2021 poc@pocnet.net