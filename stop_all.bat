@echo off
title Myrka - Stop All Services
echo Остановка всех служб "Гарант Сервис | Myrka"...
taskkill /f /im node.exe >nul 2>nul
taskkill /f /im ngrok.exe >nul 2>nul
echo Готово.
timeout /t 2 /nobreak >nul
exit