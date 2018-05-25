use [ml];

DROP PROC IF EXISTS r_simulate_departure_delays;
GO
CREATE PROC r_simulate_departure_delays(@nsim int = 20, @split_date date = "2013-07-01")
AS
BEGIN
 EXEC sp_execute_external_script
     @language = N'R'  
   , @script = N'
          library(dbloadss)
          output_data <- simulate_departure_delays(input_data, nsim = nsim_r, split_date = split_date_r)
' 
   , @input_data_1 = N' SELECT * FROM [dbo].[flights];'
   , @input_data_1_name = N'input_data'
   , @output_data_1_name = N'output_data'
   , @params = N'@nsim_r int, @split_date_r date'
   , @nsim_r = @nsim
   , @split_date_r = @split_date
    WITH RESULT SETS ((
	    "id" int not null,   
        "sim_id" int not null,  
        "dep_delay" float not null)); 
END;
GO