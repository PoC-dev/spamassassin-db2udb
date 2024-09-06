## Findings with different hardware
Database size:
- AWL: 2,600 entries.
- Bayes: 600,000 tokens, 590,000 seen.

Tests have shown that my AS/400 9401 Model 150 can handle a one-mail-at-a-time combined awl and Bayes workload with a scan time between 5 seconds for ham mails and around 60 seconds for already known spam mails. Messages which have to be trained due to autolearn can easily take three minutes and more.  As soon as more than one message comes in while another one is processed, contention will occur. The 150 will stay at 100% CPU for many minutes while trying to process parallel work. Eventually, the time intensive learning will run into a hard coded timeout of five minutes.

While placing just the AWL there is working fairly good, placing the Bayes DB in addition is too much for even small sites. Even multiple indexes for different types of queries make no difference. Once parallel processing kicks in, it's game over. This can happen easily when mails come in more frequently than every 5 minutes or so.

Tests with a 9406 model 800 look much more promising. Spam mails with high scores take around 10-15 seconds to be scanned.

----

08-2021 poc@pocnet.net
