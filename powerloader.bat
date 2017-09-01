@rem *****************************************
@rem Set base variables
@rem *****************************************
 
@cls

@echo off

Setlocal EnableDelayedExpansion

rem database params



rem rem echo off
rem set argC=0 
rem for %%x in (%*) do (
rem 	echo %%x
rem 	Set /A argC+=1
rem )
rem echo %argC%
rem if NOT %argC% == 3 (
rem   	echo ---------------------------------------------------------
rem   	echo usage: powerloader configfile_pattern sourceorg targetorg
rem   	echo ---------------------------------------------------------
rem  	echo powerloader 001* source target will process every file matching the 001* mask in the /configs dir
rem  	echo using properties/source.properties as credentials for the source org and properties/target.properties as the same for the target org
rem  	echo "sourceorg/targetorg params are safe to ignore (i.e. enter invalid) if only importing/exporting"
rem  	echo:
rem  	echo or
rem  	echo:
rem  	echo  ------------------------------------------------------------------------
rem   	echo "usage: powerloader delete org_to_delete_from (true|false) objecttodelete"
rem   	echo  ------------------------------------------------------------------------
rem  	echo powerloader delete source false MyCustomObject__c will delete the entire MyCustomObject__c object from the source org using SOAP API 
rem  	echo use true in third parameter to use Bulk API
rem  	echo using properties/source.properties as credentials for the source org and properties/target.properties as the same for the target org
rem  	echo:
rem  	echo or
rem  	echo:
rem  	echo  -----------------------------------------------------------------------------------
rem   	echo "usage: powerloader soqldelete org_to_delete_from (true|false) objecttodelete "soql""
rem   	echo  -----------------------------------------------------------------------------------
rem  	echo powerloader delete source false MyCustomObject__c "select ID from MyCustomObject__c WHERE NAME LIKE 'Foo%%'" will delete the 
rem  	echo MyCustomObject__c items returned by the SOQL from the source org using SOAP API - use true in third parameter to use Bulk API.
rem  	echo SOQL must be enclosed in double quotes, any percentage signs doubled
rem  	echo using properties/source.properties as credentials for the source org and properties/target.properties as the same for the target org
rem  	exit /b
rem  )



rem assuming directory structure going out from the place where this batch file resides

SET BASEDIR=%~dp0
SET BASEFILEDIR=%BASEDIR%files\
SET MAPPINGDIR=%BASEDIR%mappingfiles
SET CONFIGSDIR=%BASEDIR%configs
SET MAINLOGDIR=%BASEDIR%log
SET TOOLCONFDIR=%BASEDIR%toolconfig\
SET TOOLDIR=%BASEDIR%tools\



SET BTSTARTED=1
SET BASEDLDIR=%BASEDIR%dataloaderconfig
SET SHOWSKIPS=0

call :GetTimestamp
SET LOGPREFIX=!DATE.YEAR!!DATE.MONTH!!DATE.DAY!_!DATE.HOUR!.!DATE.MINUTE!.!DATE.SECOND!.!DATE.FRACTIONS!

SET LOGFILE="%BASEDIR%logs\log-%LOGPREFIX%.txt"
SET LIMIT=
SET FILEPREFIX=%1
SET BULKAPI=true
SET BULKAPIZIPCONTENT=false
SET BULKAPISERIAL=false
SET BATCHSIZE=5000
	
SET JAVAMEM=-Xmx1000m

rem setup external tools

call :LoadPropFile %TOOLCONFDIR%\toolconfig.properties

rem if we're doing a delete, then go there directly

if %1==delete goto :DoDelete
if %1==soqldelete goto :DoDelete

rem database config

call :LoadPropFile %TOOLCONFDIR%\databaseconfig.properties

rem salesforce params - source

call :LoadPropFile %PROPDIR%%2.properties

SET READENDPOINT=!SERVERURL!%URLSUFFIX%!apiversion!
SET READUSERNAME=!USERNAME!
SET READUNENCPASSWORD=!PASSWORD!

rem salesforce params - target

call :LoadPropFile %PROPDIR%%3.properties

SET WRITEENDPOINT=!SERVERURL!%URLSUFFIX%!apiversion!
SET WRITEUSERNAME=!USERNAME!
SET WRITEUNENCPASSWORD=!PASSWORD!

 
echo *********************************************************
echo * Reading from:
echo * Endpoint: !READENDPOINT!
echo * Username: !READUSERNAME!
echo *
echo * Writing to:
echo * Endpoint: !WRITEENDPOINT!
echo * Username: !WRITEUSERNAME!
echo *********************************************************



@echo Log file: %LOGFILE%
 
IF NOT DEFINED FILEPREFIX (
	SET FILEPREFIX=0*
)

echo off

echo.
echo The prefix specified will match the following files:
echo.
for /f %%d in ('dir /a:-d /b %CONFIGSDIR%\%FILEPREFIX%') do (
	echo %%d
)
echo.
echo Confirm that you want to run those by pressing any key, or use Ctrl-C to abort the execution
echo. 
pause

echo.
echo Starting processing

