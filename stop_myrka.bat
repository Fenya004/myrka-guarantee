@echo off
title Остановка Myrka
echo Останавливаем все Node.js процессы...
taskkill /f /im node.exe
echo Готово.
pause