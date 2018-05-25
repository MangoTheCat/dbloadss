use [ml];

DROP TABLE IF EXISTS flightdelays;

CREATE TABLE flightdelays (
    "id" int not null,   
    "sim_id" int not null,  
    "dep_delay" float not null
);

INSERT INTO flightdelays
EXEC [dbo].[r_simulate_departure_delays] @nsim = 20