for /f %%d in ('dir /a:-d /b %CONFIGSDIR%\%FILEPREFIX%') do (
	
	
	SET EXP=0
	SET DODYNAMICQUERY=0
	SET TRUNC=0
	SET LOADPGSQL=0
	SET DOBEFORESQL=0
	SET REMAP=0
	SET FARTMAP=0
	SET UNLOADPGSQL=0
	SET DOFIRSTSQL=0
	SET DOSECONDSQL=0
	SET SQLFIRST=
	SET SQLSECOND=
	SET ORDERBY=
	SET IMP=0
	SET UPS=0
	SET UPD=0
	SET EXPMAP=0
	SET EXPTARGET=0 
	SET DOFIRSTSQL=0
	SET FARTMAPAFTER=0
	SET FARTMAPREMOVE=0
	SET CMDBEFORE=0
	SET CMDAFTER=0
	SET ABORTONERROR=0
	SET ZIPRESULTS=1
	SET FARTMAPPINGAFTER=
	SET UNLOADWHERE=
	SET FIELDSTRING=
	SET FIELDSTRINGEXPORT=
	SET MAPPEDFILENAME=
	SET EXTERNALID=
	SET SFMAPPINGFILE=
	SET GENERATEMAPPINGFILE=
	SET BEFCMD=
	SET AFTCMD=
	SET JOBRESULTS=
   
   		Setlocal DisableDelayedExpansion
		for /f "eol=# tokens=1,2 delims=:" %%a in (%BASEDIR%configs\%%d) do (
	
			SET %%a=%%b
			
		)
		Setlocal EnableDelayedExpansion
	
	rem Check if MAPPEDFILENAME was provided, if not, set it to FILENAME

	IF [!MAPPEDFILENAME!]==[] (
		SET MAPPEDFILENAME=!FILENAME!
	) 

	rem generate DLDIR for this run
	
	call :GetTimestamp
	SET DIRTS=!DATE.YEAR!!DATE.MONTH!!DATE.DAY!_!DATE.HOUR!.!DATE.MINUTE!.!DATE.SECOND!.!DATE.FRACTIONS!
	
	SET DLDIR=%BASEDLDIR%\dlconfig-%%d-!DIRTS!
	mkdir !DLDIR!
	@copy %BASEDLDIR%\*.* !DLDIR! > NUL
	
	
	
	@echo ******************************
	@echo !JOBDESC!
	@echo ******************************
	SET STARTTIME=!time!
	@echo !STARTTIME!: Starting processing file %%d
	SET CURRENTFILE=%%d
	
	IF !CMDBEFORE!==1 (
		IF !BTSTARTED!==0 (
			@start c:\tools\baretail.exe %LOGFILE%
			SET BTSTARTED=1			
		)
		
		call !BEFCMD!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Command before run for !JOBDESC!
		)
	)

	
	IF !EXP!==1 (
		@echo Max rowcount for export: !LIMIT!
		IF !BTSTARTED!==0 (
			@start %BARETAIL% %LOGFILE%
			SET BTSTARTED=1			
		)
		
		IF NOT DEFINED READPASSWORD (
			call :GetEncryptedPassword !READUNENCPASSWORD! READPASSWORD
		)
		
		call :StandardExport !OBJECT! !ENTITY! "!SOQL!" !FILENAME! !READENDPOINT! !READUSERNAME! !READPASSWORD!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Export for !JOBDESC!
		)
	)

	IF !TRUNC!==1 (
		call :Truncate
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Truncate for !JOBDESC!
		)
	)
	
		
	IF !FARTMAP!==1 (
		call :Fart !FILENAME! !FARTMAPPING!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: FART remap for !JOBDESC!
		)
	)
	
	IF !FARTMAPREMOVE!==1 (
		call :FartRemove !FILENAME! !FARTMAPPING!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: FARTRemove remap for !JOBDESC!
		)
	)
	
	
	IF !LOADPGSQL!==1 (
		call :LoadToPostgres !OBJECT! "!FIELDSTRING!" !FILENAME!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Load into Postgres for !JOBDESC!
		)
	)

	IF !DOBEFORESQL!==1 (
		call :DoSQL "!BEFORESQL!"
	)
	
	IF !DODYNAMICQUERY!==1 (
		@echo Running dynamic query
		call :DynamicQuery "!DYNAMICQUERYSQL!" !OBJECT!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Truncate for !JOBDESC!
		)
	)
	
	
	IF !REMAP!==1 (
		for %%c in (!FIELDSTOREMAP!) do (
			call :Remap "%%c"
		)
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Remap for !JOBDESC!
		)
	)

	IF !DOFIRSTSQL!==1 (
		call :DoSQL "!FIRSTSQL!"
	)
	
	IF !UNLOADPGSQL!==1 (
	rem call :UnloadFromPostgres !OBJECT! "!FIELDSTRING!" !MAPPEDFILENAME!
		IF [!FIELDSTRINGEXPORT!]==[] (
			call :UnloadFromPostgres !OBJECT! "!FIELDSTRING!" !MAPPEDFILENAME! "!UNLOADWHERE!"
		) ELSE (
			call :UnloadFromPostgres !OBJECT! "!FIELDSTRINGEXPORT!" !MAPPEDFILENAME! "!UNLOADWHERE!"
		)
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Unload for !JOBDESC! 
		)
	)
	
	IF !FARTMAPAFTER!==1 (
		call :Fart !FILENAME! !FARTMAPPINGAFTER!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: FART remap for !JOBDESC!
		)
	)
	
	IF !IMP!==1 (
		IF !BTSTARTED!==0 (
			@start %BARETAIL% %LOGFILE%
			SET BTSTARTED=1			
		)
		
		IF NOT DEFINED WRITEPASSWORD (
			call :GetEncryptedPassword !WRITEUNENCPASSWORD! WRITEPASSWORD
		)

		if [!SFMAPPINGFILE!]==[] (
			IF !GENERATEMAPPINGFILE!==1 call :GenerateSDLFile !MAPPEDFILENAME! %MAPPINGDIR%\!OBJECT!.sdl
			SET SFMAPPINGFILE=!OBJECT!.sdl
		)
		
		call :StandardImport !OBJECT! !ENTITY! %MAPPINGDIR%\!SFMAPPINGFILE! !MAPPEDFILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
		if !ISERROR!==1 (exit /b)
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Import for !JOBDESC!
		)
	)
	
	IF !UPS!==1 (
		IF !BTSTARTED!==0 (
			@start %BARETAIL% %LOGFILE%
			SET BTSTARTED=1			
		)
		IF NOT DEFINED WRITEPASSWORD (
			call :GetEncryptedPassword !WRITEUNENCPASSWORD! WRITEPASSWORD
		)
		
		if [!SFMAPPINGFILE!]==[] (
			IF !GENERATEMAPPINGFILE!==1 call :GenerateSDLFile !MAPPEDFILENAME! %MAPPINGDIR%\!OBJECT!.sdl
			SET SFMAPPINGFILE=!OBJECT!.sdl
		)

		call :StandardUpsert !OBJECT! !ENTITY! %MAPPINGDIR%\!SFMAPPINGFILE! !FILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
		if !ISERROR!==1 (exit /b)
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Upsert for !JOBDESC!
		)
	)

	IF !UPD!==1 (
		IF !BTSTARTED!==0 (
			@start c:\tools\baretail.exe %LOGFILE%
			SET BTSTARTED=1			
		)
		
		IF NOT DEFINED WRITEPASSWORD (
			call :GetEncryptedPassword !WRITEUNENCPASSWORD! WRITEPASSWORD
		)
		
		if [!SFMAPPINGFILE!]==[] (
			IF !GENERATEMAPPINGFILE!==1 call :GenerateSDLFile !MAPPEDFILENAME! %MAPPINGDIR%\!OBJECT!.sdl
			SET SFMAPPINGFILE=!OBJECT!.sdl
		)

		call :StandardUpdate !OBJECT! !ENTITY! %MAPPINGDIR%\!SFMAPPINGFILE! !MAPPEDFILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
		if !ISERROR!==1 (exit /b)
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Update for !JOBDESC!
		)
	)

	
	IF !EXPMAP!==1 (
		echo !JOBDESC! - Updating mapping table in local database
		
		IF NOT DEFINED WRITEPASSWORD (
			call :GetEncryptedPassword !WRITEUNENCPASSWORD! WRITEPASSWORD
		)
		
		call :StandardExport !OBJECT! !ENTITY! "!MAPPINGSOQL!" !OLDNEWIDFILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
		call :UpdateDBMappingTable !OLDNEWIDFILENAME! !OBJECT!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Export mapping for !JOBDESC!
		)
	)
	

	
	IF !EXPTARGET!==1 (
		@echo Max rowcount for export: !LIMIT!
		IF !BTSTARTED!==0 (
			@start %BARETAIL% %LOGFILE%
			SET BTSTARTED=1			
		)
		
		IF NOT DEFINED WRITEPASSWORD (
			call :GetEncryptedPassword !WRITEUNENCPASSWORD! WRITEPASSWORD
		)
		
		call :StandardExport !OBJECT! !ENTITY! "!SOQL!" !FILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Export for !JOBDESC!
		)
	)

	IF !CMDAFTER!==1 (
		IF !BTSTARTED!==0 (
			@start c:\tools\baretail.exe %LOGFILE%
			SET BTSTARTED=1			
		)
		
		call !AFTCMD!

	) ELSE (
		IF %SHOWSKIPS%==1 (
			@echo Skipping: Command after run for !JOBDESC!
		)
	)
	
	rem call :ZipConfFiles "%BASEFILEDIR%%~1\conf_!JOBDESC!-!DIRTS!.zip" !DLDIR!
	
	
	
	SET ENDTIME=!time!
	@echo !STARTTIME!: Starting processing file %%d
	@echo !ENDTIME!: Finished processing file %%d
)

