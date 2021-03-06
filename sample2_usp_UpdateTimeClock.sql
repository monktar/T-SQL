USE [SupportCalls]
GO
/****** Object:  StoredProcedure [APPS].[usp_UpdateTimeClock]    Script Date: 1/14/2020 2:43:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [APPS].[usp_UpdateTimeClock]
(
	@TimeClockID bigint Output,
	@UserID int,
	@TypeOfTime tinyint,
	@StartTime datetime,
	@EndTime DATETIME = '12/31/2019',
	@ManagementChanged bit = 0, 
	@ExceedTime BIT = 0
) as
	
BEGIN

-- Last Changed  Date: 1/14/2020 -- By: Monktar Bello -  put in TypeOfTime: PTO(101,102), NPTO(103,104), CompanyHoliday(105,106) 
-- 1/10/2020 -- By: Monktar Bello -  put in TypeOfTime 17,18,19,20,21,22 
-- 1/3/2020 -- By: Monktar Bello - I put in code for excluded group: bath belongs to that group.
-- 1/2/2020 -- By: Clyde wafford - I put in code to check to see what type of break this is to make sure the exceed value is set correct
-- 1/2/2020 -- By: Clyde wafford - I took bathroom breaks out of the break calculate total, and exclude the exceed from being set for bathroom breaks
-- 12/18/2019 -- By: Monktar BELLO - put in test about the lunch time beyond 3600secondes and fixed log
-- 12/18/2019 -- By: Clyde Wafford - I put in a default Endtime since we are getting rid of this parameter.  I also added Management Change and Exceed Time.  Put them so that they are updated with Update and inserted with Insert. 
-- 12/17/2019 -- By: Monktar Bello - put in statements to log info and fixed duration
-- 12/11/2019 - By: Monktar Bello: initial version

--Times are compared to current day 
	DECLARE @Error INT

	DECLARE @OperationType char(6)
	DECLARE @SPName varchar(50)
	DECLARE @LunchBackTime DATETIME, @FirstPunchIN DATETIME, @FirstPunchOUT DATETIME
	DECLARE @BreakLenght SMALLINT, @LunchLenght SMALLINT
	
	SET @LunchLenght = 0; SET @BreakLenght = 0; 

	SET @SPName = OBJECT_NAME(@@PROCID)

	IF (@TimeClockID > 0)
	BEGIN
		SET @OperationType = 'Update'

		UPDATE apps.TimeClock SET
			UserID = @UserID,
			TypeOfTime = @TypeOfTime,
			StartTime = @StartTime,
			EntryStamp = getdate(),
			ManagementChanged = @ManagementChanged,
			ExceedTime = @ExceedTime
		WHERE TimeClockID = @TimeClockID
	END
	ELSE
	BEGIN
		SET @OperationType = 'Insert'

		Insert into apps.TimeClock (UserID, TypeOfTime, StartTime, EndTime, EntryStamp, ManagementChanged, ExceedTime)
		Values (@UserID, @TypeOfTime, @StartTime, @StartTime, getdate(), @ManagementChanged, @ExceedTime)
		SELECT @TimeClockID = @@IDENTITY

		IF @TypeOfTime NOT IN (1,9,7,15,19,20,21,22,101,102,103,104,105,106) -- excluded Punch, bathroom, CompanyEvent, BusinessTrip...
		BEGIN
			--find the 1st punch in
			SELECT TOP 1 @FirstPunchIN = StartTime FROM apps.TimeClock  
			WHERE  UserID = @UserID 
				   AND CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),StartTime),1,11),101) = CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),GETDATE()),1,11),101)
				   AND TypeOfTime = 1 
				   AND StartTime < @StartTime ORDER BY StartTime DESC
			--find the next punch out
			SELECT TOP 1 @FirstPunchOUT = StartTime FROM apps.TimeClock  
			WHERE  UserID = @UserID 
				   AND CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),StartTime),1,11),101) = CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),GETDATE()),1,11),101)
				   AND TypeOfTime = 9 
				   AND StartTime > @StartTime ORDER BY StartTime ASC
			--Get Lunch BACK TIME
			SELECT @LunchBackTime = StartTime  
			FROM apps.TimeClock 
			WHERE UserID = @UserID AND TypeOfTime = 10 -- 10 for LunchBack
			AND CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),StartTime),1,11),101) = CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),GETDATE()),1,11),101)

			--get all events for THE user this day and this range of PunchIN and current time and < PunchOUT
			DECLARE @timeTable TABLE (UserID INT, typeOfTime tinyint, StartTime datetime, A_Group varchar(15), B_Group varchar(15))
			INSERT INTO @timeTable
			SELECT 	UserID, typeOfTime, StartTime, 
						CASE 
							WHEN typeOfTime in (1,9) THEN 'Punch'
							WHEN typeOfTime in (2,10) THEN 'Lunch'
							WHEN typeOfTime in (3,11) THEN 'G_Break'
							WHEN typeOfTime in (4,12) THEN 'Phone'
							WHEN typeOfTime in (5,13) THEN 'Coffee'
							WHEN typeOfTime in (6,14) THEN 'Smoke'
							WHEN typeOfTime in (7,15) THEN 'Bath'
							WHEN typeOfTime in (8,16) THEN 'Snack'
							WHEN typeOfTime in (17,18) THEN 'Office'
							WHEN typeOfTime in (19,20) THEN 'CompanyEvent'
							WHEN typeOfTime in (21,22) THEN 'BusinessTrip'
						END A_Group, 
						CASE 
							WHEN typeOfTime in (1,9) THEN 'PunchGrp'
							WHEN typeOfTime in (2,10) THEN 'LunchGrp'
							WHEN typeOfTime in (7,15,19,20,21,22) THEN 'ExcludGrp'
							WHEN typeOfTime in (3,4,5,6,8,11,12,13,14,16,17,18) THEN 'BreakGrp'
						END B_Group
			FROM apps.TimeClock 
			WHERE UserID = @UserID AND CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20),StartTime),1,11),101) = CONVERT(DATETIME,SUBSTRING(CONVERT(VARCHAR(20), GETDATE()),1,11),101)
				  AND StartTime >= @FirstPunchIN AND StartTime <= ISNULL(@FirstPunchOUT,StartTime)

			--begin/end of each group: punch, lunch, break
			--join on group and chronological number
			DECLARE @timeGROUP TABLE (B_Group varchar(15), StartTime datetime, EndTime datetime)
			INSERT INTO @timeGROUP
			SELECT  a.B_Group, a.StartTime, b.StartTime
			FROM 
			(SELECT UserID, typeOfTime, StartTime, A_Group,B_Group, ROW_NUMBER() OVER (PARTITION BY A_Group ORDER BY StartTime ) No FROM @timeTable a WHERE typeOfTime IN (1,2,3,4,5,6,7,8,17,19,21)) a --numbers for IN
			LEFT JOIN
			(SELECT UserID, typeOfTime, StartTime, A_Group,B_Group, ROW_NUMBER() OVER (PARTITION BY A_Group ORDER BY StartTime ) No FROM @timeTable a WHERE typeOfTime IN (9,10,11,12,13,14,15,16,18,20,22)) b --numbers for OUT
			ON A.A_Group=B.A_Group  AND  A.No=B.No 


			IF ISDATE(@LunchBackTime) = 1 BEGIN-- isdate imply that the user has already gone for that day's lunch
				--Lunch lenght
				SELECT @LunchLenght = ISNULL(SUM(DATEDIFF(ss, StartTime, EndTime)),0) FROM @timeGROUP WHERE B_Group = 'LunchGrp'
				--break lenght
				SELECT @BreakLenght = ISNULL(SUM(DATEDIFF(ss, StartTime, EndTime)),0) FROM @timeGROUP WHERE B_Group = 'BreakGrp'
					  AND StartTime > @LunchBackTime AND StartTime > @LunchBackTime
			END
			ELSE BEGIN
				--break lenght			
				SELECT @BreakLenght = ISNULL(SUM(DATEDIFF(ss, StartTime, EndTime)),0) FROM @timeGROUP WHERE B_Group = 'BreakGrp'
				
			END
			
			--DEBUG
			--SELECT @BreakLenght, @LunchLenght, @FirstPunchIN

			--max 900s=15mn of break -- 3600 of lunch
			IF (@TypeOfTime IN (2,10) and @LunchLenght > 3600) --Then this is a lunch break, did they exceed
				OR (@TypeOfTime NOT IN (2,10) and @BreakLenght > 900) --Then this is a some type of break, did they exceed
				UPDATE apps.TimeClock SET ExceedTime = 1 WHERE TimeClockID = @TimeClockID
		END
	END

	DECLARE @UserActivityLogID bigint
	SET	@UserActivityLogID = 0

	DECLARE @TableName varchar(30)
	SET	@TableName = 'TimeClock'

	DECLARE @FirstKey varchar(50)
	SET	@FirstKey = CAST(@TimeClockID AS varchar(50))
	
	DECLARE @ChangeDesc varchar(5000)
	SET @ChangeDesc = 'Adding/Updating the Punch Clock entry- Time clock ID: '+ Convert (varchar(10),@TimeClockID) + '; User ID: ' + Convert (varchar(10),@UserID) +
					  '; TypeOfTime : ' + Convert (varchar(10),@TypeOfTime) + '; Start time: ' + Convert (varchar(30),@StartTime) + 
					  '; Change by Manager: ' + Convert (varchar(1),@ManagementChanged) + '; Exceed Time: ' +  Convert (varchar(1),@ExceedTime) +
					  '; Entry time: ' + Convert (varchar(30),getdate()) + '; Lunch Back Time: ' + Convert (varchar(30),isnull(@LunchBackTime,'')) +
					  '; First Punch IN: ' + Convert (varchar(30),isnull(@FirstPunchIN,'')) + '; First Punch OUT: ' + Convert (varchar(30),isnull(@FirstPunchOUT,'')) +
					  '; Break Lenght: '+ Convert (varchar(10),@BreakLenght) + '; Lunch Lenght: '+ Convert (varchar(10),@LunchLenght)

	EXEC APPS.sp_RecordLog
		@UserActivityLogID,
		@UserID,
		@OperationType,
		@TableName,
		@FirstKey,
		NULL,
		NULL, 
		@ChangeDesc, @SPName


	Set @Error = @@error
	If (@@error <> 0) BEGIN
		RAISERROR ( 'Error Adding/Updating the Punch Clock entry into TimeClock table failed', 16, 1 )
		RETURN -2
	END

END




