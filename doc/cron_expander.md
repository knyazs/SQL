# cron_expander.sql

The [cron](https://en.wikipedia.org/wiki/Cron) command-line utility, also known as cron job, is a job scheduler on Unix-like operating systems.

The code sample implements cron expander functionality using pure T-SQL code, where it  calculates previous, next and second to next value for a given set of crons.

Code can convert multiple crons at the same time and, as expected, duration increasaes with adding more crons. Some statistics based on 20 crons:

Client statistics:

![image](https://user-images.githubusercontent.com/21186130/159681573-eae64161-301f-4cb8-af25-3e6be187894e.png)

Query statistics:

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 9703 ms, elapsed time = 9826 ms.

(17 rows affected)
Table 'Worktable'. Scan count 264, logical reads 4483020, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

(1 row affected)

 SQL Server Execution Times:
   CPU time = 46688 ms,  elapsed time = 8825 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

Completion time: 2022-03-23T16:23:35.4817602+04:00
