
-- hierarchie tables: Assessment_Layouts > Assessment_LayoutSections > Assessment_LayoutDesignElements
-- will delete a default layout from hierarchie tables and insert the scripted out data from other db. with the same hierarchie tables 
--run this will give the script to run on other db


DECLARE @Assessment_LayoutDesignElements TABLE (
	[DesignElementID] [int] IDENTITY(1,1) NOT NULL,
	[LayoutID_FK] [int] NOT NULL,
	[PrimarySectionID] [int] NOT NULL,
	[Title] [varchar](100) NOT NULL,
	[Type] [smallint] NOT NULL,
	[SectionID_FK] [int] NOT NULL,
	[ParentElementID_FK] [int] NOT NULL,
	[Order] [smallint] NOT NULL,
	[EntryStamp] [datetime] NOT NULL,
	[UserID_FK] [int] NOT NULL, 
	[exDesignElementID] [int]
)

--DECLARE @NewDesignIDlist TABLE (exDesignElementID INT, DesignElementID_NEW INT) 

DECLARE @Layout NVARCHAR(max)
DECLARE @LayoutSection NVARCHAR(max)
DECLARE @LayoutDesignElements1 NVARCHAR(max)
DECLARE @LayoutDesignElements2 NVARCHAR(max)
DECLARE @LayoutDesignElements3 NVARCHAR(max)
DECLARE @LayoutDesignElements4 NVARCHAR(max)
DECLARE @LayoutDesignElements5 NVARCHAR(max)
DECLARE @LayoutDesignElements6 NVARCHAR(max)
DECLARE @LayoutDesignElements7 NVARCHAR(max)
DECLARE @WatchOut VARCHAR(200)
DECLARE @UpdateElements NVARCHAR(max)

DECLARE @FirstAssessment TINYINT

SET @Layout = ''
SET @LayoutSection = ''
SET @LayoutDesignElements1 = ''
SET @LayoutDesignElements2 = ''
SET @LayoutDesignElements3 = ''
SET @LayoutDesignElements4 = ''
SET @LayoutDesignElements5 = ''
SET @LayoutDesignElements6 = ''
SET @LayoutDesignElements7 = ''
SET @UpdateElements = '' 
SET @FirstAssessment = 1 -- the id of default layout for assessment

SET NOCOUNT ON

--temp table to divide in group when inserting
INSERT INTO @Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK, exDesignElementID)
SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), 1, DesignElementID FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = @FirstAssessment

-- @LayoutDesignElements<?> is created to be able to get all rows from APPS.Assessment_LayoutDesignElements by using small chuncks
SELECT @WatchOut = '-- Make sure @LayoutDesignElements<?> handles this count: ' + CONVERT(VARCHAR(3),COUNT(*)) + Char(13)  + Char(13) FROM @Assessment_LayoutDesignElements

SET @Layout = 'IF NOT EXISTS (SELECT 1 FROM APPS.Assessment_Layouts WHERE LayoutID = 1) ' 

SET @Layout = @Layout + Char(13) + 'BEGIN' + Char(13)

SET @Layout = @Layout + Char(9) + 'SET IDENTITY_INSERT Apps.Assessment_Layouts ON ' + Char(13) + Char(13) 