exit /b




@echo off
rem *****************************************************
rem *				DynamicQuery				*
rem *													*
rem *****************************************************

:DynamicQuery

@echo off
@echo !JOBDESC! - DynamicQuery
@echo %time%: Starting DynamicQuery
@echo Query: %~1
@echo Object: %~2

SET queryfile=%BASEFILEDIR%\dynamicquery_%~2.sql
@echo file: %queryfile%

%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "COPY (%~1) TO '%queryfile%' DELIMITER ',' ENCODING 'UTF-8' NULL '';"
@echo %time%: database dynamic command complete

for /f "eol=# tokens=1 delims=;" %%a in (%queryfile%) do (
			%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "%%a;"						
)
@echo %time%: Finished DynamicQuery

exit /b






@echo off
rem *****************************************************
rem *				FART								*
rem *				Find And Replace Text				*
rem * Expects following parameters to be set:			*
rem * JOBDESC											* 
rem * 1 - FILENAME, 									* 
rem * 2 - FART mapping file,							* 
rem * Will FART against the FILENAME for each mapping  	*
rem * line in the FART mapping file like				*
rem * texttofind=texttoreplace							*
rem *													*
rem *****************************************************

:Fart

@echo off
@echo !JOBDESC! - FART - Find And Replace Text
@echo %time%: Starting FART
@echo Filename: %~1
@echo mapping file: %~2

