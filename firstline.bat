@echo off
setlocal EnableDelayedExpansion
set /a counter=0

for /f "tokens=* delims=" %%a in (%1) do (
        if !counter!==1 goto :eof
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
	if %%B neq ID echo %%B=%%B >> mysdlfile.sdl
	call :process %%C
)


