@rem *****************************************
@rem Set base variables
@rem *****************************************

@cls

@echo off

Setlocal EnableDelayedExpansion

rem database params

SET PGPASSWORD=14707796
SET DBNAME=dentsply_fullsb
SET DBUSER=postgres

SET ITEMTODELETE=%1

echo Deleting %1

rem salesforce params

SET READENDPOINT=https://test.salesforce.com/services/Soap/u/29.0
SET READUSERNAME=kgalant@wellspect.com.fullsb
SET READPASSWORD=ce9f52eab752286ade885e5c3c4668b8
SET WRITEENDPOINT=https://test.salesforce.com/services/Soap/u/29.0
SET WRITEUSERNAME=kgalant@wellspect.com.fullsb
SET WRITEPASSWORD=ce9f52eab752286ade885e5c3c4668b8
SET LOGPREFIX=%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%.%time:~3,2%.%time:~6,2%.%time:~9,2%
SET LOGFILE=%BASEDIR%logs\log-%LOGPREFIX%.txt
rem SET LIMIT=LIMIT 10000
SET FILEPREFIX=%1
SET BULKAPI=true
SET BATCHSIZE=5000

IF NOT DEFINED FILEPREFIX (
	SET FILEPREFIX=0*
)

rem assuming directory structure going out from the place where this batch file resides
SET BASEDIR=%~dp0
SET BASEFILEDIR=%BASEDIR%files\
SET MAPPINGDIR=%BASEDIR%mappingfiles
SET CONFIGSDIR=%BASEDIR%configs

SET CLIQ=c:\Dev\ApexDataLoader\cliq_process\
SET PSQLCMD="C:\Program Files\PostgreSQL\9.3\bin\psql.exe"
SET BATDIR=%~dp0

SET STDEXPORT=stdexport
SET STDDELETE=stddelete


SET DLPATH=c:\Dev\ApexDataLoader

@start c:\tools\baretail.exe -ws 1 -tc 4 -ti 3 %LOGFILE%


for /f %%d in ('dir /a:-d /b %BASEDIR%configs\%FILEPREFIX%') do (
   @echo Processing file %%d

	SET EXPFORDELETE=0
	SET DEL=0
   
		for /f "eol=# tokens=1,2 delims=:" %%a in (%BASEDIR%configs\%%d) do (
			SET %%a=%%b
		)
	
	@echo ******************************
	@echo !JOBDESC!
	@echo ******************************
	
rem		echo FIELDSTRING=!FIELDSTRING!
rem 	echo SOQL=!SOQL!
rem 	echo MAPPINGSOQL=!MAPPINGSOQL!
rem 	echo OLDNEWIDFILENAME=!OLDNEWIDFILENAME!
rem 	echo ENTITY=!ENTITY!
rem 	echo FIELDSTOREMAP=!FIELDSTOREMAP!
rem 	echo FILENAME=!FILENAME!
rem 	echo MAPPEDFILENAME=!MAPPEDFILENAME!
rem 	echo SFMAPPINGFILE=!SFMAPPINGFILE!
rem 	echo OBJECT=%OBJECT%


	

	IF !EXPFORDELETE!==1 (
		call :StandardExport !OBJECT! !ENTITY! "!SOQL!" !DELETEFILENAME! !READENDPOINT! !READUSERNAME! !READPASSWORD!
	) ELSE (
		@echo Requested not to Export for !JOBDESC! by parameter set
	)

	
	IF !DEL!==1 (
		call :StandardDelete !OBJECT! !ENTITY! %MAPPINGDIR%\!SFMAPPINGFILE! !DELETEFILENAME!
	) ELSE (
		@echo Requested not to delete for !JOBDESC! by parameter set
	)
)

exit /b



