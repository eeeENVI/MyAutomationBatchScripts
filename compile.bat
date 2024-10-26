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
set OBJ_DIR=.\%build_target%\obj\%build_type%
set BIN_DIR=.\%build_target%\bin\%build_type%
set EXE_NAME=%build_target%.exe

REM TOOLCHAIN SFML-2.6.1 GCC 13.1.0 MinGW (SEH) - 64-bit
set SFML_INCLUDE_DIR=C:\libs\SFML-2.6.1\include
set SFML_LIB_DIR=C:\libs\SFML-2.6.1\lib
set SFML_BIN_DIR=C:\libs\SFML-2.6.1\bin
set COMPILER=C:\msys64\mingw64\bin\g++

REM DLL's for linking
set "DEBUG_DLL_FILES=openal32.dll sfml-audio-d-2.dll sfml-graphics-d-2.dll sfml-network-d-2.dll sfml-system-d-2.dll sfml-window-d-2.dll"
set "RELEASE_DLL_FILES=openal32.dll sfml-audio-2.dll sfml-graphics-2.dll sfml-network-2.dll sfml-system-2.dll sfml-window-2.dll"

REM Additional directories required for app to run
set "RESOURCES_DIR=.\assets .\config"

REM Create directories
REM Create the object directory if it doesn't exist
if not exist %OBJ_DIR% (
    mkdir %OBJ_DIR%
    echo %OBJ_DIR% created. 
)

REM Loop through all .cpp files in the src directory
REM -c compile -g debug_info -Wall all Warnings
for %%f in (%SRC_DIR%\*.cpp) do (
    echo Compiling %%f...
    %COMPILER% -c -g -Wall %%f -I%SFML_INCLUDE_DIR% -o %OBJ_DIR%\%%~nf.o
)

REM Create the bin directory if it doesn't exist
if not exist %BIN_DIR% (
    mkdir %BIN_DIR%
    echo %BIN_DIR% created.
)

REM Specify compilation of Release or Debug version based on build_type
REM Diffrent types require diffrent dlls


if "%build_type%" == "Debug" (
%COMPILER% %OBJ_DIR%\*.o -o %BIN_DIR%\%EXE_NAME% -L%SFML_LIB_DIR% -lsfml-graphics-d -lsfml-window-d -lsfml-system-d 
) 

if "%build_type%" == "Release" (
%COMPILER% -O2 %OBJ_DIR%\*.o -o %BIN_DIR%\%EXE_NAME% -L%SFML_LIB_DIR% -lsfml-graphics -lsfml-window -lsfml-system
)


if %errorlevel% equ 0 (
    echo Linking complete %EXE_NAME% %build_type% created.
    echo Compilation with %COMPILER% complete.

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
