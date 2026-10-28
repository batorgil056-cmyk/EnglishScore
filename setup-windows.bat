@echo off
setlocal
cd /d "%~dp0"
echo [1/3] Checking Flutter...
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not found in PATH. Open VS Code terminal where Flutter works.
  pause
  exit /b 1
)
echo [2/3] Creating missing Flutter Web project files...
call flutter create . --project-name englishscore_intro --platforms web
if errorlevel 1 (
  echo Flutter project creation failed.
  pause
  exit /b 1
)
echo [3/3] Downloading Flutter dependencies...
call flutter pub get
if errorlevel 1 (
  echo flutter pub get failed.
  pause
  exit /b 1
)
echo.
echo READY. Open this folder in VS Code and run:
echo flutter run -d chrome
pause
