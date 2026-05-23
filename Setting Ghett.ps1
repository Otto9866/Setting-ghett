# ===== Firebase Config =====
$firebaseUrl = "https://ghett-f9f8e-default-rtdb.asia-southeast1.firebasedatabase.app"

# ===== Get HWID =====
function Get-HWID {
    return (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
}

# ===== Check License =====
function Check-License {
    param($key)

    $hwid = Get-HWID
    $url  = "$firebaseUrl/licenses/$key.json"

    try {
        $data = Invoke-RestMethod -Uri $url -Method Get

        if ($null -eq $data) {
            Write-Host "Invalid Key" -ForegroundColor Red
            exit
        }

        if ($data.active -ne $true) {
            Write-Host "Invalid Key" -ForegroundColor Red
            exit
        }

        if ($null -eq $data.hwid -or $data.hwid -eq "null") {
            $body = '{"hwid":"' + $hwid + '"}'
            Invoke-RestMethod -Uri "$firebaseUrl/licenses/$key.json" `
                -Method Patch `
                -Body $body `
                -ContentType "application/json" | Out-Null
            Write-Host "Valid Key! Loading..." -ForegroundColor Green
        }
        elseif ($data.hwid -eq $hwid) {
            Write-Host "Valid Key! Loading..." -ForegroundColor Green
        }
        else {
            Write-Host "Invalid Key" -ForegroundColor Red
            exit
        }

    } catch {
        Write-Host "Cannot connect to server" -ForegroundColor Red
        exit
    }
}

# ===== Enter Key =====
Clear-Host
Write-Host "================================" -ForegroundColor Cyan
Write-Host "        Cheetos on top          " -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
$key = Read-Host "Enter License Key"

Check-License -key $key
Start-Sleep -Seconds 1

# ===== Menu =====
function Show-Menu {
    Clear-Host
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "          Setting GHETT         " -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Run - Ghett" -ForegroundColor Cyan
    Write-Host " [R] Reset - Ghett" -ForegroundColor Cyan
    Write-Host " [Q] Quit" -ForegroundColor Cyan
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Select"

    switch ($choice.ToUpper()) {
        "1" {
            Clear-Host
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host "          Setting GHETT         " -ForegroundColor Cyan
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host ""

            $job = Start-Job -ScriptBlock {
                # สร้าง Restore Point ก่อน
                Checkpoint-Computer -Description "Cheetos Backup" -RestorePointType "MODIFY_SETTINGS"
                # คำสั่งปรับคอมตรงนี้
            }

            $spinner = @('/', '|', '\', '-')
            $i = 0
            while ($job.State -eq "Running") {
                Write-Host "`r Loading... $($spinner[$i % 4])" -NoNewline -ForegroundColor Cyan
                $i++
                Start-Sleep -Milliseconds 100
            }

            Receive-Job $job | Out-Null
            Remove-Job $job
            Write-Host "`r Done!              " -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter to go back"
        }
        "R" {
            Clear-Host
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host "            Resetting           " -ForegroundColor Cyan
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host ""

            $job = Start-Job -ScriptBlock {
                # ดึง Restore Point ที่สร้างไว้กลับมา
                $restore = Get-ComputerRestorePoint | Where-Object { $_.Description -eq "Cheetos Backup" } | Select-Object -Last 1
                if ($restore) {
                    Restore-Computer -RestorePoint $restore.SequenceNumber -Confirm:$false
                }
            }

            $spinner = @('/', '|', '\', '-')
            $i = 0
            while ($job.State -eq "Running") {
                Write-Host "`r Resetting... $($spinner[$i % 4])" -NoNewline -ForegroundColor Red
                $i++
                Start-Sleep -Milliseconds 100
            }

            Receive-Job $job | Out-Null
            Remove-Job $job
            Write-Host "`r Done!              " -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter to go back"
        }
        "Q" {
            Write-Host "Exiting..." -ForegroundColor Gray
        }
    }

} while ($choice.ToUpper() -ne "Q")