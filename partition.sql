USE CONCUNG
GO
-- Tạo partition phân đoạn theo tổng tiền từng đơn hàng (tổng tiền <= 10000.000,
-- 10000.000 <giá bán <=30000.000, 30000.000< giá bán <= 50000.000, giá bán > 50000.000)

-- tao file group
ALTER DATABASE CONCUNG ADD FILEGROUP FG1
ALTER DATABASE CONCUNG ADD FILEGROUP FG2
ALTER DATABASE CONCUNG ADD FILEGROUP FG3
ALTER DATABASE CONCUNG ADD FILEGROUP FG4

-- tao data file
ALTER DATABASE [CONCUNG]
ADD FILE 
(
	NAME = N'FG1',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\FG1.ndf',
	Size = 80MB,
	MaxSize = 2200,
	FileGrowth = 1024MB 
)
TO FILEGROUP FG1;
GO
 
ALTER DATABASE [CONCUNG]
ADD FILE 
(
	NAME = N'FG2',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\FG2.ndf',
	Size = 80MB,
	MaxSize = 2200,
	FileGrowth = 1024MB 
)
TO FILEGROUP FG2;
GO

ALTER DATABASE [CONCUNG]
ADD FILE 
(
	NAME = N'FG3',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\FG3.ndf', 
	Size = 80MB,
	MaxSize = 2200,
	FileGrowth = 1024MB 
)
TO FILEGROUP FG3;
GO
 
ALTER DATABASE [CONCUNG]
ADD FILE 
(
	NAME = N'FG4',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\FG4.ndf',
	Size = 80MB,
	MaxSize = 2200,
	FileGrowth = 1024MB 
)
TO FILEGROUP FG4;
GO

-- Tao partition function
CREATE PARTITION FUNCTION PartFunc_1(MONEY) 
		AS RANGE LEFT FOR VALUES(10000.000, 30000.000, 50000.000)
-- Tao partition scheme
CREATE PARTITION Scheme PartScheme_1 AS PARTITION PartFunc_1 TO (FG1, FG2, FG3, FG4)

-- Kiem tra
SELECT ps.name As [Name of PS], pf.name As [Name of PF], prf.boundary_id, prf.value
FROM sys.partition_schemes ps
INNER JOIN sys.partition_functions pf ON pf.function_id = ps.function_id
INNER JOIN sys.partition_range_values prf ON pf.function_id = prf.function_id
GO

-- Chay
Select *
From DONHANG
Where $Partition.[PartFunc_1] (TONGTIEN) in (1);


