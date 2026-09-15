@echo off
setlocal EnableExtensions
cd /d "%~dp0.."
set "ROOT=%CD%"
set "LOG=%ROOT%\godot_debug.log"

echo ================================================ > "%LOG%"
echo TRY HACKING ME NOW - GODOT DEBUG RUN >> "%LOG%"
echo Started: %date% %time% >> "%LOG%"
echo Project: %ROOT% >> "%LOG%"
echo ================================================ >> "%LOG%"
echo. >> "%LOG%"

set "GODOT="
where godot.exe >nul 2>&1 && set "GODOT=godot.exe"
if not defined GODOT where godot4.exe >nul 2>&1 && set "GODOT=godot4.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\godot.exe" set "GODOT=%ProgramFiles%\Godot\godot.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Godot\godot.exe" set "GODOT=%LOCALAPPDATA%\Godot\godot.exe"

if not defined GODOT (
    echo [FATAL] Godot executable was not found. >> "%LOG%"
    echo.
    echo [ERRO] Nao encontrei o Godot no PATH nem nos locais comuns.
    echo Adicione o Godot ao PATH ou edite este BAT e coloque o caminho do executavel.
    echo.
    pause
    exit /b 1
)

echo [INFO] Godot executable: %GODOT% >> "%LOG%"
echo [INFO] Launching project... >> "%LOG%"
echo.
echo ================================================
echo TRY HACKING ME NOW - DEBUG MODE
echo ================================================
echo Log: %LOG%
echo.
echo O jogo vai abrir normalmente.
echo Feche o jogo quando terminar o teste.
echo Depois me envie o arquivo godot_debug.log.
echo.

"%GODOT%" --path "%ROOT%" --verbose >> "%LOG%" 2>&1
set "EXITCODE=%ERRORLEVEL%"

echo. >> "%LOG%"
echo ================================================ >> "%LOG%"
echo Process exit code: %EXITCODE% >> "%LOG%"
echo Finished: %date% %time% >> "%LOG%"
echo ================================================ >> "%LOG%"

echo.
echo ================================================
echo DEBUG FINISHED - Exit code: %EXITCODE%
echo ================================================
echo.
echo O arquivo godot_debug.log foi atualizado.
echo Se houver erro, envie esse arquivo para o ChatGPT.
echo.
pause
exit /b %EXITCODE%
