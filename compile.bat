@echo off
setlocal enabledelayedexpansion

REM Author @eeeENVII

REM stands for REMARK 
:: stands for comment

REM Initialize arguments: build_type & build_target
set "build_type="
set "build_target="

:: Loop through all arguments and assign them based on value
:: only last type and last target will built /i comparison case-insensitive
for %%A in (%*) do (
    if /i "%%A"=="Debug" set "build_type=Debug"
    if /i "%%A"=="Release" set "build_type=Release"
    if /i "%%A"=="Client" set "build_target=Client"
    if /i "%%A"=="Server" set "build_target=Server"
)

REM Validate the inputs to ensure we have both a build_type and build_target
if "%build_type%"=="" (
    echo Error: Missing or invalid build type. Use "Debug" or "Release".
    goto :end
)
if "%build_target%"=="" (
    echo Error: Missing or invalid build target. Use "Client" or "Server".
    goto :end
)

REM Define the directories
set SRC_DIR=.\%build_target%\src
set DEP_DIR=.\%build_target%\dep
set OBJ_DIR=.\%build_target%\obj\%build_type%
set BIN_DIR=.\%build_target%\bin\%build_type%
set EXE_NAME=%build_target%.exe

REM Initialize INCLUDE_SUB_DIRS variable
set INCLUDE_SUB_DIRS=-I%SRC_DIR%

REM Loop through all subdirectories and add -I for each
for /d %%d in (%SRC_DIR%\*) do (
    set INCLUDE_SUB_DIRS=%INCLUDE_SUB_DIRS% -I%%d
)

REM Define the TOOLCHAIN : SFML-2.6.1 GCC 13.1.0 MinGW (SEH) - 64-bit
set SFML_INCLUDE_DIR=C:\libs\SFML-2.6.1\include
set SFML_LIB_DIR=C:\libs\SFML-2.6.1\lib
set SFML_BIN_DIR=C:\libs\SFML-2.6.1\bin
set COMPILER=C:\msys64\mingw64\bin\g++

REM compiler flags: -c compile -g debug_info -Wall all Warnings -Werror warnings are errors
set CFLAGS=-g -Wall -Werror
REM compiler flags for dependency generation: -MMD generate .d file for each source file 
REM -MP files that are no longer required (because headers were deleted) are marked as dependencies and won't cause errors.
set DEPFLAGS=-MMD -MP

REM DLL's for linking
set "DEBUG_DLL_FILES=openal32.dll sfml-audio-d-2.dll sfml-graphics-d-2.dll sfml-network-d-2.dll sfml-system-d-2.dll sfml-window-d-2.dll"
set "RELEASE_DLL_FILES=openal32.dll sfml-audio-2.dll sfml-graphics-2.dll sfml-network-2.dll sfml-system-2.dll sfml-window-2.dll"

REM Additional directories required for app to run
set "RESOURCES_DIR=.\assets .\config .\data"

REM Create directories
REM Create the object directory if it doesn't exist
if not exist %OBJ_DIR% (
    mkdir %OBJ_DIR%
    echo %OBJ_DIR% created. 
)

REM Create the dependency directory if it doesn't exist
if not exist %DEP_DIR% (
    mkdir %DEP_DIR%
    echo %DEP_DIR% created.
)

REM Define timestamp file to avoid building if not modified
set TIMESTAMP_FILE=.\%build_target%\last_build.timestamp

REM Generate a unique hash based on file modification times of all .cpp files
set MOD_TIME_HASH=
for /r %SRC_DIR% %%f in (*.*) do  (
    for %%t in (%%f) do set MOD_TIME_HASH=!MOD_TIME_HASH!%%~tf
)

REM Check if the hash has changed by comparing to the stored timestamp
if exist %TIMESTAMP_FILE% (
    set /p LAST_MOD_HASH=<%TIMESTAMP_FILE%
) else (
    set LAST_MOD_HASH=
)

REM If the hashes differ, perform a build; otherwise, skip
if "%MOD_TIME_HASH%" EQU "%LAST_MOD_HASH%" (
    echo No changes detected. Build is up-to-date.
    goto :end
) else  (
    echo Changes detected. Rebuilding project...
)

REM Loop through all .cpp files in the src directory
REM -c compile -g debug_info -Wall all Warnings -Werror warnings are errors
for /r %SRC_DIR% %%f in (*.cpp) do (
    echo Compiling %%f and generating dependency files...
    %COMPILER% %CFLAGS% %DEPFLAGS% -c %%f %INCLUDE_SUB_DIRS% -I%SFML_INCLUDE_DIR% -o %OBJ_DIR%\%%~nf.o -MF %DEP_DIR%\%%~nxf.d
)

REM Create the bin directory if it doesn't exist
if not exist %BIN_DIR% (
    mkdir %BIN_DIR%
    echo %BIN_DIR% created.
)

REM Specify linking of Release or Debug version based on build_type
REM Diffrent types require diffrent dlls

if "%build_type%" == "Debug" (
%COMPILER% %OBJ_DIR%\*.o -o %BIN_DIR%\%EXE_NAME% -L%SFML_LIB_DIR% -lsfml-graphics-d -lsfml-window-d -lsfml-system-d 
) 

if "%build_type%" == "Release" (
%COMPILER% -O2 %OBJ_DIR%\*.o -o %BIN_DIR%\%EXE_NAME% -L%SFML_LIB_DIR% -lsfml-graphics -lsfml-window -lsfml-system
)

REM Copying files

if %errorlevel% equ 0 (
    REM Update the timestamp file with the new hash
    echo %MOD_TIME_HASH%>%TIMESTAMP_FILE%
    echo Build complete...
    echo Compilation with %COMPILER% complete...
    echo Linking %EXE_NAME% %build_type% complete...

    REM Copying assets/configs etc..
    :: D stands for directories
    for %%D in (%RESOURCES_DIR%) do (
        echo Copying %%D and its subdirectories to %BIN_DIR%...
        
        if exist "%%D" (
            :: Use xcopy to copy /s subdirectories /e even empty /y supress rewriting prompt /i destination is directory
            xcopy "%%D" "%BIN_DIR%\%%~nxD" /s /e /i /y
        ) else (
            echo Directory %%D does not exist.
        )
    )

    if "%build_type%" == "Debug" (
        REM Copying DLL's for dynamic linking
        for %%F in (%DEBUG_DLL_FILES%) do (
            echo Copying %%F from %SFML_BIN_DIR% to %BIN_DIR%...
            copy "%SFML_BIN_DIR%\%%F" "%BIN_DIR%" /y
        )
    )

    if "%build_type%" == "Release" (
        REM Copying DLL's for dynamic linking
        for %%F in (%RELEASE_DLL_FILES%) do (
            echo Copying %%F from %SFML_BIN_DIR% to %BIN_DIR%...
            copy "%SFML_BIN_DIR%\%%F" "%BIN_DIR%" /y
        )
    )

) else (
    echo Linking failed with error level %errorlevel%. No new executable created.
)

:end
echo end
exit /b
