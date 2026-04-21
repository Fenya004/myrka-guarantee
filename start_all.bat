@echo off
chcp 65001 >nul
title Myrka - Start All Services
color 0A
echo ========================================
echo   Start Guarantee Service "Myrka"
echo ========================================
echo.

:: Проверка Node.js
where node >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Node.js not found! Install from https://nodejs.org
    pause
    exit /b 1
)
echo [OK] Node.js found

:: Проверка ngrok
where ngrok >nul 2>nul
if errorlevel 1 (
    echo [WARN] ngrok not found in PATH. Mini App will be local only.
    set NGROK=0
) else (
    set NGROK=1
    echo [OK] ngrok found
)

:: Создание папки логов
if not exist logs mkdir logs

:: Запуск Backend
echo Starting Backend (port 3000)...
start "Myrka Backend" cmd /c "cd backend && npm start > ..\logs\backend.log 2>&1"
timeout /t 3 /nobreak >nul

:: Запуск Frontend
echo Starting Frontend (port 5173)...
start "Myrka Frontend" cmd /c "cd frontend && npm run dev > ..\logs\frontend.log 2>&1"
timeout /t 3 /nobreak >nul

:: Запуск ngrok
if %NGROK%==1 (
    echo Starting ngrok tunnel on port 3000...
    start "Myrka ngrok" cmd /c "ngrok http 3000 > ..\logs\ngrok.log 2>&1"
    timeout /t 4 /nobreak >nul
    echo ngrok admin panel: http://localhost:4040
)

:: Открытие браузера
start http://localhost:3000
start http://localhost:5173

echo.
echo ========================================
echo   ALL SERVICES STARTED
echo ========================================
echo   Backend:  http://localhost:3000
echo   Frontend: http://localhost:5173
if %NGROK%==1 echo   ngrok:    http://localhost:4040
echo.
echo   To stop all services run stop_all.bat
echo ========================================
pause