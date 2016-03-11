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

rem salesforce params

SET READENDPOINT=https://test.salesforce.com/services/Soap/u/29.0
SET READUSERNAME=kgalant@dentsply.com.fullsb
rem SET READPASSWORD=11e9c01ede56ee50aab74f014238e17c
SET READPASSWORD=ce9f52eab752286ade885e5c3c4668b8
SET WRITEENDPOINT=https://test.salesforce.com/services/Soap/u/29.0
SET WRITEUSERNAME=kgalant@wellspect.com.fullsb
rem SET WRITEPASSWORD=11e9c01ede56ee50aab74f014238e17c
SET WRITEPASSWORD=ce9f52eab752286ade885e5c3c4668b8
set FILETS=%DATE:/=-%@%TIME::=.%
SET FILETS=%FILETS: =%
SET FILETS=%FILETS:,=.%
SET LOGPREFIX=%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%.%time:~3,2%.%time:~6,2%.%time:~9,2%
SET LOGFILE=%BASEDIR%logs\log-!LOGPREFIX!.txt
SET LIMIT=
SET FILEPREFIX=%1
SET BULKAPI=true
SET BATCHSIZE=200

@echo Log file: %LOGFILE%

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
SET FART=%BASEDIR%fart.exe
SET BTSTARTED=0

SET STDEXPORT=stdexport
SET STDINSERT=stdinsert
SET STDUPSERT=stdupsert


SET DLPATH=c:\Dev\ApexDataLoader

for /f %%d in ('dir /a:-d /b %BASEDIR%configs\%FILEPREFIX%') do (
   @echo Processing file %%d

	SET EXP=0
	SET TRUNC=0
	SET LOADPGSQL=0
	SET REMAP=0
	SET FARTMAP=0
	SET UNLOADPGSQL=0
	SET IMP=0
	SET UPS=0
	SET EXPMAP=0
	SET DOFIRSTSQL=0
	SET DOSECONDSQL=0
	SET EXPTARGET=0
   
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

SET SOURCEFILENAME=%BASEFILEDIR%!OBJECT!\!OBJECT!_mapping_source.csv
SET TARGETFILENAME=%BASEFILEDIR%!OBJECT!\!OBJECT!_mapping_target.csv

	IF !EXP!==1 (
		@echo Max rowcount for export: !LIMIT!
		IF !BTSTARTED!==0 (
			@start c:\tools\baretail.exe %LOGFILE%
			SET BTSTARTED=1			
		)
		call :StandardExport !OBJECT! !ENTITY! "!SOQL!" !SOURCEFILENAME! !READENDPOINT! !READUSERNAME! !READPASSWORD!
	) ELSE (
		@echo Skipping: Export for !JOBDESC!
	)
	
	IF !DOFIRSTSQL!==1 (
		@echo !OBJECT! - DoFirstSQL in PGSQL
		@echo %time%: calling database command
		call :DoSQL "DROP TABLE mapping_full_temp;" 1>NUL 2>&1
		call :DoSQL "CREATE TABLE mapping_full_temp (   itemid VARCHAR(18),  tablekey VARCHAR(255) )  ;"
		call :DoSQL "COPY mapping_full_temp (itemid, tablekey) FROM '!SOURCEFILENAME!' DELIMITER ',' CSV ENCODING 'UTF-8' NULL '' HEADER; "
		call :DoSQL "UPDATE mapping_master SET dentsplyid = mft.itemid FROM ( select itemid, tablekey FROM mapping_full_temp ) mft WHERE mapping_master.tablekey = '!MAPPREFIX!_' || mft.tablekey;"
		call :DoSQL "INSERT INTO mapping_master(dentsplyid, tablekey) select itemid, '!MAPPREFIX!_' || tablekey FROM mapping_full_temp WHERE itemid in ( SELECT itemid FROM ( select t.itemid, t.tablekey, m.tablekey from mapping_full_temp t left join mapping_master m on (t.itemid = m.dentsplyid) WHERE m.tablekey is null ) q1 );"
		call :DoSQL "DROP TABLE mapping_full_temp;"
		@echo %time%: database command complete
	)
	
	IF !EXPTARGET!==1 (
		@echo Max rowcount for export: !LIMIT!
		IF !BTSTARTED!==0 (
			@start c:\tools\baretail.exe %LOGFILE%
			SET BTSTARTED=1			
		)
		call :StandardExport !OBJECT! !ENTITY! "!SOQL!" !TARGETFILENAME! !WRITEENDPOINT! !WRITEUSERNAME! !WRITEPASSWORD!
	) ELSE (
		@echo Skipping: Export for !JOBDESC!
	)
	
	IF !DOSECONDSQL!==1 (
		@echo !OBJECT! - DoSecondSQL in PGSQL
		@echo %time%: calling database command
		call :DoSQL "DROP TABLE mapping_full_temp;" 1>NUL 2>&1
		call :DoSQL "CREATE TABLE mapping_full_temp (   itemid VARCHAR(18),  tablekey VARCHAR(255) );"
		call :DoSQL "COPY mapping_full_temp (itemid, tablekey) FROM '!TARGETFILENAME!' DELIMITER ',' CSV ENCODING 'UTF-8' NULL '' HEADER;"
		call :DoSQL "UPDATE mapping_master SET wellspectid = mft.itemid FROM ( select itemid, tablekey FROM mapping_full_temp ) mft WHERE mapping_master.tablekey = '!MAPPREFIX!_' || mft.tablekey;"
		call :DoSQL "DELETE FROM mapping_master WHERE mapping_master.tablekey LIKE '!MAPPREFIX!_%%%%' and ((dentsplyid is null or dentsplyid = '') or (wellspectid is null or wellspectid = ''))"
		call :DoSQL "DROP TABLE mapping_full_temp;"
		@echo %time%: database command complete
	)

)