for /f "eol=# tokens=1,2 delims== " %%a in (%~2) do (
			for /f "tokens=*" %%x in ('%FART% %~1 %%a %%b') do set FARTOUTPUT=%%x
			echo Replaced %%a with %%b : !FARTOUTPUT!
			
		)

@echo %time%: Finished FART
exit /b

@echo off
rem *****************************************************
rem *				FARTRemove							*
rem *				Find And Replace Text				*
rem * Expects following parameters to be set:			*
rem * JOBDESC											* 
rem * 1 - FILENAME, 									* 
rem * 2 - FART mapping file,							* 
rem * Will FART against the FILENAME for each mapping  	*
rem * line in the FART mapping file like				*
rem * texttofind=texttoreplace							*
rem *													*
rem *****************************************************

:FartRemove

@echo off
@echo !JOBDESC! - FART - Find And Replace Text
@echo %time%: Starting FART
@echo Filename: %~1
@echo mapping file: %~2

for /f "eol=# tokens=1 " %%a in (%~2) do (
			for /f "tokens=*" %%x in ('%FART% --remove %~1 %%a') do set FARTOUTPUT=%%x
			echo Removed %%a : !FARTOUTPUT!
			
		)

@echo %time%: Finished FART
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
rem make temp dir for the error & success files

rem @echo 1: %1
rem @echo 2: %2
rem @echo 3: %3
rem @echo 4: %4
rem @echo 5: %5
rem @echo 6: %6
rem @echo 7: %7

SET FILETS=%DATE:/=-%_%TIME::=.%
SET FILETS=%FILETS: =%
SET FILETS=%FILETS:,=.%

SET LOGSDIR=%BASEFILEDIR%%~1\export_!FILETS!

IF NOT EXIST !LOGSDIR! (
	@echo %time%: Creating log directory !LOGSDIR!
	mkdir !LOGSDIR!
)

IF NOT EXIST %BASEFILEDIR%%~1 (
	@echo %time%: Creating log directory %BASEFILEDIR%%~1
	@mkdir %BASEFILEDIR%%~1
)

SET OPERATION=extract

java -jar %SAXON% -s:!DLDIR!\process-conf-base.xml -xsl:!XSLPATH!PrepExportConfig.xsl -o:!DLDIR!\process-conf-!OPERATION!-%~1.xml operation=!OPERATION! csv="%~4" dataaccess=csvWrite logdir=%BASEDIR%log entity=%~2 soql="%~3 !LIMIT!" endpoint=%~5 username=%~6 password=%~7 bulkapi=!BULKAPI!  batchsize=!BATCHSIZE! successfile=!LOGSDIR!\success.csv errorfile=!LOGSDIR!\error.csv


type !DLDIR!\doctype.txt !DLDIR!\process-conf-!OPERATION!-%~1.xml > !DLDIR!\process-conf.xml 2>>NUL

@echo %time%: Calling export using %~5 for username %~6 password %~7 into %~4
java -cp %DLJAR% %JAVAMEM% -Dsalesforce.config.dir=!DLDIR!\ com.salesforce.dataloader.process.ProcessRunner process.name=standard >> %LOGFILE% 2>&1
@echo %time%: Export complete

call :GetLastLineOfLog %MAINLOGDIR%\sdl.log

call :ZipResult "%BASEFILEDIR%%~1\result_!JOBDESC!-!OPERATION!_!FILETS!.zip" !LOGSDIR!

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

:StandardImport
@echo off
@echo !JOBDESC! - StandardImport
@echo %time%: Making Apex DataLoader config file (process-conf.xml)
set ISERROR=0
rem make temp dir for the error & success files

rem make temp dir for the error & success files

SET FILETS=%DATE:/=-%_%TIME::=.%
SET FILETS=%FILETS: =%
SET FILETS=%FILETS:,=.%

SET LOGSDIR=%BASEFILEDIR%%~1\insert_!FILETS!

SET OPERATION=insert

IF NOT EXIST !LOGSDIR! (
	@echo %time%: Creating log directory !LOGSDIR!
	mkdir !LOGSDIR!
)

java -jar %SAXON% -s:!DLDIR!\process-conf-base.xml -xsl:!XSLPATH!PrepExportConfig.xsl -o:!DLDIR!\process-conf-!OPERATION!-%~1.xml operation=!OPERATION! csv=%~4 dataaccess=csvRead logdir=%BASEDIR%log mappingfile=%~3 entity=%~2  endpoint=%~5 username=%~6 password=%~7 bulkapi=!BULKAPI!  batchsize=!BATCHSIZE! successfile=!LOGSDIR!\success.csv errorfile=!LOGSDIR!\error.csv bulkapiserial=!BULKAPISERIAL!  bulkapizipcontent=!BULKAPIZIPCONTENT!

type !DLDIR!\doctype.txt !DLDIR!\process-conf-!OPERATION!-%~1.xml > !DLDIR!\process-conf.xml 2>>NUL

@echo %time%: Calling import using %WRITEUSERNAME%
java -cp %DLJAR% %JAVAMEM% -Dsalesforce.config.dir=!DLDIR!\ com.salesforce.dataloader.process.ProcessRunner process.name=standard >> %LOGFILE% 2>&1
@echo %time%: Import complete
call :AbortOnError errorfile=!LOGSDIR!\error.csv
call :GetLastLineOfLog %MAINLOGDIR%\sdl.log

