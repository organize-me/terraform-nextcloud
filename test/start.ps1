$ErrorActionPreference = "Stop"

$terraform = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $terraform) {
    $env:Path += ";$([Environment]::GetEnvironmentVariable('Path', 'User'))"
    $terraform = Get-Command terraform -ErrorAction SilentlyContinue
}
if (-not $terraform) {
    throw "Terraform is required. Install it with: winget install --id Hashicorp.Terraform --exact"
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker Desktop is required."
}

docker info --format '{{.OSType}}' *> $null
if ($LASTEXITCODE -ne 0) {
    $desktop = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (-not (Test-Path -LiteralPath $desktop)) {
        throw "Start the Docker daemon and rerun this script."
    }
    Start-Process -FilePath $desktop
    $deadline = (Get-Date).AddMinutes(2)
    do {
        Start-Sleep -Seconds 3
        docker info --format '{{.OSType}}' *> $null
    } while ($LASTEXITCODE -ne 0 -and (Get-Date) -lt $deadline)
    if ($LASTEXITCODE -ne 0) {
        throw "Docker did not start within two minutes."
    }
}

$envFile = Join-Path $PSScriptRoot '.env'
$terraformDir = Join-Path $PSScriptRoot 'terraform'
$varsFile = Join-Path $terraformDir 'local.auto.tfvars'

foreach ($name in @('local.auto.tfvars', 'terraform.tfstate', 'terraform.tfstate.backup')) {
    $oldPath = Join-Path $PSScriptRoot $name
    $newPath = Join-Path $terraformDir $name
    if (Test-Path -LiteralPath $oldPath) {
        if (Test-Path -LiteralPath $newPath) {
            throw "Both old and new test copies of $name exist. Resolve the conflict before starting."
        }
        Move-Item -LiteralPath $oldPath -Destination $newPath
    }
}

if ((Test-Path -LiteralPath $envFile) -ne (Test-Path -LiteralPath $varsFile)) {
    throw "Only one test credential file exists. Restore the missing file or destroy the test stack before deleting both files."
}

if (-not (Test-Path -LiteralPath $envFile)) {
    if (Test-Path -LiteralPath (Join-Path $terraformDir 'terraform.tfstate')) {
        throw "Test state exists without its credentials. Restore the credential files before starting this stack."
    }
    function New-TestPassword {
        $bytes = New-Object byte[] 32
        $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $random.GetBytes($bytes)
        } finally {
            $random.Dispose()
        }
        return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    }

    $rootPassword = New-TestPassword
    $dbPassword = New-TestPassword
    $adminPassword = New-TestPassword
    $dockerHost = if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        'npipe:////./pipe/docker_engine'
    } else {
        'unix:///var/run/docker.sock'
    }
    $encoding = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($envFile, "MYSQL_ROOT_PASSWORD=$rootPassword`n", $encoding)
    [IO.File]::WriteAllText($varsFile, "docker_host = `"$dockerHost`"`nmysql_root_password = `"$rootPassword`"`nnextcloud_db_password = `"$dbPassword`"`nnextcloud_password = `"$adminPassword`"`n", $encoding)
} else {
    $envText = [IO.File]::ReadAllText($envFile)
    $varsText = [IO.File]::ReadAllText($varsFile)
    $envRoot = [regex]::Match($envText, '(?m)^MYSQL_ROOT_PASSWORD=(.+)$')
    $tfRoot = [regex]::Match($varsText, '(?m)^mysql_root_password\s*=\s*"([^"]+)"')
    $tfAdmin = [regex]::Match($varsText, '(?m)^nextcloud_password\s*=\s*"([^"]+)"')
    if (-not $envRoot.Success -or -not $tfRoot.Success -or -not $tfAdmin.Success -or
        $envRoot.Groups[1].Value.TrimEnd("`r") -cne $tfRoot.Groups[1].Value) {
        throw "The local test credentials are missing or the MySQL root passwords do not match."
    }
    $adminPassword = $tfAdmin.Groups[1].Value
    $updatedVars = [regex]::Replace($varsText, '(?m)^install_root\s*=\s*"[^"]*"\r?\n', '')
    if ($updatedVars -cne $varsText) {
        [IO.File]::WriteAllText($varsFile, $updatedVars, (New-Object System.Text.UTF8Encoding $false))
    }
}

Push-Location $PSScriptRoot
try {
    docker compose --env-file .env up -d --wait
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed." }

    foreach ($name in @('organize-me-test-nextcloud', 'organize-me-test-nextcloud-worker')) {
        $existing = @(docker ps -a --filter "name=^/$name$" --format '{{.Names}}')
        if ($LASTEXITCODE -ne 0) { throw "Could not check $name." }
        if ($existing.Count -gt 0) {
            $running = @(docker ps --filter "name=^/$name$" --format '{{.Names}}')
            if ($LASTEXITCODE -ne 0) { throw "Could not check whether $name is running." }
            if ($running.Count -eq 0) {
                docker start $name
                if ($LASTEXITCODE -ne 0) { throw "Could not restart $name." }
            }
        }
    }

    & $terraform.Source -chdir=terraform init -input=false -lockfile=readonly
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed." }

    & $terraform.Source -chdir=terraform apply -input=false -auto-approve
    if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed." }
} finally {
    Pop-Location
}

$deadline = (Get-Date).AddMinutes(3)
do {
    try {
        $status = Invoke-RestMethod -Uri 'http://127.0.0.1:18000/status.php' -TimeoutSec 10
        if ($status.installed -and -not $status.maintenance) {
            Write-Output "Nextcloud: http://localhost:18000"
            Write-Output "Mailpit:   http://localhost:18025"
            Write-Output "S3:        http://localhost:19090 (scripts use http://s3:9090)"
            Write-Output "Admin:     admin"
            Write-Output "Password:  $adminPassword"
            return
        }
    } catch [System.Net.WebException] {
        # The web server can refuse connections while Nextcloud initializes.
    }
    Start-Sleep -Seconds 5
} while ((Get-Date) -lt $deadline)
throw "Nextcloud did not become ready within three minutes. Check docker logs organize-me-test-nextcloud."
