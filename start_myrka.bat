@echo off
title Myrka Guarantee Service
echo ==============================================
echo   Запуск Гарант Сервис | Myrka
echo ==============================================
echo.

if not exist "logs" mkdir logs

echo Проверка наличия Node.js...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Node.js не найден. Установите Node.js с https://nodejs.org
    pause
    exit /b 1
)

echo Установка зависимостей (если не установлены)...
cd backend
if not exist "node_modules" (
    echo Установка backend зависимостей...
    call npm install
    if errorlevel 1 (
        echo Ошибка установки backend зависимостей.
        pause
        exit /b 1
    )
)
cd ..

cd frontend
if not exist "node_modules" (
    echo Установка frontend зависимостей...
    call npm install
    if errorlevel 1 (
        echo Ошибка установки frontend зависимостей.
        pause
        exit /b 1
    )
)
cd ..

echo Запуск бэкенда (порт 3000)...
start "Myrka Backend" cmd /c "cd backend && npm start > ..\logs\backend.log 2>&1"

timeout /t 2 /nobreak >nul

echo Запуск фронтенда (порт 5173)...
start "Myrka Frontend" cmd /c "cd frontend && npm run dev > ..\logs\frontend.log 2>&1"

echo.
echo Сервисы запущены.
echo   - Бэкенд: http://localhost:3000
echo   - Фронтенд: http://localhost:5173 (если нужен отдельно)
echo   - Mini App доступен по http://localhost:3000
echo.
echo Логи пишутся в папку logs.
echo Для остановки закройте окна "Myrka Backend" и "Myrka Frontend"
echo или выполните stop_myrka.bat
echo.
echo Нажмите любую клавишу для выхода (сервисы продолжат работу)...
pause >nul