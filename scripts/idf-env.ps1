# ESP-IDF v6.1 environment for this session.
# Dot-source before running idf.py or build.py:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   . .\scripts\idf-env.ps1
#
# Paths can be overridden with environment variables set beforehand:
#   IDF_PATH             (default: D:\Espressif\frameworks\esp-idf-v6.1)
#   IDF_TOOLS_PATH       (default: $HOME\.espressif)
#   IDF_PYTHON_ENV_PATH  (default: $IDF_TOOLS_PATH\python_env\idf6.1_py3.13_env)
#
# Host notes:
#  * Windows schannel TLS is broken here (SEC_E_NO_CREDENTIALS), so git/curl/
#    PowerShell cannot reach github.com. ESP-IDF's downloads use
#    dl.espressif.com, which works, and IDF_GITHUB_ASSETS redirects GitHub
#    release URLs there.
#  * PYTHONUTF8=1 stops idf.py aborting on this non-UTF-8 console code page.
#  * The upstream export.ps1/activate_venv.py path is unreliable here, so the
#    toolchain environment is taken straight from `idf_tools.py export`.

if (-not $env:IDF_PATH) { $env:IDF_PATH = 'D:\Espressif\frameworks\esp-idf-v6.1' }
if (-not $env:IDF_TOOLS_PATH) { $env:IDF_TOOLS_PATH = Join-Path $HOME '.espressif' }
if (-not $env:IDF_PYTHON_ENV_PATH) {
    $env:IDF_PYTHON_ENV_PATH = Join-Path $env:IDF_TOOLS_PATH 'python_env\idf6.1_py3.13_env'
}
$env:ESP_IDF_VERSION = '6.1'
$env:PYTHONUTF8 = '1'
$env:IDF_GITHUB_ASSETS = 'dl.espressif.com/github_assets'
$env:IDF_PIP_WHEELS_URL = 'https://dl.espressif.com/pypi'

if (-not (Test-Path (Join-Path $env:IDF_PATH 'tools\idf.py'))) {
    throw "ESP-IDF not found at IDF_PATH=$env:IDF_PATH. Set `$env:IDF_PATH to your ESP-IDF v6.1 install."
}
$python = Join-Path $env:IDF_PYTHON_ENV_PATH 'Scripts\python.exe'
if (-not (Test-Path $python)) {
    throw "IDF Python not found: $python. Set `$env:IDF_PYTHON_ENV_PATH (or IDF_TOOLS_PATH) to match your install."
}

$lines = & $python "$env:IDF_PATH\tools\idf_tools.py" export --format key-value
if ($LASTEXITCODE -ne 0) {
    Write-Error 'idf_tools.py export failed'
    return
}

foreach ($line in $lines) {
    $name, $value = $line -split '=', 2
    if (-not $name) { continue }
    switch ($name) {
        'PATH' {
            # The exported PATH ends with %PATH%; expand it against the current one.
            $prefix = $value -replace '%PATH%$', ''
            $env:PATH = $prefix + $env:PATH
        }
        default { Set-Item -Path "Env:$name" -Value $value }
    }
}

# Convenience wrapper so `idf.py ...` works like a normal command.
function global:idf.py { & $python "$env:IDF_PATH\tools\idf.py" @args }

Write-Host "ESP-IDF $env:ESP_IDF_VERSION ready (IDF_PATH=$env:IDF_PATH)"
