This project provides two files for use with Spamassassin 4, so the DB2/UDB database coming with IBM i and predecessors can be utilized as storage backend for AWL/TXREP and Bayes with the aid of ODBC.

*DB2UDB.pm* is an adaption of the stock *SQL.pm* included with Spamassassin for the peculiarities of the IBM i (formerly known as IBM iSeries formerly known as AS/400) integrated DB2/UDB database and its accompanying ODBC driver. See below for details.

*SQLBasedAddrList.pm* is a patched version of the file with the same name from Spamassassin, which is meant to work with stock SQL and DB2/UDB SQL. Function on stock SQL has not been tested extensively, but MySQL works.

*awl_db2udb.sql*, *bayes_db2udb.sql*, *txrep_db2udb.sql* and *userpref_db2udb.sql* are SQL statements for creating the respective tables in DB2 lingo.

Files have been derived from Spamassassin 4.0.0 and inherit the same license as the mentioned original files.

In addition, the tiny program `txrep_exp.rpgle` in positional ILE RPG with embedded SQL has been provided for housekeeping the TXREP table. It is licensed under the GPL v2 or later versions, at your option. Upload into a source PF, compile. Run it with a scheduled job entry:
```
addjobscde job(txrep_exp) cmd(call pgm(spamassass/txrep_exp)) frq(*weekly) scddate(*none) scdday(*all) scdtime('04:37') text('Purge old records from Spamassassin-TXREP')
```

## Rationale.
Either the IBM ODBC driver, or the database behave differently than the code in stock *SQL.pm* and *SQLBasedAddrList.pm* expect. Peculiarities encountered:
- Return value of `$sth->execute` is
   - `-1` for `SELECT`,
   - `undef` for `INSERT`, `UPDATE` or `DELETE`.
- `$sth->rows` is correct for `SELECT`, but not for `INSERT`, `UPDATE` and `DELETE`.

It seems the only reliable way to determine if an error happened is to check if `$sth->errstr` is defined. Changes to the files account for the encountered specialities.

To enable my old AS/400 to have some meaningful workload, I decided to adapt the existing files. Enhancing *SQLBasedAddrList.pm* wasn't too bad but extending *SQL.pm* would have bloated the code unnecessarily. So I chose to create a separate file.

