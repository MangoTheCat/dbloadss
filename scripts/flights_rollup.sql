WITH gp AS (
SELECT sim_id
      ,origin
	  ,day_date
	  ,avg(fd.dep_delay) as mean_delay
	  ,count(fd.dep_delay) as n_flights
  FROM dbo.flightdelays fd
  LEFT JOIN (SELECT *, convert(date, time_hour) as day_date FROM dbo.flights) fs on fd.id = fs.id
  WHERE fs.carrier='UA'
  GROUP BY sim_id, origin, day_date
  
)

SELECT day_date, origin
     , avg(mean_delay) as mean_delay
     , min(mean_delay) as min_delay
	 , max(mean_delay) as max_delay
FROM gp
GROUP BY origin, day_date
ORDER BY day_date, origin