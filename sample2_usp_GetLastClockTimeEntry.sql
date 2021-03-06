/****** Object:  StoredProcedure [APPS].[usp_GetLastClockTimeEntry]    Script Date: 1/19/2021 11:09:59 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [APPS].[usp_GetLastClockTimeEntry]
(
	@UserID int
)
as

BEGIN
--Last Changed -- Date: 12/17/2019 - By: Monktar Bello: return the same cloumns as [usp_GetClockTimeEntries]
-- 12/16/2019 - By: Monktar Bello: use the new logic from usp_GetClockTimeEntries to get last entry
--Example run: EXEC APPS.usp_GetLastClockTimeEntry 6

	-- cast current date
	declare @DateCast datetime
	set @DateCast = CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),GETDATE()),1,11),101)
	set @DateCast= cast(@DateCast + ' 00:00 AM' as Datetime)

	-- temp table
	declare @timeTable table (	TimeClockID bigint, UserID int, EntryStamp datetime, 	TypeOfTime tinyint,
						TypeOfTimeName varchar(50), StartTime datetime,	EndTime datetime,	Name varchar(50),	duration varchar(50),
						ExceedTime tinyint, ManagementChanged tinyint,	EndTimeClockID bigint, EndTypeOfTime tinyint,	EndTypeOfTimeName varchar(50),
						EndManagementChange tinyint, 	EndExceedTime tinyint)
	
	-- put current date entries in @timeTable
	INSERT INTO @timeTable
	EXEC [APPS].[usp_GetClockTimeEntries] @UserID, 0, @DateCast

	SELECT TOP 1 TimeClockId, UserID,EntryStamp, TypeOfTime,TypeOfTimeName, StartTime, EndTime,name ,Duration, ExceedTime, ManagementChanged,
			EndTimeClockID, EndTypeOfTime, EndTypeOfTimeName, EndManagementChange, EndExceedTime
	FROM @timeTable a
	order by TimeclockId desc

END