call :ZipResult "%BASEFILEDIR%%~1\result_!JOBDESC!-!OPERATION!_!FILETS!.zip" !LOGSDIR!

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

:StandardUpsert
@echo off
@echo !JOBDESC! - StandardUpsert
@echo %time%: Making Apex DataLoader config file (process-conf.xml)
set ISERROR=0
rem make temp dir for the error & success files

SET FILETS=%DATE:/=-%_%TIME::=.%
SET FILETS=%FILETS: =%
SET FILETS=%FILETS:,=.%

SET LOGSDIR=%BASEFILEDIR%%~1\upsert_!FILETS!

SET OPERATION=upsert

IF NOT EXIST !LOGSDIR! (
	@echo %time%: Creating log directory !LOGSDIR!
	mkdir !LOGSDIR!
)


java -jar %SAXON% -s:!DLDIR!\process-conf-base.xml -xsl:!XSLPATH!PrepExportConfig.xsl -o:!DLDIR!\process-conf-!OPERATION!-%~1.xml operation=!OPERATION! csv=%~4 dataaccess=csvRead logdir=%BASEDIR%log mappingfile=%~3 entity=%~2 endpoint=%~5 username=%~6 password=%~7 bulkapi=!BULKAPI!  batchsize=!BATCHSIZE! bulkapizipcontent=!BULKAPIZIPCONTENT! externalid=!EXTERNALID! successfile=!LOGSDIR!\success.csv errorfile=!LOGSDIR!\error.csv bulkapiserial=!BULKAPISERIAL! 

type !DLDIR!\doctype.txt !DLDIR!\process-conf-!OPERATION!-%~1.xml > !DLDIR!\process-conf.xml 2>>NUL

@echo %time%: Calling upsert using %WRITEUSERNAME%
java -cp %DLJAR% %JAVAMEM% -Dsalesforce.config.dir=!DLDIR!\ com.salesforce.dataloader.process.ProcessRunner process.name=standard >> %LOGFILE% 2>&1
@echo %time%: Upsert complete
call :AbortOnError errorfile=!LOGSDIR!\error.csv
call :GetLastLineOfLog %MAINLOGDIR%\sdl.log

call :ZipResult "%BASEFILEDIR%%~1\result_!JOBDESC!-!OPERATION!_!FILETS!.zip" !LOGSDIR!

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

@echo off
rem *****************************************************
rem *				StandardUpdate						*
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

:StandardUpdate
@echo off
@echo !JOBDESC! - StandardUpdate
@echo %time%: Making Apex DataLoader config file (process-conf.xml)
set ISERROR=0
rem make temp dir for the error & success files

SET FILETS=%DATE:/=-%_%TIME::=.%
SET FILETS=%FILETS: =%
SET FILETS=%FILETS:,=.%

SET LOGSDIR=%BASEFILEDIR%%~1\update_!FILETS!

SET OPERATION=update

IF NOT EXIST !LOGSDIR! (
	@echo %time%: Creating log directory !LOGSDIR!
	mkdir !LOGSDIR!
)


java -jar %SAXON% -s:!DLDIR!\process-conf-base.xml -xsl:!XSLPATH!PrepExportConfig.xsl -o:!DLDIR!\process-conf-!OPERATION!-%~1.xml operation=!OPERATION! csv=%~4 dataaccess=csvRead logdir=%BASEDIR%log mappingfile=%~3 entity=%~2 endpoint=%~5 username=%~6 password=%~7 bulkapi=!BULKAPI!  batchsize=!BATCHSIZE! bulkapizipcontent=!BULKAPIZIPCONTENT! externalid=!EXTERNALID! successfile=!LOGSDIR!\success.csv errorfile=!LOGSDIR!\error.csv bulkapiserial=!BULKAPISERIAL!

type !DLDIR!\doctype.txt !DLDIR!\process-conf-!OPERATION!-%~1.xml > !DLDIR!\process-conf.xml 2>>NUL

@echo %time%: Calling update using %WRITEUSERNAME% - file %~4
java -cp %DLJAR% %JAVAMEM% -Dsalesforce.config.dir=!DLDIR!\ com.salesforce.dataloader.process.ProcessRunner process.name=standard >> %LOGFILE% 2>&1
@echo %time%: Update complete
call :AbortOnError errorfile=!LOGSDIR!\error.csv
call :GetLastLineOfLog %MAINLOGDIR%\sdl.log

call :ZipResult "%BASEFILEDIR%%~1\result_!JOBDESC!-!OPERATION!_!FILETS!.zip" !LOGSDIR!

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b



@echo off
rem *****************************************************
rem *				Truncate							*
rem * Expects following parameters to be set:			*
rem * JOBDESC, OBJECT, NEXTSTEP							* 
rem * Will truncate the OBJECT table in Postgres 		*
rem *													*
rem *****************************************************

:Truncate

@echo !JOBDESC! - Truncate
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "TRUNCATE !OBJECT!;"
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

@echo off
rem *****************************************************
rem *				LoadToPostgres						*
rem * Expects following parameters to be set:			*
rem * 1 - object										*
rem * 2 - Field string									*
rem * 3 - Filename to load from 						*
rem *													*
rem * Will load the FILENAME into Postgres			 	*
rem *													*
rem *****************************************************

