# cron_expander.sql

The [cron](https://en.wikipedia.org/wiki/Cron) command-line utility, also known as cron job, is a job scheduler on Unix-like operating systems.

The code sample implements cron expander functionality using pure T-SQL code, where it calculates previous, next and potentially second to next value for a given set of crons.

Code can convert multiple crons at the same time and, as expected, duration increasaes with adding more crons.

Some statistics based on **20 crons**:

## Client statistics

![image](https://user-images.githubusercontent.com/21186130/159768962-c309336a-913b-4e79-9135-8975ee4ed476.png)


## Query statistics

...

Table '#expand_all'. Scan count 0, logical reads **940**, physical reads 0

Table 'Worktable'. Scan count 104, logical reads **1745940**, physical reads 0

Table '#expand_all'. Scan count 12, logical reads 96, physical reads 0

SQL Server Execution Times: CPU time = **38015** ms,  elapsed time = **39277** ms.

...

## Server

Microsoft SQL Server 2017 (RTM-GDR) (KB4583456) - 14.0.2037.2 (X64) on Windows 10 Pro 10.0 <X64> (Build 19044: ) 
 
 
