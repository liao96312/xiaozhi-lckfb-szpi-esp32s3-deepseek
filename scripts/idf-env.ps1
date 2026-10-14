# ESP-IDF v6.1 environment for this session.
# Dot-source before running idf.py or build.py:
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   . .\tools\idf-env.ps1
#
# Host notes:
#  * Windows schannel TLS is broken here (SEC_E_NO_CREDENTIALS), so git/curl/
#    PowerShell cannot reach github.com. ESP-IDF's downloads use
#    dl.espressif.com, which works, and IDF_GITHUB_ASSETS redirects GitHub
#    release URLs there.
#  * PYTHONUTF8=1 stops idf.py aborting on this non-UTF-8 console code page.
#  * The upstream export.ps1/activate_venv.py path is unreliable here, so the
#    toolchain environment is taken straight from `idf_tools.py export`.

$env:IDF_PATH = 'D:\Espressif\frameworks\esp-idf-v6.1'
$env:IDF_TOOLS_PATH = 'C:\Users\tardy\.espressif'
$env:IDF_PYTHON_ENV_PATH = 'C:\Users\tardy\.espressif\python_env\idf6.1_py3.13_env'
$env:ESP_IDF_VERSION = '6.1'
$env:PYTHONUTF8 = '1'
$env:IDF_GITHUB_ASSETS = 'dl.espressif.com/github_assets'
$env:IDF_PIP_WHEELS_URL = 'https://dl.espressif.com/pypi'

$python = Join-Path $env:IDF_PYTHON_ENV_PATH 'Scripts\python.exe'

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
