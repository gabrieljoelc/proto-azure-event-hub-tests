-- This convert the period to date-time format
--SELECT 
--	AP.TestRun
--    -- note the 5, the "minute", and the starting point to convert the 
--    -- period back to original time
--    ,DATEADD(minute, AP.FiveMinutesPeriod * 1, '2010-01-01T00:00:00') AS Period
--    ,AP.AvgCount
--FROM
--    -- this groups by the period and gets the average
--    (SELECT
--		P.TestRun
--        ,P.FiveMinutesPeriod
--        ,AVG(P.Count) AS AvgCount
--    FROM
--        -- This calculates the period (five minutes in this instance)
--        (SELECT 
--			T.TestRun as TestRun
--            -- note the division by 5 and the "minute" to build the 5 minute periods
--            -- the '2010-01-01T00:00:00' is the starting point for the periods
--            ,datediff(minute, '2010-01-01T00:00:00', T.CreatedAt)/1 AS FiveMinutesPeriod
--            ,count(*) as Count
--        FROM EhTests T group by T.TestRun, datediff(minute, '2010-01-01T00:00:00', T.CreatedAt)/1) AS P
--    GROUP BY P.TestRun, P.FiveMinutesPeriod) AP
--order by AP.TestRun
--select
--TestRun
--,datediff(minute, '1990-01-01T00:00:00', createdat) /1
--,count(*) as EventCountPer
--from ehtests
--group by
--TestRun
--,datediff(minute, '1990-01-01T00:00:00', createdat) /1
--order by testrun
select
TestRun
-- this tells us the estimated duration of the test
-- which may not be accurate since some were done in parallel (would need to look at gaps as well)
,datediff(second ,min(createdat) ,max(createdat)) as TestDurtionSec
-- this tells us how many events were received
,count(1) as EventCount
-- this tells which if all distinct enqueued events were processed
,sum(distinct EnqueuedCounter) as EnqueuedCounterSum
-- estimate of enqueued events were "re-processed"
,sum(EnqueuedCounter) as EnqueuedCounterSum
from ehtests
group by testrun
order by TestRun
select
TestRun
,EnqueuedCounter
,count(1) as EnqueuedCounterDupCount
from
ehtests
group by testrun, EnqueuedCounter
having count(1) > 1
order by TestRun
SELECT TestRun,
		[Id]
      ,[PartitionKey]
      ,[PartitionKeyPrefix]
      ,[PartitionKeySuffix]
      ,[CreatedAt]
      --,[EnqueuedTimeUtc]
      ,[EnqueuedCounter]
      --,[Body]
  FROM [MedumoContext].[dbo].[EhTests]
  where testrun = 3
  order by PartitionKeyPrefix, PartitionKeySuffix asc
