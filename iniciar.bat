@echo off
title Leilao de Imoveis - Servidor Local
echo.
echo  ========================================
echo   🏠 Leilao de Imoveis - Extrator
echo  ========================================
echo.
echo  Iniciando servidor PHP 8.4...
echo  Acesse: http://localhost:8000/public/
echo.
echo  Pressione Ctrl+C para encerrar.
echo  ========================================
echo.

start "" "http://localhost:8000/public/"

"C:\laragon\bin\php\php-8.4.24-Win32-vs17-x64\php.exe" -S localhost:8000 -t "%~dp0"

pause
