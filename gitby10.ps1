# -----------------------------
# gitby10_force.ps1
# -----------------------------
# Commit and push local repo in batches of 10, ignoring locked files
# -----------------------------

# CONFIG
$branch = "main"
$batchSize = 10
$repoUrl = "https://github.com/KsibetTawkit/TAOUKIT.git"

Write-Host "`n===== GIT BATCH FORCE PUSH =====`n" -ForegroundColor Cyan

# Ensure Git repo initialized
if (-Not (Test-Path ".git")) {
    git init
    git remote add origin $repoUrl
    git checkout -b $branch
} else {
    git checkout $branch
}

# List all files recursively
$allFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName
$totalFiles = $allFiles.Count
Write-Host ("Total files to process: " + $totalFiles) -ForegroundColor Cyan

$batchIndex = 0
for ($i = 0; $i -lt $totalFiles; $i += $batchSize) {
    $batchIndex++
    $end = [Math]::Min($i + $batchSize - 1, $totalFiles - 1)
    $batch = $allFiles[$i..$end]

    $startIndex = $i + 1
    $endIndex = $end + 1

    Write-Host ("--- Batch " + $batchIndex + " (files " + $startIndex + " to " + $endIndex + ") ---") -ForegroundColor Magenta

    foreach ($f in $batch) {
        try {
            # Check git status
            $status = git status --porcelain "$f" 2>$null
            if ($status -match '^A') { $action = "A" }
            elseif ($status -match '^M') { $action = "M" }
            elseif ($status -match '^D') { $action = "D" }
            else { $action = "?" }

            Write-Host ("  " + $action + " : " + $f)

            # Try add file, skip if locked
            git add "$f" 2>$null
        } catch {
            Write-Host ("  SKIPPED (locked or error) : " + $f) -ForegroundColor Yellow
        }
    }

    # Commit batch
    $commitMsg = "Batch " + $batchIndex + ": files " + $startIndex + " to " + $endIndex
    git commit -m "$commitMsg" 2>$null

    Write-Host ("Commit batch " + $batchIndex + " done.") -ForegroundColor Green

    # Push batch force
    git push origin $branch --force
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("Error pushing batch " + $batchIndex + ". Stopping.") -ForegroundColor Red
        exit 1
    } else {
        Write-Host ("Push batch " + $batchIndex + " OK.") -ForegroundColor Green
    }
}

Write-Host ("All files have been pushed in batches of " + $batchSize + ".") -ForegroundColor Cyan
