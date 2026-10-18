/*

====================================================
CREATE DATABASE AND SCHEMAS
====================================================
Script Purpose:
	This script creates a new database named 'Olist_warehouse' after checking if it already exists.
	If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
	within the database: 'bronze', 'silver', and 'gold'.
	

WARNING: 
	Running this script will drop the entire 'Olist_warehouse' database if it exists.
	All data in the database will be permanently deleted. Proceed with caution 
	and ensure you have proper backups before running this script.

*/



USE MASTER;

GO

--DROP AND CREATE THE "Olist_warehouse" DATABASE
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Olist_warehouse')

BEGIN
	ALTER DATABASE Olist_warehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Olist_warehouse

END;

GO

-- CREATE THE "Olist_warehouse" database

CREATE DATABASE Olist_warehouse;
GO

USE Olist_warehouse;
GO

-- CREATE SCHEMAS

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
