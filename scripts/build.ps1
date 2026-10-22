# Rebuild the xiaozhi firmware for the LCKFB SZPI ESP32-S3 (立创·实战派 S3).
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   .\scripts\build.ps1 [-ProjectDir <path>]
#
# -ProjectDir: the patched 78/xiaozhi-esp32 checkout. Defaults to
# $env:XIAOZHI_PROJECT_DIR, then D:\xz\xiaozhi. Keep it on a short path:
# long paths make ninja's command lines exceed the Windows limit.

param(
    [string]$ProjectDir = $(if ($env:XIAOZHI_PROJECT_DIR) { $env:XIAOZHI_PROJECT_DIR } else { 'D:\xz\xiaozhi' })
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'idf-env.ps1')

$project = $ProjectDir
if (-not (Test-Path $project)) {
    throw "Project not found: $project`nPass -ProjectDir <path> or set XIAOZHI_PROJECT_DIR to your xiaozhi-esp32 checkout."
}

Set-Location $project
& "$env:IDF_PYTHON_ENV_PATH\Scripts\python.exe" scripts\build.py lckfb/szpi-esp32s3 --name lichuang-dev
exit $LASTEXITCODE
