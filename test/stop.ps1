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
    throw "Docker Desktop is not running."
}

$envFile = Join-Path $PSScriptRoot '.env'
$terraformDir = Join-Path $PSScriptRoot 'terraform'
$stateFile = Join-Path $terraformDir 'terraform.tfstate'
$varsFile = Join-Path $terraformDir 'local.auto.tfvars'
if ((Test-Path -LiteralPath $stateFile) -and
    (-not (Test-Path -LiteralPath $envFile) -or -not (Test-Path -LiteralPath $varsFile))) {
    throw "Test state exists without its credentials. Restore them before destroying the stack."
}

Push-Location $PSScriptRoot
try {
    if (Test-Path -LiteralPath $stateFile) {
        docker compose --env-file .env up -d --wait
        if ($LASTEXITCODE -ne 0) { throw "Could not start MySQL for Terraform destroy." }

        & $terraform.Source -chdir=terraform init -input=false -lockfile=readonly
        if ($LASTEXITCODE -ne 0) { throw "Terraform init failed; test data was not deleted." }

        & $terraform.Source -chdir=terraform destroy -input=false -auto-approve
        if ($LASTEXITCODE -ne 0) { throw "Terraform destroy failed; test data was not deleted." }
    }

    if (Test-Path -LiteralPath $envFile) {
        docker compose --env-file .env down -v
        if ($LASTEXITCODE -ne 0) { throw "Could not remove test Compose resources." }
    } elseif (Test-Path -LiteralPath $stateFile) {
        throw "Missing test/.env; cannot remove test Compose resources."
    }
} finally {
    Pop-Location
}

foreach ($path in @(
    $envFile,
    $varsFile,
    $stateFile,
    (Join-Path $terraformDir 'terraform.tfstate.backup'),
    (Join-Path $PSScriptRoot 'local.auto.tfvars'),
    (Join-Path $PSScriptRoot 'terraform.tfstate'),
    (Join-Path $PSScriptRoot 'terraform.tfstate.backup')
)) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
    }
}

$generatedDirs = @(
    (Join-Path $terraformDir '.terraform'),
    (Join-Path $PSScriptRoot 'bin'),
    (Join-Path $PSScriptRoot 'tmp')
)
foreach ($dir in $generatedDirs) {
    if (Test-Path -LiteralPath $dir) {
        Remove-Item -LiteralPath $dir -Recurse -Force
    }
}

Write-Output "Test stack destroyed, including containers, volumes, credentials, and state. Run .\test\start.ps1 for a fresh stack."
