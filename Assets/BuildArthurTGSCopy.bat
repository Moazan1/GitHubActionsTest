@echo off
SETLOCAL 

SET UnityVersion=%1
SET AndroidSDKVersion=%2
SET Identifier=%3
SET Version=%4
SET BuildNumber=%5
SET Server=%6
SET Channel=%7

REM === CONFIGURATION BEGIN =============================================

@echo off
ChangeServerConfig.exe %6 %4
SET /a retVar=%errorlevel%
ECHO %retVar%
if %errorlevel% EQU 1 goto SUCCESS
if %errorlevel% EQU 0 goto FAIL

:SUCCESS
ECHO Server Config Changed Successfully
goto CONTINUE
:FAIL
ECHO Please provide correct parameters to change Server Config

:CONTINUE
REM The Android SDK Build Tools location
SET BUILD_TOOLS=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Android\Sdk\build-tools\%AndroidSDKVersion%
ECHO Android SDK Path: %BUILD_TOOLS%

REM The Android SDK Build Tools location
SET UNITY_EXE="%programfiles%\Unity\Hub\Editor\%UnityVersion%\Editor"
SET UNITY_LOGS="%LOCALAPPDATA%\Unity\Editor\Editor.log"
ECHO Unity Editor Path: %UNITY_EXE%

REM The location of android.jar for the current API level
REM SET ANDROID_JAR=%HOMEDRIVE%%HOMEPATH%\AppData\Local\Android\Sdk\platforms\android-29\android.jar

REM === CONFIGURATION END ===============================================

TITLE Building the Arthur APK...
PUSHD "%~dp0"
SET PROJ=%~dp0
ECHO Project Path : %PROJ%
REM setlocal DisableDelayedExpansion

REM EnableExtensions DisableDelayedExpansion
if not exist Builds\* md Builds || (pause & GOTO EXIT)

SET BUILD_PATH=%PROJ%Builds\
SET APK_PATH=%BUILD_PATH%%Identifier%_%Version%_%BuildNumber%_%Server%.apk
REM ECHO %BUILD_PATH%

REM GOTO CONTINUE_BUILD
IF EXIST "%APK_PATH%" (GOTO ASK_USER) ELSE (GOTO CONTINUE_BUILD)   


:ASK_USER
SET /p DoOverride="Override Existing APK? Y/N : " 

if "%DoOverride%" == "n" GOTO DONT_OVERRIDE 
if "%DoOverride%" == "y" GOTO OVERRIDE

ECHO InValid Input
ECHO Aborting...
GOTO EXIT

:DONT_OVERRIDE
ECHO Aborting...
GOTO EXIT

:OVERRIDE
DEL "%APK_PATH%"
ECHO Old APK Deleted
GOTO CONTINUE_BUILD

:CONTINUE_BUILD
ECHO Building APK
ECHO Build Logs Path: %UNITY_LOGS%
REM cd "%UNITY_EXE%"
CALL %UNITY_EXE%\Unity.exe -quit -batchmode -projectPath %PROJ% -executeMethod AutoBuilder.PerformAndroidBuild -p "%APK_PATH%" -v %Version% -c %BuildNumber% -i %Identifier%
IF %ERRORLEVEL% NEQ 0 GOTO EXIT
ECHO Build Compelted Successfully 
ECHO APK Path : %APK_PATH%

ECHO Signing APK
REM cd "%PROJ%"
CALL %BUILD_TOOLS%\apksigner sign --ks "%PROJ%\arthur.keystore" --ks-key-alias "arthur" --ks-pass pass:"Arthur2019" "%APK_PATH%"
IF %ERRORLEVEL% NEQ 0 GOTO EXIT
ECHO APK Signed

IF "%~7" == "" GOTO EXIT
ECHO Uploading %Identifier% To Channel %Channel%
ovr-platform-util.exe upload-quest-build --app-id "2811606932268926" --app-secret "e9e1350641d3af0736c4b810424a8375" --apk "%APK_PATH%" --channel "%Channel%"



:EXIT
pause
POPD
ENDLOCAL
@echo on