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

        if ($data.hwid -eq "any") {
            Write-Host "Valid Key! Loading..." -ForegroundColor Green
        }
        elseif ($null -eq $data.hwid -or $data.hwid -eq "null") {
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
            Write-Host "HWID Invalid" -ForegroundColor Red
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

            # Restore Point ก่อนเลย
            Write-Host " Creating Restore Point..." -ForegroundColor Cyan
            Checkpoint-Computer -Description "Cheetos Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

            $job = Start-Job -ScriptBlock {

                # ===== QoS Policy FiveM =====
                $fivemSubprocess = Get-ChildItem -Path ([System.IO.DriveInfo]::GetDrives() |
                    Where-Object { $_.DriveType -eq 'Fixed' } |
                    ForEach-Object { "$($_.Name)Users\$env:USERNAME\AppData\Local\FiveM\FiveM.app\data\cache\subprocess.exe" }) `
                    -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

                $fivemExe = Get-ChildItem -Path ([System.IO.DriveInfo]::GetDrives() |
                    Where-Object { $_.DriveType -eq 'Fixed' } |
                    ForEach-Object { "$($_.Name)Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe" }) `
                    -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

                if ($fivemSubprocess) {
                    New-NetQosPolicy -Name "udp" -AppPathNameMatchCondition $fivemSubprocess -DSCPAction 46 -IPProtocolMatchCondition Both -ErrorAction SilentlyContinue
                }
                if ($fivemExe) {
                    New-NetQosPolicy -Name "Ghett" -AppPathNameMatchCondition $fivemExe -DSCPAction 46 -IPProtocolMatchCondition Both -ErrorAction SilentlyContinue
                }

                # ===== citizenFX.ini =====
                $iniPath = Get-ChildItem -Path ([System.IO.DriveInfo]::GetDrives() |
                    Where-Object { $_.DriveType -eq 'Fixed' } |
                    ForEach-Object { "$($_.Name)Users\$env:USERNAME\AppData\Local\FiveM\FiveM.app\citizenFX.ini" }) `
                    -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

                if ($iniPath) {
                    $iniContent = @"
PoolSizesIncrease={"CMoveObject":600,"CWeaponComponentInfo":2048,"Object":2000,"TxdStore":26000}
ReplaceExecutable=1
DisableNvThreadedOptimization=1
DisableHyperThreading=0
UseDirectInput=1
DisableNagleAlgorithm=1
HighPriority=1
[Game]
DisableLauncher=true
[Renderer]
DisableShadowOptimizations=false
EnablePresentationOptimizations=true
ForceRenderAheadLimit=1
DisableNvLowLatency=false
SwapChainUseWaitableSwapChain=true
DisableHyperthreading=1
cl_forceStreamingLegacy=false
DisableMulticore=0
enable_cloth=1
SafeMode=1
NumWorkerThreads=1
disable_vsync=0
force_enable_lod_streaming=0
disable_raw_input=0
disable_windowed_resize_borders=0
disable_ambient_occlusion=0
disable_fog=0
maxStreamingRequests=200
NV_disableShaderDiskCache=false
[Streaming]
MaxStreamingRequests=50
MaxStreamingMemory=2000
StreamerMode=0
"@
                    Set-Content -Path $iniPath -Value $iniContent -Force
                }

                # ===== FiveM Shortcut =====
                if ($fivemExe) {
                    $WScriptShell = New-Object -ComObject WScript.Shell
                    $shortcut = $WScriptShell.CreateShortcut("$env:USERPROFILE\Desktop\FiveM.lnk")
                    $shortcut.TargetPath = $fivemExe
                    $shortcut.Arguments = "-nopickup -nomouselook -frameQueueLimit 1 -disableHyperthreading"
                    $shortcut.Save()
                }

                # ===== TCP Commands =====
                $tcpCmds = @(
                    "netsh int tcp set global rss=enabled",
                    "netsh int tcp set global dca=enabled",
                    "netsh int tcp set global netdma=enabled",
                    "netsh int tcp set global chimney=disabled",
                    "netsh int tcp set global rsc=disabled",
                    "netsh int tcp set global ecncapability=disabled",
                    "netsh int tcp set global timestamps=disabled",
                    "netsh int tcp set global nonsackrttresiliency=disabled",
                    "netsh int tcp set global autotuninglevel=disabled",
                    "netsh int tcp set global fastopen=enabled",
                    "netsh int tcp set global fastopenfallback=enabled",
                    "netsh int tcp set global maxsynretransmissions=2",
                    "netsh int tcp set global initialrto=2000",
                    "netsh int tcp set global mincto=0",
                    "netsh int tcp set global congestionprovider=ctcp",
                    "netsh int tcp set supplemental congestionprovider=ctcp",
                    "netsh int tcp set heuristics disabled",
                    "netsh int ipv4 set glob defaultcurhoplimit=64",
                    "netsh int ipv6 set glob defaultcurhoplimit=64",
                    "netsh int ip set global taskoffload=enabled",
                    "netsh int ip set global multicastforwarding=disabled",
                    "netsh int ip set global reassemblylimit=0",
                    "netsh int udp set global uro=disabled",
                    "netsh int tcp set global memoryprofile=normal",
                    "netsh int ipv6 set global randomizeidentifiers=disabled",
                    "netsh int ipv6 set privacy state=disabled",
                    "bcdedit /set useplatformtick yes",
                    "bcdedit /set disabledynamictick yes"
                )
                foreach ($cmd in $tcpCmds) {
                    try { Invoke-Expression "$cmd 2>&1" | Out-Null } catch {}
                }

                # ===== Registry Interfaces =====
                $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
                $ifVals = [ordered]@{
                    "TcpWindowSize"=65535; "GlobalMaxTcpWindowSize"=65535; "TcpAckFrequency"=1
                    "TcpDelAckTicks"=0; "TCPNoDelay"=1; "TcpMaxDataRetransmissions"=3
                    "TCPTimedWaitDelay"=30; "TCPInitialRtt"=300; "TcpMaxDupAcks"=2
                    "Tcp1323Opts"=1; "SackOpts"=1; "KeepAliveTime"=30000
                    "KeepAliveInterval"=1000; "DefaultTTL"=64; "EnablePMTUBHDetect"=0
                    "EnablePMTUDiscovery"=1; "DisableTaskOffload"=0; "IRPStackSize"=32
                    "MaxUserPort"=65534; "MaxFreeTcbs"=65536; "DisableRss"=0
                    "DisableTcpChimneyOffload"=1; "EnableICMPRedirect"=0; "SynAttackProtect"=0
                }
                foreach ($kv in $ifVals.GetEnumerator()) {
                    Set-ItemProperty -Path $ifPath -Name $kv.Key -Value $kv.Value -Type DWord -Force -ErrorAction SilentlyContinue
                }

                # ===== Registry Parameters =====
                $pPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
                $pVals = [ordered]@{
                    "TcpAckFrequency"=1; "TcpDelAckTicks"=0; "TCPNoDelay"=1
                    "TcpWindowSize"=65535; "GlobalMaxTcpWindowSize"=65535; "SackOpts"=1
                    "Tcp1323Opts"=1; "TcpMaxDataRetransmissions"=3; "TCPTimedWaitDelay"=30
                    "IRPStackSize"=32; "DefaultTTL"=64; "KeepAliveTime"=30000
                    "KeepAliveInterval"=1000; "EnablePMTUBHDetect"=0; "EnablePMTUDiscovery"=1
                    "DisableTaskOffload"=0; "MaxUserPort"=65534; "MaxFreeTcbs"=65536
                    "SynAttackProtect"=0; "EnableICMPRedirect"=0
                }
                foreach ($kv in $pVals.GetEnumerator()) {
                    Set-ItemProperty -Path $pPath -Name $kv.Key -Value $kv.Value -Type DWord -Force -ErrorAction SilentlyContinue
                }

                # ===== GPolicy / QoS / Bandwidth =====
                $pschedPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
                if (!(Test-Path $pschedPath)) { New-Item -Path $pschedPath -Force | Out-Null }
                Set-ItemProperty -Path $pschedPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force
                $multPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Multimedia"
                if (!(Test-Path $multPath)) { New-Item -Path $multPath -Force | Out-Null }
                Set-ItemProperty -Path $multPath -Name "SystemResponsiveness" -Value 0 -Type DWord -Force

                # ===== DSCP Registry FiveMLag =====
                $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\FiveMLag"
                if (!(Test-Path $qosPath)) { New-Item -Path $qosPath -Force | Out-Null }
                Set-ItemProperty -Path $qosPath -Name "Version" -Value "1.0" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Application Name" -Value "FiveM_GTAProcess.exe" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Protocol" -Value "*" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Local Port" -Value "*" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Local IP" -Value "*" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Local IP Prefix Length" -Value "*" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Remote Port" -Value "*" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Remote IP" -Value "*" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Remote IP Prefix Length" -Value "*" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "DSCP Value" -Value "46" -Type String -Force
                Set-ItemProperty -Path $qosPath -Name "Throttle Rate" -Value "1" -Type String -Force

                # ===== Display Latency =====
                $gdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
                if (!(Test-Path $gdPath)) { New-Item -Path $gdPath -Force | Out-Null }
                Set-ItemProperty -Path $gdPath -Name "HwSchMode" -Value 2 -Type DWord -Force
                Set-ItemProperty -Path $gdPath -Name "EnablePreemption" -Value 1 -Type DWord -Force

                $gcPath = "HKCU:\System\GameConfigStore"
                if (!(Test-Path $gcPath)) { New-Item -Path $gcPath -Force | Out-Null }
                Set-ItemProperty -Path $gcPath -Name "GameDVR_FSEBehavior" -Value 2 -Type DWord -Force
                Set-ItemProperty -Path $gcPath -Name "GameDVR_DXGIHonorFSEWindowFocused" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $gcPath -Name "GameDVR_EFSEBehaviorMode" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path $gcPath -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path $gcPath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord -Force

                $desktopPath = "HKCU:\Control Panel\Desktop"
                Set-ItemProperty -Path $desktopPath -Name "ScreenSaveActive" -Value "0" -Type String -Force
                Set-ItemProperty -Path $desktopPath -Name "CursorBlinkRate" -Value "-1" -Type String -Force
                Set-ItemProperty -Path $desktopPath -Name "MenuShowDelay" -Value "0" -Type String -Force
                Set-ItemProperty -Path $desktopPath -Name "HungAppTimeout" -Value "4000" -Type String -Force
                Set-ItemProperty -Path $desktopPath -Name "WaitToKillAppTimeout" -Value "2000" -Type String -Force
                Set-ItemProperty -Path $desktopPath -Name "LowLevelHooksTimeout" -Value "1000" -Type String -Force

                # ===== Game Tasks Priority =====
                $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
                Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
                Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness" -Value 0 -Type DWord -Force

                $gamePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
                if (!(Test-Path $gamePath)) { New-Item -Path $gamePath -Force | Out-Null }
                Set-ItemProperty -Path $gamePath -Name "GPU Priority" -Value 10 -Type DWord -Force
                Set-ItemProperty -Path $gamePath -Name "Priority" -Value 8 -Type DWord -Force
                Set-ItemProperty -Path $gamePath -Name "Scheduling Category" -Value "High" -Type String -Force
                Set-ItemProperty -Path $gamePath -Name "SFIO Priority" -Value "High" -Type String -Force
                Set-ItemProperty -Path $gamePath -Name "Affinity" -Value 0xff -Type DWord -Force
                Set-ItemProperty -Path $gamePath -Name "Background Only" -Value "False" -Type String -Force
                Set-ItemProperty -Path $gamePath -Name "Clock Rate" -Value 10000 -Type DWord -Force

                # ===== FiveM Process Priority =====
                foreach ($exe in @("GTA5.exe", "FiveM.exe")) {
                    $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exe\PerfOptions"
                    if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                    Set-ItemProperty -Path $p -Name "CpuPriorityClass" -Value 6 -Type DWord -Force
                    Set-ItemProperty -Path $p -Name "IoPriority" -Value 3 -Type DWord -Force
                }
                foreach ($exe in @("GTAVLauncher.exe", "subprocess.exe")) {
                    $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exe\PerfOptions"
                    if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                    Set-ItemProperty -Path $p -Name "CpuPriorityClass" -Value 5 -Type DWord -Force
                    Set-ItemProperty -Path $p -Name "IoPriority" -Value 1 -Type DWord -Force
                }

                # ===== Power / Core Parking =====
                $ptPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
                if (!(Test-Path $ptPath)) { New-Item -Path $ptPath -Force | Out-Null }
                Set-ItemProperty -Path $ptPath -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force

                $cpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
                Set-ItemProperty -Path $cpPath -Name "Attributes" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $cpPath -Name "ValueMax" -Value 100 -Type DWord -Force -ErrorAction SilentlyContinue

                # ===== Priority Control =====
                $pcPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
                Set-ItemProperty -Path $pcPath -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force
                Set-ItemProperty -Path $pcPath -Name "IRQ8Priority" -Value 1 -Type DWord -Force

                # ===== Mouse =====
                $mousePath = "HKCU:\Control Panel\Mouse"
                Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value "0" -Type String -Force
                Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0" -Type String -Force
                Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0" -Type String -Force
                Set-ItemProperty -Path $mousePath -Name "MouseSensitivity" -Value "10" -Type String -Force
                Set-ItemProperty -Path $mousePath -Name "MouseHoverTime" -Value "30" -Type String -Force
                Set-ItemProperty -Path $mousePath -Name "DoubleClickSpeed" -Value "200" -Type String -Force
                Set-ItemProperty -Path $mousePath -Name "MouseTrails" -Value "0" -Type String -Force
                $smoothX = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc0,0xcc,0x0c,0x00,0x00,0x00,0x00,0x00,0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
                $smoothY = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xa8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xe0,0x00,0x00,0x00,0x00,0x00)
                Set-ItemProperty -Path $mousePath -Name "SmoothMouseXCurve" -Value $smoothX -Type Binary -Force
                Set-ItemProperty -Path $mousePath -Name "SmoothMouseYCurve" -Value $smoothY -Type Binary -Force

                # ===== Keyboard =====
                $kbPath = "HKCU:\Control Panel\Keyboard"
                Set-ItemProperty -Path $kbPath -Name "KeyboardDelay" -Value "0" -Type String -Force
                Set-ItemProperty -Path $kbPath -Name "KeyboardSpeed" -Value "31" -Type String -Force

                # ===== Input Buffer =====
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Value 0x10 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Value 0x10 -Type DWord -Force -ErrorAction SilentlyContinue

                # ===== FilterKeys =====
                $filterKeysPath = "HKCU:\Control Panel\Accessibility\Keyboard Response"
                if (!(Test-Path $filterKeysPath)) { New-Item -Path $filterKeysPath -Force | Out-Null }
                Set-ItemProperty -Path $filterKeysPath -Name "Flags" -Value "126" -Type String -Force
                Set-ItemProperty -Path $filterKeysPath -Name "DelayBeforeAcceptance" -Value "0" -Type String -Force
                Set-ItemProperty -Path $filterKeysPath -Name "AutoRepeatDelay" -Value "150" -Type String -Force
                Set-ItemProperty -Path $filterKeysPath -Name "AutoRepeatRate" -Value "25" -Type String -Force
                Set-ItemProperty -Path $filterKeysPath -Name "BounceTime" -Value "0" -Type String -Force

                $stickyPath = "HKCU:\Control Panel\Accessibility\StickyKeys"
                if (!(Test-Path $stickyPath)) { New-Item -Path $stickyPath -Force | Out-Null }
                Set-ItemProperty -Path $stickyPath -Name "Flags" -Value "506" -Type String -Force

                $togglePath = "HKCU:\Control Panel\Accessibility\ToggleKeys"
                if (!(Test-Path $togglePath)) { New-Item -Path $togglePath -Force | Out-Null }
                Set-ItemProperty -Path $togglePath -Name "Flags" -Value "58" -Type String -Force

                # ===== Network Adapter =====
                $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
                if ($adapter) {
                    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
                    $adapterKey = Get-ChildItem $regPath | Where-Object {
                        (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).NetCfgInstanceId -eq $adapter.InterfaceGuid
                    }
                    if ($adapterKey) {
                        Set-ItemProperty -Path $adapterKey.PSPath -Name "*JumboPacket" -Value "9014" -Type String -Force -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $adapterKey.PSPath -Name "*ReceiveBuffers" -Value "32" -Type String -Force -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $adapterKey.PSPath -Name "*TransmitBuffers" -Value "64" -Type String -Force -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $adapterKey.PSPath -Name "*WakeOnMagicPacket" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $adapterKey.PSPath -Name "*WakeOnPattern" -Value "0" -Type String -Force -ErrorAction SilentlyContinue
                    }
                }

                # ===== Memory Management =====
                $mmgPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                Set-ItemProperty -Path $mmgPath -Name "LargeSystemCache" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path $mmgPath -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force

                # ===== Disable GameDVR / GameBar =====
                $gdvrPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
                if (!(Test-Path $gdvrPath)) { New-Item -Path $gdvrPath -Force | Out-Null }
                Set-ItemProperty -Path $gdvrPath -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force

                $gbPath = "HKCU:\Software\Microsoft\GameBar"
                if (!(Test-Path $gbPath)) { New-Item -Path $gbPath -Force | Out-Null }
                Set-ItemProperty -Path $gbPath -Name "GamePanelStartupNotificationOff" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $gbPath -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $gbPath -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force

                # ===== Disable Services =====
                $services = @("DiagTrack", "SysMain", "WSearch", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "XboxGipSvc")
                foreach ($svc in $services) {
                    try {
                        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
                    } catch {}
                }

                # ===== Visual Effects =====
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue

                # ===== Disable Windows Defender Realtime =====
                $wdPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
                if (!(Test-Path $wdPath)) { New-Item -Path $wdPath -Force | Out-Null }
                Set-ItemProperty -Path $wdPath -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force

                # ===== Direct3D =====
                $d3dPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Direct3D"
                if (!(Test-Path $d3dPath)) { New-Item -Path $d3dPath -Force | Out-Null }
                Set-ItemProperty -Path $d3dPath -Name "MaxPreRenderedFrames" -Value 0 -Type DWord -Force

                # ===== Explorer =====
                $serializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
                if (!(Test-Path $serializePath)) { New-Item -Path $serializePath -Force | Out-Null }
                Set-ItemProperty -Path $serializePath -Name "StartupDelayInMSec" -Value 0 -Type DWord -Force

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

                # ===== Restore Point =====
                $restore = Get-ComputerRestorePoint | Where-Object { $_.Description -eq "Cheetos Backup" } | Select-Object -Last 1
                if ($restore) {
                    Restore-Computer -RestorePoint $restore.SequenceNumber -Confirm:$false
                }

                # ===== Remove QoS Policy =====
                Remove-NetQosPolicy -Name "udp" -Confirm:$false -ErrorAction SilentlyContinue
                Remove-NetQosPolicy -Name "aspas" -Confirm:$false -ErrorAction SilentlyContinue

                # ===== Remove DSCP Registry =====
                Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\FiveMLag" -Recurse -Force -ErrorAction SilentlyContinue

                # ===== Remove Bandwidth Limit =====
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Multimedia" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue

                # ===== Re-enable Services =====
                $services = @("DiagTrack", "SysMain", "WSearch", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "XboxGipSvc")
                foreach ($svc in $services) {
                    try {
                        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
                        Start-Service -Name $svc -ErrorAction SilentlyContinue
                    } catch {}
                }

                # ===== Re-enable Windows Defender =====
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue

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
            Start-Sleep -Seconds 1
            exit
        }
    }

} while ($choice.ToUpper() -ne "Q")