:LoadToPostgres

@echo !OBJECT! - Load into PostgreSQL
@echo %time%: calling database command
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "COPY %~1 (%~2) FROM '%~3' DELIMITER ',' CSV ENCODING 'UTF-8' NULL '' HEADER;"
@echo %time%: database command complete
@echo %time%: calling database vacuum
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "VACUUM ANALYZE %~1;"
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "VACUUM ANALYZE mapping_master;"
@echo %time%: database vaccum complete
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

@echo off
rem *****************************************************
rem *					Remap							*
rem * Expects following parameters to be set:			*
rem * param1=item to remap, OBJECT, NEXTSTEP 			*
rem *													*
rem * Will remap the ids using existing mapping	table	*
rem * (mapping_master). Assumes mapping table is 		*
rem * updated											*
rem *													*
rem *****************************************************

:Remap
@echo ***********************************************************
@echo *                                                         *
@echo * !OBJECT! - Remap %~1 in PGSQL
@echo * %time%: calling database command 
rem %PSQLCMD% -U %DBUSER% -d %DBNAME% -c "UPDATE !OBJECT! SET %~1 = 'cannot_map' WHERE id in (select id from !OBJECT! t left join mapping_master m on (t.%~1=m.dentsplyid) WHERE m.wellspectid is null and %~1<>''); UPDATE !OBJECT! SET %~1 = COALESCE(rt.wellspectid, 'cannot map') FROM (SELECT m.wellspectid, m.dentsplyid FROM mapping_master m WHERE m.dentsplyid is not null and m.dentsplyid<>'') rt WHERE !OBJECT!.%~1 = rt.dentsplyid; "
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "UPDATE !OBJECT! SET %~1 = rt.wellspectid FROM (SELECT m.wellspectid, m.dentsplyid FROM mapping_master m WHERE m.dentsplyid is not null and m.dentsplyid<>'') rt WHERE !OBJECT!.%~1 = rt.dentsplyid; "
@echo * %time%: database command complete
@echo *                                                         *
@echo ***********************************************************
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

@echo off
rem *****************************************************
rem *					DoSQL							*
rem * Expects following parameters to be set:			*
rem * param1=SQL to run						 			*
rem *													*
rem * Will run the SQL verbatim							*
rem *													*
rem *****************************************************

:DoSQL
@echo !OBJECT! - DoSQL in PGSQL
@echo %time%: calling database command %~1
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "%~1"
@echo %time%: database command complete
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b


@echo off
rem *****************************************************
rem *				UnloadFromPostgres					*
rem * Expects following parameters to be set:			*
rem * 1 - object										*
rem * 2 - Field string									*
rem * 3 - Filename to load from 						*
rem * 4 - WHERE-clause (if any)													*
rem * Will load the FILENAME into Postgres			 	*
rem *													*
rem *****************************************************



:UnloadFromPostgres
@echo !OBJECT! - Unload from PostgreSQL
@echo %time%: calling database command 
@echo SELECT %~2 FROM %~1 %~4 !ORDERBY!
rem @echo "COPY (SELECT %~2 FROM %~1 %~4) TO '%~3' DELIMITER ',' CSV ENCODING 'UTF-8' NULL '' HEADER;"
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "COPY (SELECT %~2 FROM %~1 %~4 !ORDERBY!) TO '%~3' DELIMITER ',' CSV ENCODING 'UTF-8' NULL '' HEADER;"
@echo %time%: database command complete
@echo Created/updated file %~3
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b


@echo off
rem *****************************************************
rem *				UpdateDBMappingTable				*
rem * Expects following parameters to be set:			*
rem * 1 - Filename to load mapping from					*
rem * 2 - String to prefix tablekey field in table		*
rem *													*
rem * Will update the FILENAME into Postgres master	 	*
rem * mapping table										*
rem *****************************************************

:UpdateDBMappingTable
@echo !OBJECT! - Update PostgreSQL MappingTable
@echo %time%: calling database command 
rem %PSQLCMD% -U %DBUSER% -d %DBNAME% -c "CREATE LOCAL TEMPORARY TABLE mapping_full_temp (   dentsplyid VARCHAR(18),   wellspectid VARCHAR(18),   tablekey VARCHAR(255) )  ON COMMIT PRESERVE ROWS;  COPY mapping_full_temp (wellspectid, dentsplyid, tablekey) FROM '%~1' DELIMITER ',' CSV ENCODING 'UTF-8' NULL '' HEADER;  DELETE FROM mapping_master WHERE dentsplyid IN (select dentsplyid from mapping_full_temp) or wellspectid in (select wellspectid from mapping_full_temp) or tablekey like '%~2_%%';  INSERT INTO mapping_master(dentsplyid, wellspectid, tablekey) SELECT dentsplyid, wellspectid, '%~2_' || tablekey FROM mapping_full_temp WHERE dentsplyid is not null and dentsplyid<>'' and wellspectid is not null and wellspectid<>'';       DROP TABLE mapping_full_temp;"
@echo %time%: calling database command: CREATE temp table 
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "CREATE TABLE temp_mapping_%~2 (   dentsplyid VARCHAR(18),   wellspectid VARCHAR(18),   tablekey VARCHAR(255) );"
@echo %time%: calling database command: LOAD from mapping file
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "COPY temp_mapping_%~2 (wellspectid, dentsplyid, tablekey) FROM '%~1' DELIMITER ',' CSV ENCODING 'UTF-8' NULL '' HEADER;"
@echo %time%: calling database command: DELETE from mapping_master 
rem %PSQLCMD% -U %DBUSER% -d %DBNAME% -c "DELETE FROM mapping_master WHERE dentsplyid IN (select dentsplyid from temp_mapping_%~2) or wellspectid in (select wellspectid from temp_mapping_%~2) or tablekey like '%~2_%%';
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "DELETE FROM mapping_master WHERE tablekey like '%~2_%%';
@echo %time%: calling database command: INSERT INTO mapping_master 
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "INSERT INTO mapping_master(dentsplyid, wellspectid, tablekey) SELECT distinct dentsplyid, wellspectid, '%~2_' || tablekey FROM temp_mapping_%~2 WHERE dentsplyid is not null and dentsplyid<>'' and wellspectid is not null and wellspectid<>'';"
@echo %time%: calling database command: DROP temp table 
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "DROP TABLE temp_mapping_%~2;"

