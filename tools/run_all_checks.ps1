param(
	[string]$GodotExe = $env:GODOT_EXE
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($GodotExe)) {
	$godotCommand = Get-Command godot -ErrorAction SilentlyContinue
	if ($null -ne $godotCommand) {
		$GodotExe = $godotCommand.Source
	} elseif (Test-Path "C:\Godot\Godot_v4.7.2-stable_win64.exe") {
		$GodotExe = "C:\Godot\Godot_v4.7.2-stable_win64.exe"
	} else {
		throw "Set GODOT_EXE or pass -GodotExe with a Godot 4 executable path."
	}
}

if (-not (Test-Path -LiteralPath $GodotExe)) {
	throw "Godot executable not found: $GodotExe"
}

Write-Host "Importing and indexing the project..."
& $GodotExe --headless --editor --path $projectRoot --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Auditing assets..."
& $GodotExe --headless --path $projectRoot --script "res://tools/asset_auditor.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running unit tests..."
& $GodotExe --headless --path $projectRoot --script "res://tests/test_runner.gd"
exit $LASTEXITCODE
