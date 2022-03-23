# cron_expander.sql

The [cron](https://en.wikipedia.org/wiki/Cron) command-line utility, also known as cron job, is a job scheduler on Unix-like operating systems.

The code sample implements cron expander functionality using pure T-SQL codeand  calculates previous and next value for a given set of crons.

Code can convert multiple crons at the same time and, as expected, duration increasaes with adding more crons. Some statistics based on 20 crons