exit /b






:StandardExport
@echo off
@echo !JOBDESC! - StandardExport
@echo %time%: Making Apex DataLoader config file (process-conf.xml)




Setlocal EnableDelayedExpansion

set FILETS=%DATE:/=-%@%TIME::=.%
SET FILETS=%FILETS: =%
SET FILETS=%FILETS:,=.%

SET OUTPUTFILE=%BASEDIR%%STDEXPORT%\output\%~1_%LOGPREFIX%.csv


rem @echo Param 1: %~1
rem @echo Param 2: %~2
rem @echo Param 3: %~3
rem @echo Param 4: %~4
rem @echo Param 5: %~5
rem @echo Param 6: %~6
rem @echo Param 7: %~7
rem 
rem @echo OUTPUTFILE: !OUTPUTFILE!
rem @echo FILETS: !FILETS!
rem 
java -jar c:\tools\saxon9he.jar -s:%BASEDIR%%STDEXPORT%\process-conf-base.xml -xsl:PrepExportConfig.xsl -o:%BASEDIR%%STDEXPORT%\process-conf-%~1.xml csv=!OUTPUTFILE! dataaccess=csvWrite logdir=%BASEDIR%%STDEXPORT%\log entity=%~2 soql="%~3 !LIMIT!" operation=extract endpoint=%~5 username=%~6 password=%~7 bulkapi=!BULKAPI!  batchsize=!BATCHSIZE!

@type %BASEDIR%%STDEXPORT%\doctype.txt %BASEDIR%%STDEXPORT%\process-conf-%~1.xml > %BASEDIR%%STDEXPORT%\process-conf.xml 2>>%LOGFILE%

@echo %time%: Calling export using %~6
@java -cp %DLPATH%\* -Dsalesforce.config.dir=%BASEDIR%%STDEXPORT%\ com.salesforce.dataloader.process.ProcessRunner process.name=standard_export >> %LOGFILE% 2>&1
@echo %time%: Export complete

IF NOT EXIST %BASEFILEDIR%%~1 (
	@mkdir %BASEFILEDIR%%~1
)

move !OUTPUTFILE! %~4

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

:DoSQL

rem echo command: %~1
%PSQLCMD% -U %DBUSER% -d %DBNAME% -c "%~1"

rem this is CALLed, so we need to Exit /b instead of the GOTO
exit /b

