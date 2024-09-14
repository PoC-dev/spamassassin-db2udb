#!/usr/bin/perl -w

# This is to be manually incremented on each "publish".
my $versionstring = '2024-09-13.00';

use strict;
use warnings;
use DBI;
use Getopt::Std;

# How to access the databases
my $odbc_dsn      = "DBI:ODBC:Driver={iSeries Access ODBC Driver};System=Digby;DBQ=SPAMASSASS";
my $odbc_user     = "dstuser";
my $odbc_password = "dstpass";
my $maria_db      = "spamassassin";
my $maria_user    = "srcuser";
my $maria_pass    = "srcpass";

# DB-Handling vars.
my ($maria_dbh, $maria_sth, $odbc_dbh, $odbc_sth);

# Variables from the tables.
my ($atime, $email, $flag, $ham_count, $id, $ip, $last_atime_delta, $last_expire, $last_expire_reduce, $last_hit, $msgcount,
    $msgid, $newest_token_age, $oldest_token_age, $runtime, $signedby, $spam_count, $token, $token_count, $totscore, $username
);

# Causes the currently selected handle to be flushed immediately and after every print. Execute anytime before using <STDOUT>.
$| = 1;

#-----------------------------------------------------------------------------------------------------------------------------------
# Parse cmdline options.

my %options = ();
my $retval = getopts("hstvrTV", \%options);

if ( $retval != 1 ) {
    printf(STDERR "Wrong parameter error.\n");
}

