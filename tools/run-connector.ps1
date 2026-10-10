# ZHKU-Connector 启动器（白云校区）
#
#   * 单实例守卫：已经在跑就不再启动。
#     同一账号同时登录会被学校判定为"共享"并冻结，所以这一步不能省。
#     判断：① 锁文件 logs\.connector.pid 里的进程还活着（最可靠）
#           ② 退一步按命令行匹配进程列表（锁文件被删时兜底）
#   * 输出同时写入 logs\connector-日期.log（由 Python 侧的日志器负责）
param([switch]$Quiet)

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot      # tools 的上一级 = 项目根
Set-Location $root
$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$lockFile = Join-Path $logDir '.connector.pid'
$script:lockOwner = $false

function Get-RunningInstance {
    if (Test-Path $lockFile) {
        $raw = (Get-Content $lockFile -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($raw -match '^\d+$') {
            $p = Get-Process -Id ([int]$raw) -ErrorAction SilentlyContinue
            if ($p) { return "PID $raw（锁文件）" }
        }
    }
    try {
        $others = Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
                  Where-Object { $_.CommandLine -and $_.CommandLine -like '*Connector.py*' }
        if ($others) {
            $pids = ($others | ForEach-Object { $_.ProcessId }) -join ', '
            return "$pids（进程列表）"
        }
    } catch { }
    return $null
}

$who = Get-RunningInstance
if ($who) {
    Write-Host "[跳过] 已经有一个 Connector 在运行：$who"
    Write-Host "       同一账号同时登录会被学校判定为共享并冻结，所以不重复启动。"
    Write-Host "       要重启：先在任务管理器里结束那个 python.exe，再运行本脚本。"
    if (-not $Quiet) { Start-Sleep -Seconds 6 }
    exit 0
}

try {
    Set-Content -Path $lockFile -Value $PID -Encoding ascii -ErrorAction Stop
    $script:lockOwner = $true
} catch {
    Write-Host "[提示] 锁文件写入失败（$($_.Exception.Message)），本次仍会启动。"
}

$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) {
    Write-Host "[错误] PATH 里找不到 python。请安装 Python 并勾选 Add to PATH。"
    if ($script:lockOwner) { Remove-Item $lockFile -ErrorAction SilentlyContinue }
    if (-not $Quiet) { Read-Host '按回车退出' }
    exit 1
}
Write-Host "使用 Python：$python"

Write-Host "启动 ZHKU-Connector（Ctrl+C 可强制退出）..."
Write-Host ("=" * 58)
& $python '.\src\Connector.py'
$rc = $LASTEXITCODE
Write-Host ("=" * 58)
Write-Host "程序已退出（退出码 $rc）。"
Write-Host "日志文件：$logDir\connector-$(Get-Date -Format 'yyyy-MM-dd').log"
if ($rc -ne 0) {
    Write-Host ''
    Write-Host '如果是因为断网导致登录失败：日志已留档，能上网时把它发出来即可排查。'
}

if ($script:lockOwner) { Remove-Item $lockFile -ErrorAction SilentlyContinue }
if (-not $Quiet) { Read-Host '按回车关闭窗口' }
exit $rc