## Installation.
### ODBC.
Install the ODBC packages for your particular Linux distro. Install the IBM i ODBC driver for Linux. You can download it from ESS, but you need an IBM ID for signing in. It can be obtained without a fee.
- [Login/Requesting an IBM ID](https://www.ibm.com/servers/eserver/ess/ProtectedServlet.wss)
- [Support Page for IBM i Access - Client solutions](https://www.ibm.com/support/pages/node/633843) including download links

You need the *IBMiAccess_v1r1_LinuxAP.zip*. It contains subdirectories for supported CPU architectures, in turn containing readymade DEB and RPM packages. Install the matching one with `dpkg -i` or `rpm -i`.

Example entry for */etc/odbc.ini*:
```
[Nibbler]
Driver=IBM i Access ODBC Driver
System=nibbler.pocnet.net
AllowUnsupportedChar=1
```
You can find documentation about the parameters [here](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_73/rzaik/connectkeywords.htm).

You can find further explanation about the commit mode statement [here](https://www-01.ibm.com/support/docview.wss?uid=nas8N1017566).

Create an user profile (e. g. *spambays*) with a default library on your IBM i, for example *spamassass*. Make sure you've configured TCP/IP services properly, and basic communication between the Linux install, and the IBM machine is working.

Test the ODBC connection with
```
isql -v Nibbler <userprofilename> <password-here>
```
If you issue `help` as command, you should get a list of default IBM i libraries and their contained tables.

### Spamassassin.
Example entry for Spamassassin's *local.cf* file for Bayes and TXREP on IBM i:
```
bayes_store_module Mail::SpamAssassin::BayesStore::DB2UDB
bayes_sql_dsn DBI:ODBC:Driver={IBM i Access ODBC Driver};System=Nibbler;DBQ=SPAMASSASS;CMT=0
bayes_sql_username spambays
bayes_sql_password <password-here>
txrep_factory Mail::SpamAssassin::SQLBasedAddrList
user_awl_dsn DBI:ODBC:Driver={IBM i Access ODBC Driver};System=Nibbler;DBQ=SPAMASSASS;CMT=0
user_awl_sql_username spambays
user_awl_sql_password <password-here>
user_awl_sql_table txrep
use_txrep 1
```

### Database.
For creating the database tables, you can either
- copy-paste the respective SQL file's contents into an interactive SQL session (`strsql` in 5250), one by one, omitting the `;`,
- use the IBM i Access Client's "Run SQL scripts" function,
- upload the files via FTP into a source physical file and use the 5250 `runsqlstm` command for executing the SQL statements in there.

To ease access from 5250 sessions, the SQL commands create 10 char table- and field name aliases.

To enable transactional processing, the tables need to be journaled. In a 5250 session, issue these commands:
```
chgcurlib curlib(spamassass)
crtjrnrcv jrnrcv(sa00000001)
crtjrn jrn(sajrn) jrnrcv(*curlib/sa00000001) dltrcv(*yes) rcvsizopt(*rmvintent) jrncache(*yes)
strjrnpf file(*curlib/bayes_seen *curlib/bayes_vars *curlib/bayes00001 *curlib/bayes00002 *curlib/bayes00003 *curlib/txrep) jrn(*curlib/sajrn) omtjrne(*opnclo)
```
**Note:** If you journal database tables, and the client doesn't `COMMIT` changes, an automatic `ROLLBACK` will be issued when the connection is closed after Spamassassin completed scan of an email. All changes are lost. Until we incorporate proper commitment control, take care to use `CMT=0` in your connection string as shown above!

After everything is prepared, you might want to migrate your existing database (most likely from MySQL) into the IBM i database. See the Spamassassin provided `sa-learn` command. You can backup and restore a database with it. If you used the default *Berkeley Database* support, this is your only option to export the Bayes database in a way to reimport it into any SQL database. I must admit, I've completely forgotten how AWL/TXREP data is stored without a SQL database backend. Refer to the official [Spamassassin documentation](https://spamassassin.apache.org/doc.html) for details, or view the [Spamassassin](https://kb.pocnet.net/wiki/Spamassassin) entry in my Knowledgebase (German language).

The restore process of `sa-learn` is incredibly slow. The database contents are restored in a way similar to Bayes learning and thus might pose considerable impact on your local CPU.

If you want things to proceed faster, and you already use e. g. MySQL for storing Bayes- and TXREP data, see the included `copy-sa-tables.pl` script.
```
Usage: copy-sa-tables(.pl) [options]
Options:
    -h: Show this help
    -s: Copy bayes_seen
    -t: Copy bayes_token
    -v: Copy bayes_vars
    -r: Copy txrep
    -T: Run TRUNCATE TABLE prior to inserting - not supported by all OS/400 releases
    -V: Show version and exit
```
If your target machine has sufficient I/O juice, you can run this script in parallel for each of the individual table *copy* parameters. A 9406-800 with RAID5 over 10 Disks yielded just 50% CPU load.

## Bugs
I'm sure there are yet undiscovered ones. What I've tested so far:
- TXREP functionality in a production environment for several months. Spamassassin 3.4.2 from Debian 10 (Buster) onward. The Database is located on an ancient AS/400e Model 150 running OS/400 V4R5. It is accessed with the older IBM iSeries Access driver.
- A cancelled `sa-learn --restore` on the same platform. Cancelled because the restore of about 5 million tokens would have run for weeks.
- `sa-learn --restore` on the same Linux/Spamassassin combo. The database was located on a IBM Power 520 Express (8203-E4A) running IBM i 7.2. It was accessed with the IBM iAccess ODBC Driver.
- `sa-learn --restore` on the same Linux/Spamassassin combo. The database was located on a IBM 9406-800 running IBM i5/OS V5R4. It was accessed with the older IBM iSeries Access driver.

As far as I know the current iACS driver does not support connections to OS/400 versions older than V5. If you want to make use of older systems, you need to find a download source for the older iSeries Access ODBC Driver package.

## ToDo
- Better error messages. The original files had the same error message for different error conditions in the code. This makes finding the right spot for chasing a bug unnecessary hard. Partly done.
- Implement transactional consistency with COMMIT/ROLLBACK to make sure the database is consistent even after a program error had the database modifications done just in parts. Not sure if this is beneficial:
   - Each table seems to be mostly self-contained, no cross relations
   - Most statistics in *bayes_vars* can probably obtained from *bayes_seen* and *bayes_tokens*
- Possibly convert `sa-learn --force-expire` to a local SQL or RPG program running on the IBM i machine for better performance and increased efficiency.
- After stability is proven for some time by different users, and issues have been resolved, try to integrate us into the main Spamassassin source tree.

The latter point proves to be challenging. Apparently there are no people besides me using IBM i as storage backend for Spamassassin. And I don't use the functionality regularly for reasons being described in [README.machines.md](README.machines.md).

----

2024-09-14 poc@pocnet.net
