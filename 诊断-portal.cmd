@echo off
chcp 65001 >nul
setlocal EnableExtensions
set "ROOT=%~dp0"
title ZHKU-Connector 诊断（未登录时跑最有价值）
cd /d "%ROOT%"

echo ==================================================
echo   portal 诊断（只读探测，不提交账号密码）
echo   建议在「未登录」时跑：能抓到真实的登录页地址
echo ==================================================
echo.

where python >nul 2>&1
if errorlevel 1 (
  echo [错误] 没找到 python 命令。
  echo.
  pause
  exit /b 1
)

python ".\diagnose.py" > ".\logs\diagnose-last.txt" 2>&1
type ".\logs\diagnose-last.txt"
set "RC=%ERRORLEVEL%"

echo.
echo --------------------------------------------------
echo 结果已保存到：%ROOT%logs\diagnose-last.txt
echo 恢复网络后把这个文件发我（或让我直接读）即可。
echo.
pause
endlocal
