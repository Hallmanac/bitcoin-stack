# =============================================================================
# Bitcoin Stack Setup Script (Windows PowerShell)
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Write-Host ""
Write-Host "=============================================================================" -ForegroundColor Blue
Write-Host "  Bitcoin Stack Setup" -ForegroundColor Blue
Write-Host "  Bitcoin Knots + LND + Tor" -ForegroundColor Blue
Write-Host "=============================================================================" -ForegroundColor Blue
Write-Host ""

# -----------------------------------------------------------------------------
# Check prerequisites
# -----------------------------------------------------------------------------
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

try {
    $dockerVersion = docker --version
    Write-Host "Found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Visit: https://docs.docker.com/desktop/install/windows-install/"
    exit 1
}

try {
    $composeVersion = docker compose version
    Write-Host "Found: Docker Compose" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker Compose is not working." -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# Create .env file
# -----------------------------------------------------------------------------
Set-Location $ProjectDir

if (Test-Path ".env") {
    Write-Host "Found existing .env file." -ForegroundColor Yellow
    $regen = Read-Host "Do you want to regenerate it? (y/N)"
    if ($regen -eq "y" -or $regen -eq "Y") {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        Copy-Item ".env" ".env.backup.$timestamp"
        Write-Host "Backed up existing .env file."
        Copy-Item ".env.example" ".env"
    } else {
        Write-Host "Keeping existing .env file."
    }
} else {
    Write-Host "Creating .env file from template..."
    Copy-Item ".env.example" ".env"
}

# -----------------------------------------------------------------------------
# Generate RPC password
# -----------------------------------------------------------------------------
Write-Host "Generating secure RPC password..." -ForegroundColor Yellow

# Generate 32 random bytes as hex
$bytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$RpcPass = [BitConverter]::ToString($bytes) -replace '-', ''
$RpcPass = $RpcPass.ToLower()

# Update .env with generated password
$envContent = Get-Content ".env" -Raw
$envContent = $envContent -replace 'BITCOIN_RPC_PASS=.*', "BITCOIN_RPC_PASS=$RpcPass"
Set-Content ".env" $envContent -NoNewline

Write-Host "RPC password generated and saved to .env" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Create data directories
# -----------------------------------------------------------------------------
Write-Host "Creating data directories..." -ForegroundColor Yellow

# Read DATA_DIR from .env
$envContent = Get-Content ".env"
$dataDir = ($envContent | Where-Object { $_ -match "^DATA_DIR=" }) -replace "DATA_DIR=", ""
if (-not $dataDir) { $dataDir = "./data" }

# Convert relative path to absolute
if ($dataDir.StartsWith("./")) {
    $dataDir = Join-Path $ProjectDir $dataDir.Substring(2)
}

New-Item -ItemType Directory -Force -Path "$dataDir/bitcoin" | Out-Null
New-Item -ItemType Directory -Force -Path "$dataDir/lnd" | Out-Null
New-Item -ItemType Directory -Force -Path "$dataDir/tor" | Out-Null

Write-Host "Data directories created at: $dataDir" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Generate config files from templates
# -----------------------------------------------------------------------------
Write-Host "Generating configuration files..." -ForegroundColor Yellow

# Read .env variables
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match "^([^#][^=]+)=(.*)$") {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Generate bitcoin.conf from template
$bitcoinTemplate = Get-Content "config/bitcoin.conf.template" -Raw
foreach ($key in $envVars.Keys) {
    $bitcoinTemplate = $bitcoinTemplate -replace "\`$\{$key\}", $envVars[$key]
    $bitcoinTemplate = $bitcoinTemplate -replace "\`$$key", $envVars[$key]
}
Set-Content "config/bitcoin.conf" $bitcoinTemplate
Write-Host "Generated config/bitcoin.conf"

# Copy lnd.conf template (mostly static)
Copy-Item "config/lnd.conf.template" "config/lnd.conf"
Write-Host "Generated config/lnd.conf"

Write-Host "Configuration files generated." -ForegroundColor Green

# -----------------------------------------------------------------------------
# Build Docker images
# -----------------------------------------------------------------------------
Write-Host "Building Docker images (this may take a few minutes)..." -ForegroundColor Yellow
Write-Host "This includes GPG signature verification of binaries."

docker compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed." -ForegroundColor Red
    exit 1
}

Write-Host "Docker images built successfully." -ForegroundColor Green

# -----------------------------------------------------------------------------
# Done!
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "=============================================================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "=============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your RPC credentials:"
Write-Host "  Username: $($envVars['BITCOIN_RPC_USER'])" -ForegroundColor Cyan
Write-Host "  Password: $RpcPass" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Review and customize .env if needed"
Write-Host "  2. Start the stack:  docker compose up -d"
Write-Host "  3. Monitor logs:     docker compose logs -f"
Write-Host "  4. Check status:     docker compose ps"
Write-Host ""
Write-Host "After Bitcoin syncs (~3-7 days), create your LND wallet:"
Write-Host "  docker exec -it lnd lncli create"
Write-Host ""
Write-Host "For more information, see README.md"
Write-Host ""