@echo %time%: database command complete
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

rem *****************************************************
rem *				StandardDelete						*
rem * Expects following parameters to be set:			*
rem * JOBDESC											* 
rem * 1 - OBJECT, 										* 
rem * 2 - ENTITY,										* 
rem * 3 - Mapping_FILENAME								* 
rem * 4 - FILENAME										*
rem * 5 - ENDPOINT,										* 
rem * 6 - USERNAME										* 
rem * 7 - PASSWORD										* 
rem * Will execute the SOQL against the ENTITY, then 	*
rem * Move the output to FILENAME						*
rem *													*
rem *****************************************************

:StandardDelete
@echo off
@echo !JOBDESC! - StandardDelete


SET FILETS=%DATE:/=-%_%TIME::=.%
SET FILETS=%FILETS: =%
SET FILETS=%FILETS:,=.%

SET LOGSDIR=%BASEFILEDIR%%~1\export_!FILETS!

IF NOT EXIST !LOGSDIR! (
	@echo Creating log directory !LOGSDIR!
	mkdir !LOGSDIR!
)

IF NOT EXIST %BASEFILEDIR%%~1 (
	@echo Creating log directory %BASEFILEDIR%%~1
	@mkdir %BASEFILEDIR%%~1
)

SET OPERATION=delete

@echo %time%: Making Apex DataLoader config file (process-conf.xml)

java -jar %SAXON% -s:!DLDIR!\process-conf-base.xml -xsl:!XSLPATH!PrepExportConfig.xsl -o:!DLDIR!\process-conf-!OPERATION!-%~1.xml operation=!OPERATION! csv=%~4 dataaccess=csvRead logdir=!LOGSDIR! mappingfile=%~3 entity=%~2 endpoint=%~5 username=%~6 password=%~7 bulkapi=!BULKAPI! batchsize=!BATCHSIZE! successfile=!LOGSDIR!\success.csv errorfile=!LOGSDIR!\error.csv

type !DLDIR!\doctype.txt !DLDIR!\process-conf-!OPERATION!-%~1.xml > !DLDIR!\process-conf.xml 2>>NUL

@echo %time%: Apex DataLoader config file (process-conf.xml) completed

@echo %time%: Calling delete using %~6
java -cp %DLJAR% %JAVAMEM% -Dsalesforce.config.dir=!DLDIR!\ com.salesforce.dataloader.process.ProcessRunner process.name=standard >> %LOGFILE% 2>&1
@echo %time%: Delete complete

call :GetLastLineOfLog %MAINLOGDIR%\sdl.log

call :ZipResult "%BASEFILEDIR%%~1\result_!OPERATION!_!FILETS!.zip" !LOGSDIR!

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b


:ZipResult

rem %1 name of output Zipfile
rem %2 name of log directory which is to be zipped

rem echo ZIPRESULTS: !ZIPRESULTS!
rem echo JOBRESULTS: !JOBRESULTS!

IF !ZIPRESULTS!==1 (
	@echo %time%: starting results zip to %~1
	rem now zip up the content of the logsdir
	!ZIP! a "%~1" %~2\*.* >NUL 2>&1
	
	
) else (
	IF [!JOBRESULTS!] == [] (
		@echo %time%: asked to not zip job results, but no JORRESULTS parameter found in config file, will zip anyway to %~1
		rem now zip up the content of the logsdir
		!ZIP! a "%~1" %~2\*.* >NUL 2>&1
	)
)

IF !ZIPRESULTS!==0 IF NOT [!JOBRESULTS!] == [] (
	@echo %time%: asked to not zip job results, moving to !JOBRESULTS!
	@echo %time%: moving %~2\success.csv to !JOBRESULTS!\success_!CURRENTFILE!.csv
	Move %~2\success.csv !JOBRESULTS!\success_!CURRENTFILE!.csv
	@echo %time%: moving %~2\error.csv to !JOBRESULTS!\error_!CURRENTFILE!.csv
	move %~2\error.csv !JOBRESULTS!\error_!CURRENTFILE!.csv
)

rem remove logsdir
rmdir /s /q %~2
@echo %time%: finished results zip/move

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b


:ZipConfFiles

@echo %time%: starting conf zip to %~1
rem now zip up the content of the logsdir
!ZIP! a "%~1" %~2\*.* >NUL 2>&1
rem remove logsdir
rmdir /s /q %~2
@echo %time%: finished conf zip
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