if ( defined($options{h}) || $retval != 1 ) {
    printf("Version %s\n", $versionstring);
    printf("Usage: copy-sa-tables(.pl) [options]\nOptions:
    -h: Show this help
    -s: Copy bayes_seen
    -t: Copy bayes_token
    -v: Copy bayes_vars
    -r: Copy txrep
    -T: Run TRUNCATE TABLE prior to inserting - not supported by all OS/400 releases
    -V: Show version and exit\n\n");
    exit(0);
} elsif ( defined($options{V}) ) {
    printf("Version %s\n", $versionstring);
    exit(0);
}

#-----------------------------------------------------------------------------------------------------------------------------------
# Connect, etc.

printf("Connecting to IBM i database...");
$odbc_dbh = DBI->connect($odbc_dsn, $odbc_user, $odbc_password, {PrintError => 0, LongTruncOk => 1});
if ( ! defined($odbc_dbh) ) {
    printf(" failed:\n%s\n", $odbc_dbh->errstr);
    die;
} else {
    printf(" OK.\n");
}

printf("Connecting to MariaDB database...");
$maria_dbh = DBI->connect("dbi:mysql:database=" . $maria_db . ";host=localhost", $maria_user, $maria_pass);
if ( ! defined($maria_dbh) ) {
    printf(" failed:\n%s\n", $maria_dbh->errstr);
    die;
} else {
    printf(" OK.\n");
}

#-------------------------------------------------------------------------------
# Handle bayes_seen table.

if ( defined($options{s}) ) {
    printf("Copying bayes_seen table...\n");

    # Prepare statements.
    $maria_sth = $maria_dbh->prepare("SELECT id, msgid, flag FROM bayes_seen");
    if (defined($maria_dbh->errstr)) {
        printf("Bayes Seen: Source SQL preparation error: %s\n", $maria_dbh->errstr);
        die;
    }
    $odbc_sth = $odbc_dbh->prepare("INSERT INTO bayes_seen (id, msgid, flag) VALUES (?, ?, ?)");
    if (defined($odbc_dbh->errstr)) {
        printf("Bayes Seen: Destination SQL preparation error: %s\n", $odbc_dbh->errstr);
        die;
    }

    if ( defined($options{T}) ) {
        # Clear destination table.
        $odbc_dbh->do("TRUNCATE TABLE bayes_seen");
        if (defined($odbc_dbh->errstr)) {
            # Ignore failure to truncate an empty table.
            if ($odbc_dbh->errstr ne '[IBM][System i Access ODBC Driver][DB2 for i5/OS]SQL0100 - Row not found for TRUNCATE. (SQL-01000)') {
                printf("Bayes Seen: Error truncating destination table: %s\n", $odbc_dbh->errstr);
                die;
            }
        }
    }

    # Execute source SQL.
    $maria_sth->execute();
    if (defined($maria_dbh->errstr)) {
        printf("Bayes Seen: Source SQL execution error: %s\n", $maria_dbh->errstr);
        die;
    }

    # Loop over source records, insert into destination records.
    while ( ($id, $msgid, $flag) = $maria_sth->fetchrow ) {
        if (defined($maria_dbh->errstr)) {
            printf("Bayes Seen: Source SQL fetch error: %s\n", $maria_dbh->errstr);
            die;
        }

        $odbc_sth->execute($id, $msgid, $flag);
        if (defined($odbc_dbh->errstr)) {
            printf("Bayes Seen: Destination SQL execution error: %s\n", $odbc_dbh->errstr);
            die;
        }
    }

    # Cleanup for now.
    if ( $odbc_sth ) {
        $odbc_sth->finish;
    }
    if ( $maria_sth ) {
        $maria_sth->finish;
    }
}

#-------------------------------------------------------------------------------
# Handle bayes_token table.

if ( defined($options{t}) ) {
    printf("Copying bayes_token table...\n");

    # Prepare statements.
    $maria_sth = $maria_dbh->prepare("SELECT id, token, spam_count, ham_count, atime FROM bayes_token");
    if (defined($maria_dbh->errstr)) {
        printf("Bayes Token: Source SQL preparation error: %s\n", $maria_dbh->errstr);
        die;
    }
    $odbc_sth = $odbc_dbh->prepare("INSERT INTO bayes_token (id, token, spam_count, ham_count, atime) VALUES (?, ?, ?, ?, ?)");
    if (defined($odbc_dbh->errstr)) {
        printf("Bayes Token: Destination SQL preparation error: %s\n", $odbc_dbh->errstr);
        die;
    }

    if ( defined($options{T}) ) {
        # Clear destination table.
        $odbc_dbh->do("TRUNCATE TABLE bayes_token");
        if (defined($odbc_dbh->errstr)) {
            # Ignore failure to truncate an empty table.
            if ($odbc_dbh->errstr ne '[IBM][System i Access ODBC Driver][DB2 for i5/OS]SQL0100 - Row not found for TRUNCATE. (SQL-01000)') {
                printf("Bayes Token: Error truncating destination table: %s\n", $odbc_dbh->errstr);
                die;
            }
        }
    }

    # Execute source SQL.
    $maria_sth->execute();
    if (defined($maria_dbh->errstr)) {
        printf("Bayes Token: Source SQL execution error: %s\n", $maria_dbh->errstr);
        die;
    }

    # Loop over source records, insert into destination records.
    while ( ($id, $token, $spam_count, $ham_count, $atime) = $maria_sth->fetchrow ) {
        if (defined($maria_dbh->errstr)) {
            printf("Bayes Token: Source SQL fetch error: %s\n", $maria_dbh->errstr);
            die;
        }

        $odbc_sth->execute($id, $token, $spam_count, $ham_count, $atime);
        if (defined($odbc_dbh->errstr)) {
            printf("Bayes Token: Destination SQL execution error: %s\n", $odbc_dbh->errstr);
            die;
        }
    }

    # Cleanup for now.
    if ( $odbc_sth ) {
        $odbc_sth->finish;
    }
    if ( $maria_sth ) {
        $maria_sth->finish;
    }
}

#-------------------------------------------------------------------------------
# Handle bayes_vars table.

if ( defined($options{v}) ) {
    printf("Copying bayes_vars table...\n");

    # Prepare statements.
    $maria_sth = $maria_dbh->prepare(
        "SELECT id, username, spam_count, ham_count, token_count, last_expire, last_atime_delta, last_expire_reduce,
            oldest_token_age, newest_token_age FROM bayes_vars"
    );
    if (defined($maria_dbh->errstr)) {
        printf("Bayes Vars: Source SQL preparation error: %s\n", $maria_dbh->errstr);
        die;
    }
    $odbc_sth = $odbc_dbh->prepare("
        INSERT INTO bayes_vars (id, username, spam_count, ham_count, token_count, last_expire, last_atime_delta, last_expire_reduce,
            oldest_token_age, newest_token_age) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );
    if (defined($odbc_dbh->errstr)) {
        printf("Bayes Vars: Destination SQL preparation error: %s\n", $odbc_dbh->errstr);
        die;
    }

    if ( defined($options{T}) ) {
        # Clear destination table.
        $odbc_dbh->do("TRUNCATE TABLE bayes_vars");
        if (defined($odbc_dbh->errstr)) {
            # Ignore failure to truncate an empty table.
            if ($odbc_dbh->errstr ne '[IBM][System i Access ODBC Driver][DB2 for i5/OS]SQL0100 - Row not found for TRUNCATE. (SQL-01000)') {
                printf("Bayes Vars: Error truncating destination table: %s\n", $odbc_dbh->errstr);
                die;
            }
        }
    }

    # Execute source SQL.
    $maria_sth->execute();
    if (defined($maria_dbh->errstr)) {
        printf("Bayes Vars: Source SQL execution error: %s\n", $maria_dbh->errstr);
        die;
    }

    # Loop over source records, insert into destination records.
    while ( ($id, $username, $spam_count, $ham_count, $token_count, $last_expire, $last_atime_delta, $last_expire_reduce,
                $oldest_token_age, $newest_token_age) = $maria_sth->fetchrow ) {
        if (defined($maria_dbh->errstr)) {
            printf("Bayes Vars: Source SQL fetch error: %s\n", $maria_dbh->errstr);
            die;
        }

        $odbc_sth->execute($id, $username, $spam_count, $ham_count, $token_count, $last_expire, $last_atime_delta, $last_expire_reduce,
                $oldest_token_age, $newest_token_age);
        if (defined($odbc_dbh->errstr)) {
            printf("Bayes Vars: Destination SQL execution error: %s\n", $odbc_dbh->errstr);
            die;
        }
    }

    # Cleanup for now.
    if ( $odbc_sth ) {
        $odbc_sth->finish;
    }
    if ( $maria_sth ) {
        $maria_sth->finish;
    }
}

#-------------------------------------------------------------------------------
# Handle txrep table.

if ( defined($options{r}) ) {
    printf("Copying txrep table...\n");

    # Prepare statements.
    $maria_sth = $maria_dbh->prepare("SELECT username, email, ip, msgcount, totscore, signedby, last_hit FROM txrep");
    if (defined($maria_dbh->errstr)) {
        printf("Txrep: Source SQL preparation error: %s\n", $maria_dbh->errstr);
        die;
    }
    $odbc_sth = $odbc_dbh->prepare("
        INSERT INTO txrep (username, email, ip, msgcount, totscore, signedby, last_hit) VALUES (?, ?, ?, ?, ?, ?, ?)"
    );
    if (defined($odbc_dbh->errstr)) {
        printf("Txrep: Destination SQL preparation error: %s\n", $odbc_dbh->errstr);
        die;
    }

    if ( defined($options{T}) ) {
        # Clear destination table.
        $odbc_dbh->do("TRUNCATE TABLE txrep");
        if (defined($odbc_dbh->errstr)) {
            # Ignore failure to truncate an empty table.
            if ($odbc_dbh->errstr ne '[IBM][System i Access ODBC Driver][DB2 for i5/OS]SQL0100 - Row not found for TRUNCATE. (SQL-01000)') {
                printf("Txrep: Error truncating destination table: %s\n", $odbc_dbh->errstr);
                die;
            }
        }
    }

    # Execute source SQL.
    $maria_sth->execute();
    if (defined($maria_dbh->errstr)) {
        printf("Txrep: Source SQL execution error: %s\n", $maria_dbh->errstr);
        die;
    }

    # Loop over source records, insert into destination records.
    while ( ($username, $email, $ip, $msgcount, $totscore, $signedby, $last_hit) = $maria_sth->fetchrow ) {
        if (defined($maria_dbh->errstr)) {
            printf("Txrep: Source SQL fetch error: %s\n", $maria_dbh->errstr);
            die;
        }

        # Convert timestamp formatting.
        $last_hit =~ /^([[:digit:]-]{10}) ([[:digit:]]{2}):([[:digit:]]{2}):([[:digit:]]{2})$/;
        $last_hit = sprintf("%s-%s.%s.%s.000000", $1, $2, $3, $4);

        $odbc_sth->execute($username, $email, $ip, $msgcount, $totscore, $signedby, $last_hit);
        if (defined($odbc_dbh->errstr)) {
            printf("Txrep: Destination SQL execution error: %s\n", $odbc_dbh->errstr);
            die;
        }
    }

    # Cleanup for now.
    if ( $odbc_sth ) {
        $odbc_sth->finish;
    }
    if ( $maria_sth ) {
        $maria_sth->finish;
    }
}

#-------------------------------------------------------------------------------
# Handle final cleanup.

if ( defined($options{s}) || defined($options{t}) || defined($options{v}) || defined($options{r}) ) {
    printf("Committing all changes...\n");
    $odbc_dbh->do("commit");
    if (defined($odbc_dbh->errstr)) {
        printf("Destination commit error: %s\n", $odbc_dbh->errstr);
    }
}

# Clean up after ourselves.
if ( $odbc_dbh ) {
	$odbc_dbh->disconnect;
}
if ( $maria_dbh ) {
    $maria_dbh->disconnect;
}

#-----------------------------------------------------------------------------------------------------------------------------------
# vim: tabstop=4 shiftwidth=4 autoindent colorcolumn=133 expandtab textwidth=132
# -EOF-