@echo off
rem *****************************************************
rem *				StandardExport						*
rem * Expects following parameters to be set:			*
rem * JOBDESC								* 
rem * 1 - OBJECT, 										* 
rem * 2 - ENTITY,										* 
rem * 3 - SOQL,											* 
rem * 4 - FILENAME										* 
rem * Will execute the SOQL against the ENTITY, then 	*
rem * Move the output to FILENAME						*
rem *													*
rem *****************************************************

:StandardExport
@echo off
@echo !JOBDESC! - StandardExport
@echo %time%: Making Apex DataLoader config file (process-conf.xml)

@java -jar c:\tools\saxon9he.jar -s:%BASEDIR%%STDEXPORT%\process-conf-base.xml -xsl:PrepExportConfig.xsl -o:%BASEDIR%%STDEXPORT%\process-conf-%~1.xml csv=%BASEDIR%%STDEXPORT%\output\%~1.csv dataaccess=csvWrite logdir=%BASEDIR%%STDEXPORT%\log entity=%~2 soql="%~3 %LIMIT%" operation=extract endpoint=%~5 username=%~6 password=%~7 bulkapi=!BULKAPI! batchsize=!BATCHSIZE!


@type %BASEDIR%%STDEXPORT%\doctype.txt %BASEDIR%%STDEXPORT%\process-conf-%~1.xml > %BASEDIR%%STDEXPORT%\process-conf.xml 2>>%LOGFILE%

@echo %time%: Calling export using %~6
@java -cp %DLPATH%\* -Dsalesforce.config.dir=%BASEDIR%%STDEXPORT%\ com.salesforce.dataloader.process.ProcessRunner process.name=standard_export >> %LOGFILE% 2>&1
rem call %DLPATH%\Java\bin\java.exe -cp %DLPATH%\* -Dsalesforce.config.dir=%BASEDIR%%STDEXPORT% com.salesforce.dataloader.process.ProcessRunner process.name=standard_export
@echo %time%: Export complete

IF NOT EXIST %BASEFILEDIR%%~1 (
	@mkdir %BASEFILEDIR%%~1
)

move %BASEDIR%%STDEXPORT%\output\%~1.csv %~4
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

@echo off
rem *****************************************************
rem *				StandardImport						*
rem * Expects following parameters to be set:			*
rem * JOBDESC											* 
rem * 1 - OBJECT, 										* 
rem * 2 - ENTITY,										* 
rem * 3 - Mapping_FILENAME								* 
rem * 4 - FILENAME										* 
rem * Will execute the SOQL against the ENTITY, then 	*
rem * Move the output to FILENAME						*
rem *													*
rem *****************************************************

:StandardDelete
@echo off
@echo !JOBDESC! - StandardDelete
@echo %time%: Making Apex DataLoader config file (process-conf.xml)

@java -jar c:\tools\saxon9he.jar -s:%BASEDIR%%STDDELETE%\process-conf-base.xml -xsl:PrepExportConfig.xsl -o:%BASEDIR%%STDDELETE%\process-conf-%~1.xml csv=%~4 dataaccess=csvRead logdir=%BASEDIR%%STDDELETE%\log mappingfile=%~3 entity=%~2 operation=delete endpoint=%WRITEENDPOINT% username=%WRITEUSERNAME% password=%WRITEPASSWORD% bulkapi=!BULKAPI! batchsize=!BATCHSIZE!

@type %BASEDIR%%STDDELETE%\doctype.txt %BASEDIR%%STDDELETE%\process-conf-%OBJECT%.xml > %BASEDIR%%STDDELETE%\process-conf.xml  2>>%LOGFILE%

@echo %time%: Apex DataLoader config file (process-conf.xml) completed

@echo %time%: Calling delete using %WRITEUSERNAME%
@java -cp %DLPATH%\* -Dsalesforce.config.dir=%BASEDIR%%STDDELETE%\ com.salesforce.dataloader.process.ProcessRunner process.name=standard_delete >> %LOGFILE% 2>&1
@echo %time%: Delete complete

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

