use [ml];

DROP PROC IF EXISTS generate_random_data;
GO
CREATE PROC generate_random_data(@nrow int)
AS
BEGIN
 EXEC sp_execute_external_script
       @language = N'R'  
     , @script = N'  
          library(dbload)
          random_data <- random_data_set(n_rows = nrow_r, n_cols = 5)
' 
     , @input_data_1 = N' '
	 , @input_data_1_name = N'input_data'
     , @output_data_1_name = N'random_data'
	 , @params = N'@nrow_r int'
	 , @nrow_r = @nrow
    WITH RESULT SETS ((
	    "COL_1" float not null,   
        "COL_2" float not null,  
        "COL_3" float not null,   
        "COL_4" float not null,
		"COL_5" float not null)); 
END;
GO