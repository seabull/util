--CREATE TABLE FORT_STATUS_JOB
--(
--  SessionHost VARCHAR(100) NOT NULL
--  ,SessionStartTime TIMESTAMP NOT NULL
--  ,JobId INT NOT NULL
--  ,LastStartTime TIMESTAMP NOT NULL
--  ,LastEndTime TIMESTAMP
--  ,Status VARCHAR(100) NOT NULL
--  PRIMARY KEY CLUSTERED  (SessionHost ASC, SessionStartTime DESC, JobId ASC) ON [PRIMARY] 
--)
--
--CREATE TABLE FORT_STATUS_JOB_WAVE
--(
--  SessionHost VARCHAR(100) NOT NULL
--  ,SessionStartTime TIMESTAMP NOT NULL
--  ,JobId INT NOT NULL
--  ,WaveId INT NOT NULL
--  ,LastStartTime TIMESTAMP NOT NULL
--  ,LastEndTime TIMESTAMP
--  ,Status VARCHAR(100) NOT NULL
--  PRIMARY KEY CLUSTERED  (SessionHost ASC, SessionStartTime DESC, JobId ASC, WaveId ASC) ON [PRIMARY] 
--)
--
--CREATE TABLE FORT_STATUS_JOB_WAVE_STEP
--(
--  SessionHost VARCHAR(100) NOT NULL
--  ,SessionStartTime TIMESTAMP NOT NULL
--  ,JobId INT NOT NULL
--  ,WaveId INT NOT NULL
--  ,StepId INT NOT NULL
--  ,LastStartTime TIMESTAMP NOT NULL
--  ,LastEndTime TIMESTAMP
--  ,Status VARCHAR(100) NOT NULL
--  ,RecordsAffected INT NOT NULL
--  ,ErrorText VARCHAR(500) NOT NULL
--  PRIMARY KEY CLUSTERED  (SessionHost ASC, SessionStartTime DESC, JobId ASC, WaveId ASC, StepId ASC) ON [PRIMARY] 
--)
--

------------------------------------------------
-- $Id: Fort_Log.sql,v 1.3 2011/11/03 16:57:16 a645276 Exp $
-- $Revision: 1.3 $
-- $Date: 2011/11/03 16:57:16 $
--
-- vim:set ft=SQL ts=4 sw=4 expandtab
------------------------------------------------

USE [RSCDB001]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO


CREATE TABLE dbo.FORT_STATUS_JOB
(
        SessionHost             NVARCHAR(100) NOT NULL
        ,SessionStartTime       DATETIME2 NOT NULL
        ,JobId                  INT NOT NULL
        ,LastStartTime          DATETIME2 NOT NULL
        ,LastEndTime            DATETIME2
        ,[Status]               NVARCHAR(100) NOT NULL
        --
        ,PRIMARY KEY CLUSTERED  (SessionHost ASC, SessionStartTime DESC, JobId ASC) ON [Group00] 
)


CREATE TABLE dbo.FORT_STATUS_JOB_WAVE
(
        SessionHost             NVARCHAR(100) NOT NULL
        ,SessionStartTime       DATETIME2 NOT NULL
        ,JobId                  INT NOT NULL
        ,WaveId                 INT NOT NULL
        ,LastStartTime          DATETIME2 NOT NULL
        ,LastEndTime            DATETIME2
        ,[Status]               NVARCHAR(100) NOT NULL
        --
        ,PRIMARY KEY CLUSTERED  (SessionHost ASC, SessionStartTime DESC, JobId ASC, WaveId ASC) ON [Group00] 
)

CREATE TABLE dbo.FORT_STATUS_JOB_WAVE_STEP
(
        SessionHost             NVARCHAR(100) NOT NULL
        ,SessionStartTime       DATETIME2 NOT NULL
        ,JobId                  INT NOT NULL
        ,WaveId                 INT NOT NULL
        ,StepId                 INT NOT NULL
        ,LastStartTime          DATETIME2 NOT NULL
        ,LastEndTime            DATETIME2
        ,[Status]               NVARCHAR(100) NOT NULL
        ,RecordsAffected        INT NOT NULL
        ,ErrorText              NVARCHAR(500) 
        --
        ,PRIMARY KEY CLUSTERED  (SessionHost ASC, SessionStartTime DESC, JobId ASC, WaveId ASC, StepId ASC) ON [Group00] 
)

