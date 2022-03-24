
/* =============================================
 Author:      Miljan Radovic
 Create date: 2022-03-22
 Description: Simple T-SQL Cron expander.
   The cron command-line utility, also known as cron job, is a job scheduler on Unix-like operating systems.
   The code sample implements cron expander functionality using pure T-SQL code, where it calculates previous, next and potentially second to next value for a given set of crons.
   Code can convert multiple crons at the same time and, as expected, duration increasaes with adding more crons.
============================================= */

-- * = any value
-- , value list separator
-- - range of values
-- / step values

-- minute allowed values 0-59
-- hour allowed values 0-23
-- day_of_month allowed values 1-31
-- month allowed values 1-12
-- day_of_week allowed values 0-6

-- Clear cache to get consistent times
DBCC FREEPROCCACHE

if OBJECT_ID ('tempdb..#expand_all') is not null
	drop table #expand_all

-- cron samples
;WITH crons as (
	select '0,14/15 * * * 2' as cron
	union all
	select '13 4 * * *' as cron
	union all
	select '5 0/11 * * 2/2' as cron
	union all
	select '5 0 * 8 *' as cron
	union all
	select '15 14 1 * *' as cron
	union all
	select '0 22 * * 1-5' as cron
	union all
	select '23 0-20/2 * * *' as cron
	union all
	select '0 0,12 1 */2 *' as cron
	union all
	select '0 4 8-14 * *' as cron
	union all
	select '0 0 1,15 * 3' as cron
	union all
	select '11 0/2 * * 1-5' as cron
	union all
	select '0/15 0/3 * * 1-6' as cron
	union all
	select '10 0/4 1 * *' as cron
	union all
	select '1-10,15/5 6-14/2 1-10 3-10 *' as cron
	union all
	select '14 6 * 1/3 1-5' as cron
	union all
	select '13 13 1/3 * *' as cron
	union all
	select '* * * * *' as cron
)
, lv0 AS (SELECT 0 g UNION ALL SELECT 0)
, lv1 AS (SELECT 0 g FROM lv0 a CROSS JOIN lv0 b) -- 4
, lv2 AS (SELECT 0 g FROM lv1 a CROSS JOIN lv1 b) -- 16
, lv3 AS (SELECT 0 g FROM lv2 a CROSS JOIN lv2 b) -- 256
, Tally (n) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM lv3)

-- Cron standard part range definitions
, cron_parts as (
	select top 60 cast(1 as smallint) as idx, 'minute' as part_name, cast(n-1 as smallint) as [value]
	from Tally
	union all
	select top 24 2 as idx, 'hour', cast(n-1 as smallint)
	from Tally
	union all
	select top 31 3 as idx, 'day_of_month', cast(n as smallint)
	from Tally
	union all
	select top 12 4 as idx, 'month', cast(n as smallint)
	from Tally
	union all
	select top 7 5 as idx, 'day_of_week', cast(n-1 as smallint)
	from Tally
)
-- Gets min and max values for each cron part
, cron_parts_ranges as (
	select idx, part_name, min([value]) as min_value, max([value]) as max_value
	from cron_parts
	group by idx, part_name
)
-- Expands all 5 cron parts
, expand_parts as (
	select c.*, p.value, cast(row_number() over (partition by c.cron order by (select null)) as smallint) as idx
	from crons as c
	cross apply string_split(c.cron, ' ') as p
)
-- Expands value list ','
, expand_commas as (
	select p.idx, p.cron,v.value
	from expand_parts as p
	cross apply string_split(p.value, ',') as v
)
-- Expands steps '/'
, expand_steps as (
		select 
		c.idx,
		c.cron,
		c.value as cron_part,
		case
			when c.value like '%/%' then substring(c.value, 0, charindex('/', c.value))
			else c.value
		end as [value],
		cast(
			case
				when c.value like '%/%' then substring(c.value, charindex('/', c.value) + 1, 1000)
			end as smallint)
		as [step]
	from expand_commas as c
)

