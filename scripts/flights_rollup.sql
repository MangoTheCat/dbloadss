SELECT sim_id
      ,origin
	  ,avg(fd.dep_delay) as mean_delay
  FROM dbo.flightdelays fd
  LEFT JOIN dbo.flights fs on fd.id = fs.id
  GROUP BY sim_id, origin