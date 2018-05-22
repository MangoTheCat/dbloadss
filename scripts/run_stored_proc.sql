use [ml];

DROP TABLE IF EXISTS randData;

CREATE TABLE randData (
    COL_1 float,
	COL_2 float,
	COL_3 float,
	COL_4 float,
	COL_5 float
)

INSERT INTO randData
EXEC [dbo].[generate_random_data] @nrow = 3000000

--SELECT TOP (10) [COL_1]
--      ,[COL_2]
--      ,[COL_3]
--      ,[COL_4]
--      ,[COL_5]
--  FROM randData