-- Expands ranges '-'
, expand_ranges as (
	select 
		c.idx,
		c.cron,
		c.value as cron_part,
		cast (
			case
				when c.value like '%-%' then substring(c.value, 0, charindex('-', c.value))
				when c.value = '*' then null -- to be able to convert value to smallint
				else c.value
			end as smallint)
		as [value],
		cast(
			case
				when c.value like '%-%' then substring(c.value, charindex('-', c.value) + 1, 1000)
			end
			as smallint)
		as [range],
		[step]
	from expand_steps as c
)
-- Expands all together (in physical table for better performance)
--, expand_all as (
	select rs.idx, rs.cron, rs.cron_part, cp.part_name, cast(cp.value as smallint) as [value]
	into #expand_all
	from expand_ranges as rs
	inner join cron_parts_ranges cr
		on rs.idx = cr.idx
	inner join cron_parts as cp
		on rs.idx = cp.idx
		and (
			(rs.range is not null and cp.[value] between isnull(rs.value, cp.value) and rs.[range])
			or
			(rs.range is null and rs.step is null and cp.value = isnull(rs.value, cp.value))
			or
			(rs.range is null and rs.step is not null)
		)
		and (
			(rs.step is not null and cr.min_value = cp.[value] % rs.[step] 	and cp.[value] >= isnull(rs.value, cp.value))
			or
			(rs.step is null)		
		)
--)

-- Create index for better performance
create clustered index ix_expand_all_cron on #expand_all(cron)

-- Dummy up years to use in datetime
;with years as (
	select year(getdate()) - 1 as [year]
	union all
	select year(getdate())
	union all
	select year(getdate()) + 1
)
, dist_crons as (
	select distinct cron
	from #expand_all
)
-- Form datetime values from date time parts
, expand_times as (
	select c.cron, y.[year], m.value as month, d.value as day, h.value as hour, n.value as minute, try_cast(cast(y.[year] as varchar(50)) + '-' + cast(m.value as varchar) + '-' + cast(d.value as varchar) + ' ' + cast(h.value as varchar) + ':' + cast(n.value as varchar) + ':00' as datetime) as [datetime]
	from dist_crons as c
	cross apply years as y
	cross apply #expand_all as m
	cross apply #expand_all as d
	cross apply #expand_all as h
	cross apply #expand_all as n
	cross apply #expand_all as w
	where m.cron = c.cron and m.part_name = 'month'
		and d.cron = c.cron and d.part_name = 'day_of_month' 
		and h.cron = c.cron and h.part_name = 'hour' 
		and n.cron = c.cron and n.part_name = 'minute' 
		and w.cron = c.cron and w.part_name = 'day_of_week' 
		and datepart(dw, try_cast(cast(y.[year] as varchar(50)) + '-' + cast(m.value as varchar) + '-' + cast(d.value as varchar) as date)) - 1 = w.[value]
)
, prev_next as (
	select cron, 'prev' as type, max([datetime]) as [datetime]
	from expand_times
	where [datetime] < getdate()
	group by cron
	union all
	select cron, 'next', min([datetime])
	from expand_times
	where [datetime] > getdate()
	group by cron
)


-- Pivot rows into column to get prev and next as columns, not column values
--, pivotted as (
	SELECT cron, prev, next
	FROM  
	(
	  SELECT * FROM prev_next
	) AS SourceTable  
	PIVOT  
	(  
	  max(datetime)  
	  FOR type IN ([prev], [next])  
	) AS PivotTable
--)

/*
-- Uncomment code below and cte above if you are interested in second next value
select p.cron, p.prev, p.[next], min([datetime]) as [then]
from pivotted as p
inner join expand_dates as e
	on p.cron = e.cron
	and e.[datetime] > p.[next]
group by p.cron, p.prev, p.[next]
	*/