:GetEncryptedPassword

echo Getting encrypted password for string %~1

set pwdcmd=java -cp %DLJAR% com.salesforce.dataloader.security.EncryptionUtil -e %~1
for /f "tokens=* delims= " %%I in ('%pwdcmd%') do for %%A in (%%~I) do set %~2=%%A
rem %pwdcmd%

echo Encrypted password set to !%~2!

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

:GetLastLineOfLog
@echo off
for /f "tokens=* delims=" %%a in (%~1) do (
set var=%%a
)
echo !var!

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

:LoadPropFile

rem Params: 1: properties file to read

@echo off
for /f "eol=# delims== tokens=1,2" %%a in (%1) do (
	call :SetWithTrim %%a %%b
)
rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

:SetWithTrim

rem Params: 1: name of param
rem Params: 2: value of param

@echo off

SET %1=%2

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

:GetTimestamp

@echo off
rem Get the time from WMI - at least that's a format we can work with
set X=
for /f "skip=1 delims=" %%x in ('wmic os get localdatetime') do if not defined X set X=%%x
rem echo.%X%

rem dissect into parts
set DATE.YEAR=%X:~0,4%
set DATE.MONTH=%X:~4,2%
set DATE.DAY=%X:~6,2%
set DATE.HOUR=%X:~8,2%
set DATE.MINUTE=%X:~10,2%
set DATE.SECOND=%X:~12,2%
set DATE.FRACTIONS=%X:~15,2%
set DATE.OFFSET=%X:~21,4%

rem echo %DATE.YEAR%-%DATE.MONTH%-%DATE.DAY% %DATE.HOUR%:%DATE.MINUTE%:%DATE.SECOND%.%DATE.FRACTIONS%

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b


:DoDelete

rem salesforce params - org to delete from

call :LoadPropFile %PROPDIR%%2.properties

SET WRITEENDPOINT=!SERVERURL!%URLSUFFIX%!apiversion!
SET WRITEUSERNAME=!USERNAME!
SET WRITEUNENCPASSWORD=!PASSWORD!

call :GetEncryptedPassword !WRITEUNENCPASSWORD! WRITEPASSWORD

@start %BARETAIL% -ws 1 -tc 4 -ti 3 %LOGFILE%
SET BULKAPI=%3

for %%f in (%4) do (

	if [%%f] neq [] (
		rem generate DLDIR for this run
		
		call :GetTimestamp
		SET DIRTS=!DATE.YEAR!!DATE.MONTH!!DATE.DAY!_!DATE.HOUR!.!DATE.MINUTE!.!DATE.SECOND!.!DATE.FRACTIONS!
		
		SET DLDIR=%BASEDLDIR%\dlconfig-delete-!DIRTS!
		mkdir !DLDIR!
		@xcopy /q %BASEDLDIR%\*.* !DLDIR! >> NUL 2>&1

		@echo Processing object %%f

		SET ITEMTODELETE=%%f
		echo ********************************************
		echo * Deleting %%f
		echo ********************************************
		SET DELETEFILENAME=%BASEFILEDIR%%%f\%%f_to_delete.csv
		SET OBJECT=%%f 
		SET JOBDESC=Delete %%f
		if %1==soqldelete (
			SET SOQL=%5
		) else (
			SET SOQL=select id from %%f
		)
		SET SOQL=!SOQL:"=!
		@rem "
		SET BATCHSIZE=1000
		SET ENTITY=%%f
		SET SFMAPPINGFILE=delete.sdl
	   
		call :StandardExport !OBJECT! !ENTITY! "!SOQL!" !DELETEFILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
		call :StandardDelete !OBJECT! !ENTITY! %MAPPINGDIR%\!SFMAPPINGFILE! !DELETEFILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
	)
	
)

exit /b

:AbortOnError		
	IF !ABORTONERROR!==1 (		
		rem * figure out how many lines in error.csv		
		rem echo 1:%1 2:%2		
 		for /f %%C in ('Find /V /C "" ^<  %2') do set lineCount=%%C
 		for /l %%a in (1,1,100) do if "!lineCount:~-1!"==" " set lineCount=!lineCount:~0,-1! 
		echo Lines: !lineCount!.
		if !lineCount! gtr 1 (		
			echo Errors found in this job: error file has !lineCount! lines. Aborting execution		
			SET ISERROR=1
			exit /b 		
		)		
	)		
exit /b

:GenerateSDLFile

@echo %time%: Generating SDL file (%2) based on %1

rem Params: 1: name of csv file to generate sdl file for (assumes first line is field names)
rem Params: 2: full path of the sdl file to be GenerateSDLFile

@echo off
setlocal EnableDelayedExpansion
set /a counter=0

SET GENERATEDFILENAME=%2

echo # SDL file autogenerated by PowerLoader > %2
echo. >> %2

for /f "tokens=* delims=" %%a in (%1) do (
        if !counter!==1 goto :return
        SET FIELD=%%a
        SET FIELD=!FIELD:"=!
        SET FIELD=!FIELD:,=#!
        rem "
        call :process !FIELD!
        set /a counter+=1 
)

:process
@rem echo Process called with %1
for /F "delims=# tokens=1*" %%B in ("%1") do (
	if %%B neq ID echo %%B=%%B >> !GENERATEDFILENAME!
	call :process %%C
)
exit /b

:return
exit /b


