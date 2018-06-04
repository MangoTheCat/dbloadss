use ml;

DROP VIEW IF EXISTS flights_roll_origin;

CREATE VIEW flights_roll_origin AS

WITH gp AS (
SELECT sim_id
      ,origin
	  ,day_date
	  ,avg(fd.dep_delay) as mean_delay
	  ,count(fd.dep_delay) as n_flights
	  ,max(fd.dep_delay) as max_delay
	  ,min(fd.dep_delay) as min_delay
  FROM dbo.flightdelays fd
  LEFT JOIN (SELECT *, convert(date, time_hour) as day_date FROM dbo.flights) fs on fd.id = fs.id
  GROUP BY sim_id, origin, day_date  
)

SELECT day_date, origin
     , avg(mean_delay) as mean_delay
     , min(mean_delay) as min_delay
	 , max(mean_delay) as max_delay
FROM gp
GROUP BY day_date, origin
