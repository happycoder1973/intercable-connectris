param (
    [string]$GodotExe = "Godot_Engine\Godot_v4.3-stable_mono_win64_console.exe"
)

Write-Host "Building project before running tests..." -ForegroundColor Cyan
& $GodotExe --headless --build-solutions

Write-Host "Running Godot C# tests..." -ForegroundColor Cyan

# Run the test runner scene
& $GodotExe --headless res://src/Tests/TestRunner.tscn
$ExitCode = $LASTEXITCODE

if ($ExitCode -ne 0) {
    Write-Host "`nTests failed with exit code $ExitCode!" -ForegroundColor Red
    exit $ExitCode
} else {
    Write-Host "`nAll tests passed successfully!" -ForegroundColor Green
    exit 0
}
