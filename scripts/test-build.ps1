#!/usr/bin/env pwsh
# PowerShell script to run Docker build tests for NutAndJamPack

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "client", "server")]
    [string]$TestType = "all",
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoBuild
)

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n═══ $Message ═══" -ForegroundColor Yellow
}

# Check if Docker is running
function Test-Docker {
    Write-Step "Checking Docker availability"
    try {
        docker info | Out-Null
        Write-Success "Docker is running"
        return $true
    } catch {
        Write-Error "Docker is not running or not installed"
        Write-Info "Please start Docker Desktop and try again"
        return $false
    }
}

# Clean build artifacts
function Clear-BuildArtifacts {
    Write-Step "Cleaning build artifacts"
    
    if (Test-Path "build-output") {
        Remove-Item -Recurse -Force "build-output"
        Write-Success "Removed build-output directory"
    }
    
    if (Test-Path "*.mrpack") {
        Remove-Item -Force "*.mrpack"
        Write-Success "Removed .mrpack files"
    }
    
    # Clean Docker containers and images
    docker-compose down --rmi local 2>&1 | Out-Null
    Write-Success "Cleaned Docker resources"
}

# Test client build
function Test-ClientBuild {
    Write-Step "Testing Client Build"
    
    $buildCmd = if ($NoBuild) {
        "docker-compose run --rm client-test"
    } else {
        "docker-compose up --build client-test"
    }
    
    Write-Info "Running: $buildCmd"
    $result = Invoke-Expression $buildCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Client build test PASSED"
        return $true
    } else {
        Write-Error "Client build test FAILED"
        return $false
    }
}

# Test server build
function Test-ServerBuild {
    Write-Step "Testing Server Build and Startup"
    
    $buildCmd = if ($NoBuild) {
        "docker-compose run --rm server-test"
    } else {
        "docker-compose up --build server-test"
    }
    
    Write-Info "Running: $buildCmd"
    Write-Info "This will take several minutes as the server downloads and starts..."
    
    $result = Invoke-Expression $buildCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Server build test PASSED"
        return $true
    } else {
        Write-Error "Server build test FAILED"
        return $false
    }
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   NutAndJamPack Docker Build Test Suite          ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

# Check Docker
if (-not (Test-Docker)) {
    exit 1
}

# Clean if requested
if ($Clean) {
    Clear-BuildArtifacts
}

# Create build-output directory
New-Item -ItemType Directory -Force -Path "build-output/client" | Out-Null
New-Item -ItemType Directory -Force -Path "build-output/server" | Out-Null

# Run tests based on type
$clientPassed = $false
$serverPassed = $false

switch ($TestType) {
    "client" {
        $clientPassed = Test-ClientBuild
    }
    "server" {
        $serverPassed = Test-ServerBuild
    }
    "all" {
        $clientPassed = Test-ClientBuild
        $serverPassed = Test-ServerBuild
    }
}

# Summary
Write-Step "Test Summary"

if ($TestType -eq "all") {
    Write-Host "`nClient Test: " -NoNewline
    if ($clientPassed) {
        Write-Host "PASSED ✓" -ForegroundColor Green
    } else {
        Write-Host "FAILED ✗" -ForegroundColor Red
    }
    
    Write-Host "Server Test: " -NoNewline
    if ($serverPassed) {
        Write-Host "PASSED ✓" -ForegroundColor Green
    } else {
        Write-Host "FAILED ✗" -ForegroundColor Red
    }
    
    if ($clientPassed -and $serverPassed) {
        Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║   ALL TESTS PASSED! ✓                             ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║   SOME TESTS FAILED! ✗                            ║" -ForegroundColor Red
        Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Red
        exit 1
    }
} else {
    $passed = if ($TestType -eq "client") { $clientPassed } else { $serverPassed }
    if ($passed) {
        Write-Success "Test completed successfully!"
        exit 0
    } else {
        Write-Error "Test failed!"
        exit 1
    }
}
