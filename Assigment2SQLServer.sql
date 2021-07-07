
/****** Object:  Database [db_Anushi]    Script Date: 2021-07-04 4:00:50 PM ******/
CREATE DATABASE [db_Anushi]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'db_Anushi', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.HUMBERBRIDGING\MSSQL\DATA\db_Anushi.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'db_Anushi_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.HUMBERBRIDGING\MSSQL\DATA\db_Anushi_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [db_Anushi].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [db_Anushi] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [db_Anushi] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [db_Anushi] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [db_Anushi] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [db_Anushi] SET ARITHABORT OFF 
GO

ALTER DATABASE [db_Anushi] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [db_Anushi] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [db_Anushi] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [db_Anushi] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [db_Anushi] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [db_Anushi] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [db_Anushi] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [db_Anushi] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [db_Anushi] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [db_Anushi] SET  DISABLE_BROKER 
GO

ALTER DATABASE [db_Anushi] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [db_Anushi] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [db_Anushi] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [db_Anushi] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [db_Anushi] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [db_Anushi] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [db_Anushi] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [db_Anushi] SET RECOVERY FULL 
GO

ALTER DATABASE [db_Anushi] SET  MULTI_USER 
GO

ALTER DATABASE [db_Anushi] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [db_Anushi] SET DB_CHAINING OFF 
GO

ALTER DATABASE [db_Anushi] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [db_Anushi] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO

ALTER DATABASE [db_Anushi] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [db_Anushi] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO

ALTER DATABASE [db_Anushi] SET QUERY_STORE = OFF
GO

ALTER DATABASE [db_Anushi] SET  READ_WRITE 
GO


=================================================================================================================
2)
USE [db_Anushi]
GO

/****** Object:  Table [dbo].[CUSTOMER]    Script Date: 2021-07-04 4:01:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CUSTOMER](
	[CustomerID] [int] NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO

=====================================================================================================================
3)
USE [db_Anushi]
GO

/****** Object:  Table [dbo].[ORDERS]    Script Date: 2021-07-04 4:02:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ORDERS](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[OrderDate] [datetime] NOT NULL
) ON [PRIMARY]
GO
===============================================================================================================
4)
create trigger tr_deleteonorder
    on [dbo].[Customer]
    instead of delete
    as

    begin
		set nocount on
		declare @customerId int
		declare @numberOfOrders int

		select @customerId = CustomerID from deleted
		select @numberOfOrders = count(*) from Orders where CustomerID = @customerId

		if (@numberOfOrders >= 1)
			raiserror('This customer has at least one order and cannot be deleted', 2, 1);
		else
			delete from Customer where CustomerID = @customerId
	end

c)
create trigger tr_updatecust
    on [dbo].[Customer]
    instead of UPDATE
    as

	begin
		set nocount on

		declare @customerIdNew int
		declare @customerIdOld int
		declare @numberOfOrders int
		declare @orderId int

		select @customerIdOld = CustomerID from deleted
		select @customerIdNew = CustomerID from inserted
	
		select @numberOfOrders = count(*), @orderId = OrderId
		from [dbo].[Orders]
		where CustomerID = @customerIdOld
		group by OrderID

		if (@numberOfOrders > 0)
			update Orders set CustomerID = @customerIdNew where OrderID = @orderId
    end

d)
create trigger tr_insupdcustomer
    on [dbo].[Orders]
    for INSERT, UPDATE
    as

	begin
		set nocount on

		declare @customerIdNew int
		declare @customerExists int

		select @customerIdNew = CustomerID from inserted

		select @customerExists = count(*) from Customer where CustomerID = @customerIdNew
		if (@customerExists = 0)
			begin
				raiserror('The customer does not exist. Rolling back transaction', 2, 1);
				rollback transaction
			end
    end
===================================================================================================================
b)
===========================================================================
5)
USE [db_Anushi]
GO

/****** Object:  StoredProcedure [dbo].[SP_INSERTCUSTOMER]    Script Date: 2021-07-04 4:16:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[SP_INSERTCUSTOMER]
@FNAME AS NVARCHAR(50),
@LNAME AS NVARCHAR(50),
@CUSTID AS INT=null
AS
BEGIN
declare @FLAG AS BIT
declare @FN as NVARCHAR(50)=@FNAME
declare @LN as NVARCHAR(50)=@LNAME
SELECT @FLAG = (SELECT [dbo].[FN_CHECKNAME] (@FN,@LN ))
	IF @FLAG ='FALSE'
		BEGIN
			IF @CUSTID=NULL
			BEGIN
			set @CUSTID= (SELECT (MAX([CustomerID])) FROM [dbo].[CUSTOMER])
			END
		END
		ELSE
				INSERT INTO [dbo].[CUSTOMER]
				VALUES
				(@CUSTID
				,@FNAME
				,@LNAME)
				
END

exec SP_INSERTCUSTOMER
@FNAME ='Anu',
@LNAME='Anu',
@CUSTID =2

SELECT * FROM [dbo].[CUSTOMER]

DELETE FROM [dbo].[CUSTOMER]
WHERE [CustomerID]=2
GO





===================================================================================
6)
CREATE OR ALTER PROCEDURE dbo.sp_InsertCustomer @fname  NVARCHAR(MAX),

                                                @lname  NVARCHAR(MAX),

                                                @custID INT           = 0

AS

    BEGIN

        SET NOCOUNT ON;

        DECLARE @result BIT;

                                SET @result = dbo.fn_CheckName(@fname,@lname)

 

                                -- handling optional parameter custID --

        IF(@custID = 0)

            BEGIN

                SET @custID =

                (

                    SELECT MAX(CustomerID)

                    FROM Customer

                ) + 1;

        END;

 

                                -- if fname and lname are the the same insert data --

        IF(@result = 1)

            BEGIN

                INSERT INTO dbo.Customer

                (CustomerID,

                 FirstName,

                 LastName

                )

                VALUES

                (@custID,

                 @fname,

                 @lname

                );

        END;

    END;

GO

 

=============================================================================================================================

 

 

Question 7

 

SET NOCOUNT ON;

IF EXISTS

(

    SELECT TABLE_NAME

    FROM INFORMATION_SCHEMA.TABLES

    WHERE TABLE_NAME = N'CusAudit'

)

    BEGIN

        SELECT 'CusAudit Table Already Created' AS Message;

END;

    ELSE

    BEGIN

        CREATE TABLE CusAudit

        (CusAuditID INTEGER IDENTITY(1, 1) PRIMARY KEY,

         CustomerId INT NOT NULL,          

         FirstName  NVARCHAR(50) NOT NULL,

         LastName   NVARCHAR(50) NOT NULL,         

         UpdatedBy  NVARCHAR(50) NOT NULL,

         UpdatedOn  DATETIME NOT NULL,

        );

       

        SELECT 'CusAudit Table Created' AS Message;

END;

GO

-- create triggers for AFTER UPDATE and INSERT

CREATE TRIGGER CustTableUpdates ON Customer

AFTER UPDATE, INSERT

AS

     BEGIN

         SET NOCOUNT ON;

                                INSERT INTO CusAudit

         (CustomerId,

          FirstName,

          LastName,

          UpdatedBy,

          UpdatedOn

         )

                SELECT i.CustomerId,

                       i.FirstName,

                       i.LastName,

                       SUSER_NAME(),

                       GETDATE()

                FROM Customer C

                     INNER JOIN inserted i ON C.CustomerID = i.CustomerID;

     END;

GO

