@echo off
title ZHKU-Connector 自动登录（白云校区）
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run-connector.ps1"
exit /b %ERRORLEVEL%