SELECT @Layout = @Layout + Char(9) + 
	'INSERT INTO Apps.Assessment_Layouts (LayoutID, Name, PatientAgeMin, PatientAgeMax, Active, AgeType, Description, EntryStamp, UserID_FK) ' + Char(13) + Char(9) +  
	--SELECT LayoutID, Name, PatientAgeMin, PatientAgeMax, Active, AgeType, Description, GETDATE(), UserID_FK  FROM APPS.Assessment_Layouts WHERE LayoutID = 1
	'SELECT 1, ''' + Name + ''', '  + CONVERT(VARCHAR(6),PatientAgeMin ) + ', ' + CONVERT(VARCHAR(3),PatientAgeMax )+ ', ' + CONVERT(VARCHAR(1),Active )+ ', ' + CONVERT(VARCHAR(4),AgeType )+ ', ''' + Description + ''', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM APPS.Assessment_Layouts WHERE LayoutID = @FirstAssessment

SET @Layout = @Layout + Char(9) + 'SET IDENTITY_INSERT Apps.Assessment_Layouts OFF'   

SET @Layout = @Layout + Char(13) + 'END' + Char(13) 

SET @LayoutSection = @LayoutSection + 'DELETE FROM APPS.Assessment_LayoutSections WHERE LayoutID_FK = 1 ' + Char(13) + Char(13) 

SELECT @LayoutSection = @LayoutSection + 
	'INSERT INTO Apps.Assessment_LayoutSections ' + Char(13) + Char(9) +  
	--	SELECT 1, SectionID_FK, Required, GETDATE(), UserID_FK  FROM APPS.Assessment_LayoutSections WHERE LayoutID_FK = 1
	'SELECT 1, ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', '  + CONVERT(VARCHAR(1),Required ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM APPS.Assessment_LayoutSections WHERE LayoutID_FK = @FirstAssessment

SET @LayoutDesignElements1 = @LayoutDesignElements1 + 'DELETE FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 1 ' + Char(13) + Char(13) 

SET @LayoutDesignElements1 = @LayoutDesignElements1 + 'DECLARE @NewDesignIDlist TABLE (DesignElementID_NEW INT, exDesignID INT, exParent INT) ' + Char(13) + Char(13)  

SELECT @LayoutDesignElements1 = @LayoutDesignElements1 + 
	'INSERT INTO Apps.Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK) ' + Char(13) + Char(9) + 
	'OUTPUT inserted.DesignElementID, ' + CONVERT(VARCHAR(11),exDesignElementID )  + ',' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ' INTO @NewDesignIDlist ' + Char(13) +
	-- SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), UserID_FK FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 3
	'SELECT 1, ' + CONVERT(VARCHAR(11),PrimarySectionID )  + ', ''' + Title + ''', ' + CONVERT(VARCHAR(6),Type ) + ', ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', ' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ', '  + CONVERT(VARCHAR(6),[Order] ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM @Assessment_LayoutDesignElements WHERE DesignElementID BETWEEN 1 AND 12
	
SELECT @LayoutDesignElements2 = @LayoutDesignElements2 + 
	'INSERT INTO Apps.Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK) ' + Char(13) + Char(9) + 
	'OUTPUT inserted.DesignElementID, ' + CONVERT(VARCHAR(11),exDesignElementID )  + ',' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ' INTO @NewDesignIDlist ' + Char(13) +
	-- SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), UserID_FK FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 3
	'SELECT 1, ' + CONVERT(VARCHAR(11),PrimarySectionID )  + ', ''' + Title + ''', ' + CONVERT(VARCHAR(6),Type ) + ', ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', ' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ', '  + CONVERT(VARCHAR(6),[Order] ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM @Assessment_LayoutDesignElements WHERE DesignElementID BETWEEN 13 AND 24

SELECT @LayoutDesignElements3 = @LayoutDesignElements3 + 
	'INSERT INTO Apps.Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK) ' + Char(13) + Char(9) + 
	'OUTPUT inserted.DesignElementID, ' + CONVERT(VARCHAR(11),exDesignElementID )  + ',' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ' INTO @NewDesignIDlist ' + Char(13) +
	-- SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), UserID_FK FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 3
	'SELECT 1, ' + CONVERT(VARCHAR(11),PrimarySectionID )  + ', ''' + Title + ''', ' + CONVERT(VARCHAR(6),Type ) + ', ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', ' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ', '  + CONVERT(VARCHAR(6),[Order] ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM @Assessment_LayoutDesignElements WHERE DesignElementID BETWEEN 25 AND 36

SELECT @LayoutDesignElements4 = @LayoutDesignElements4 + 
	'INSERT INTO Apps.Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK) ' + Char(13) + Char(9) + 
	'OUTPUT inserted.DesignElementID, ' + CONVERT(VARCHAR(11),exDesignElementID )  + ',' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ' INTO @NewDesignIDlist ' + Char(13) +
	-- SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), UserID_FK FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 3
	'SELECT 1, ' + CONVERT(VARCHAR(11),PrimarySectionID )  + ', ''' + Title + ''', ' + CONVERT(VARCHAR(6),Type ) + ', ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', ' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ', '  + CONVERT(VARCHAR(6),[Order] ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM @Assessment_LayoutDesignElements WHERE DesignElementID BETWEEN 37 AND 48

SELECT @LayoutDesignElements5 = @LayoutDesignElements5 + 
	'INSERT INTO Apps.Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK) ' + Char(13) + Char(9) + 
	'OUTPUT inserted.DesignElementID, ' + CONVERT(VARCHAR(11),exDesignElementID )  + ',' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ' INTO @NewDesignIDlist ' + Char(13) +
	-- SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), UserID_FK FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 3
	'SELECT 1, ' + CONVERT(VARCHAR(11),PrimarySectionID )  + ', ''' + Title + ''', ' + CONVERT(VARCHAR(6),Type ) + ', ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', ' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ', '  + CONVERT(VARCHAR(6),[Order] ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM @Assessment_LayoutDesignElements WHERE DesignElementID BETWEEN 49 AND 60

SELECT @LayoutDesignElements6 = @LayoutDesignElements6 + 
	'INSERT INTO Apps.Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK) ' + Char(13) + Char(9) + 
	'OUTPUT inserted.DesignElementID, ' + CONVERT(VARCHAR(11),exDesignElementID )  + ',' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ' INTO @NewDesignIDlist ' + Char(13) +
	-- SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), UserID_FK FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 3
	'SELECT 1, ' + CONVERT(VARCHAR(11),PrimarySectionID )  + ', ''' + Title + ''', ' + CONVERT(VARCHAR(6),Type ) + ', ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', ' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ', '  + CONVERT(VARCHAR(6),[Order] ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM @Assessment_LayoutDesignElements WHERE DesignElementID BETWEEN 61 AND 72

SELECT @LayoutDesignElements7 = @LayoutDesignElements7 + 
	'INSERT INTO Apps.Assessment_LayoutDesignElements (LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], EntryStamp, UserID_FK) ' + Char(13) + Char(9) + 
	'OUTPUT inserted.DesignElementID, ' + CONVERT(VARCHAR(11),exDesignElementID )  + ',' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ' INTO @NewDesignIDlist ' + Char(13) +
	-- SELECT LayoutID_FK, PrimarySectionID, Title, Type, SectionID_FK, ParentElementID_FK, [Order], GETDATE(), UserID_FK FROM APPS.Assessment_LayoutDesignElements WHERE LayoutID_FK = 3
	'SELECT 1, ' + CONVERT(VARCHAR(11),PrimarySectionID )  + ', ''' + Title + ''', ' + CONVERT(VARCHAR(6),Type ) + ', ' + CONVERT(VARCHAR(11),SectionID_FK )  + ', ' + CONVERT(VARCHAR(11),ParentElementID_FK )  + ', '  + CONVERT(VARCHAR(6),[Order] ) + ', ''' + CONVERT(VARCHAR(24),GETDATE() )+ ''', ' + CONVERT(VARCHAR(11),1 ) + Char(13) + Char(13) FROM @Assessment_LayoutDesignElements WHERE DesignElementID BETWEEN 73 AND 84

SELECT @UpdateElements = 'UPDATE a SET ParentElementID_FK = coalesce(p0.DesignElementID_NEW, p1.DesignElementID_NEW,0 ) ' + Char(13) + Char(9) +
	'FROM apps.Assessment_LayoutDesignElements a ' +
	'LEFT JOIN (select exDesignID,DesignElementID_NEW from @NewDesignIDlist where exparent = 0) p0 on a.ParentElementID_FK = p0.exDesignID ' +
	'LEFT JOIN (select exDesignID,DesignElementID_NEW from @NewDesignIDlist where exDesignID not in (select exDesignID from @NewDesignIDlist where exparent = 0)) p1 on a.ParentElementID_FK = p1.exDesignID ' 

PRINT @WatchOut 

PRINT @Layout

PRINT @LayoutSection

PRINT @LayoutDesignElements1

PRINT @LayoutDesignElements2

PRINT @LayoutDesignElements3

PRINT @LayoutDesignElements4

PRINT @LayoutDesignElements5

PRINT @LayoutDesignElements6

PRINT @LayoutDesignElements7

PRINT @UpdateElements



