param([switch]$NoMenu, [switch]$AutoGame)
# ============================================================
#  GreenTweak v2 - Gaming-Tweaks fuer Windows 10/11
#  Alle Aenderungen werden vorher gesichert und sind per
#  Menuepunkt [3] komplett rueckgaengig zu machen.
# ============================================================

# --- Als Administrator neu starten, falls noetig ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if (-not $PSCommandPath) { Write-Host "Bitte als Administrator starten." -ForegroundColor Red; Read-Host; exit }
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$VerFile = Join-Path $PSScriptRoot "version.txt"
$Version = if (Test-Path $VerFile) { (Get-Content $VerFile -Raw).Trim() } else { "2.0" }
if (-not $NoMenu) {
    $Host.UI.RawUI.WindowTitle = "GreenTweak v$Version"
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "Green"
    Clear-Host
}
$BackupDir  = Join-Path $env:ProgramData "GreenTweak"
$BackupFile = Join-Path $BackupDir "backup.json"
$LogFile    = Join-Path $BackupDir "log.txt"
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
$OldBackup = Join-Path $env:ProgramData "JanTweak\backup.json"
if ((Test-Path $OldBackup) -and -not (Test-Path $BackupFile)) { Move-Item $OldBackup $BackupFile }

function Log($text, $color = "DarkGreen") {
    Write-Host $text -ForegroundColor $color
    Add-Content -Path $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $text)
}

# ------------------------------------------------------------
#  Registry-Tweaks (Gruppe: Basis = in jedem Profil, Gaming = ab Profil Gaming)
# ------------------------------------------------------------
$MM = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$Tweaks = @(
    # --- Basis ---
    @{ Group="Basis";  Path="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"; Value=0; Type="DWord"; Info="Game DVR aus" },
    @{ Group="Basis";  Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"; Name="AppCaptureEnabled"; Value=0; Type="DWord"; Info="Hintergrundaufnahme aus" },
    @{ Group="Basis";  Path="HKCU:\Software\Microsoft\GameBar"; Name="AutoGameModeEnabled"; Value=1; Type="DWord"; Info="Spielmodus an" },
    @{ Group="Basis";  Path="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name="HwSchMode"; Value=2; Type="DWord"; Info="GPU-Planung an" },
    # --- Gaming ---
    @{ Group="Gaming"; Path=$MM; Name="SystemResponsiveness"; Value=10; Type="DWord"; Info="CPU-Prioritaet fuer Spiele" },
    @{ Group="Gaming"; Path=$MM; Name="NetworkThrottlingIndex"; Value=0xffffffff; Type="DWord"; Info="Netzwerk-Drosselung aus" },
    @{ Group="Gaming"; Path="$MM\Tasks\Games"; Name="GPU Priority"; Value=8; Type="DWord"; Info="GPU-Prioritaet Spiele" },
    @{ Group="Gaming"; Path="$MM\Tasks\Games"; Name="Priority"; Value=6; Type="DWord"; Info="Prioritaet Spiele" },
    @{ Group="Gaming"; Path="$MM\Tasks\Games"; Name="Scheduling Category"; Value="High"; Type="String"; Info="Planung Spiele: Hoch" },
    @{ Group="Gaming"; Path="$MM\Tasks\Games"; Name="SFIO Priority"; Value="High"; Type="String"; Info="Datei-I/O Spiele: Hoch" },
    @{ Group="Gaming"; Path="HKCU:\Control Panel\Mouse"; Name="MouseSpeed"; Value="0"; Type="String"; Info="Mausbeschleunigung aus" },
    @{ Group="Gaming"; Path="HKCU:\Control Panel\Mouse"; Name="MouseThreshold1"; Value="0"; Type="String"; Info="Maus-Schwelle 1" },
    @{ Group="Gaming"; Path="HKCU:\Control Panel\Mouse"; Name="MouseThreshold2"; Value="0"; Type="String"; Info="Maus-Schwelle 2" }
)

# FiveM/GTA beim Start automatisch mit hoher CPU-Prioritaet (Windows "Image File Execution Options")
$IFEO = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
function Get-GameExeNames {
    $names = @("GTA5.exe", "GTA5_Enhanced.exe", "FiveM_GTAProcess.exe",
               "FiveM_b2802_GTAProcess.exe", "FiveM_b2944_GTAProcess.exe", "FiveM_b3095_GTAProcess.exe",
               "FiveM_b3258_GTAProcess.exe", "FiveM_b3323_GTAProcess.exe", "FiveM_b3407_GTAProcess.exe")
    # tatsaechlich vorhandene FiveM-Prozessnamen dazunehmen
    $sub = Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\data\cache\subprocess"
    if (Test-Path $sub) {
        $names += Get-ChildItem $sub -Filter "*GTAProcess.exe" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
    }
    return $names | Sort-Object -Unique
}
function Get-PrioTweaks {
    foreach ($exe in Get-GameExeNames) {
        @{ Group="Gaming"; Path="$IFEO\$exe\PerfOptions"; Name="CpuPriorityClass"; Value=3; Type="DWord"; Info="Hohe Prioritaet: $exe" }
    }
}

# Windows-Grafikeinstellung "Hoechstleistung" (dedizierte Grafikkarte) fuer GTA/FiveM
$GpuPrefKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
function Get-GameExePaths {
    $paths = @()
    $fivem = Join-Path $env:LOCALAPPDATA "FiveM"
    if (Test-Path "$fivem\FiveM.exe") { $paths += "$fivem\FiveM.exe" }
    $sub = Join-Path $fivem "FiveM.app\data\cache\subprocess"
    if (Test-Path $sub) { $paths += Get-ChildItem $sub -Filter "*GTAProcess.exe" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName } }
    foreach ($k in @("HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V", "HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\GTAV")) {
        $dir = (Get-ItemProperty $k -ErrorAction SilentlyContinue).InstallFolder
        if ($dir -and (Test-Path "$dir\GTA5.exe")) { $paths += "$dir\GTA5.exe" }
    }
    foreach ($d in @("C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto V", "C:\Program Files\Rockstar Games\Grand Theft Auto V", "C:\Program Files\Epic Games\GTAV")) {
        if (Test-Path "$d\GTA5.exe") { $paths += "$d\GTA5.exe" }
    }
    return $paths | Sort-Object -Unique
}
function Get-GpuPrefTweaks {
    foreach ($exe in Get-GameExePaths) {
        @{ Group="Gaming"; Path=$GpuPrefKey; Name=$exe; Value="GpuPreference=2;"; Type="String"; Info="Grafikkarte Hoechstleistung: " + (Split-Path $exe -Leaf) }
    }
}

$UltimateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$HighPerfGuid = "8c5e7fda-e8bf-4a96-9a85-cf4e4d2bcfb5"

# ------------------------------------------------------------
#  Hilfsfunktionen
# ------------------------------------------------------------
function Get-RegState($path, $name) {
    if (Test-Path $path) {
        $item = Get-Item -Path $path
        if ($item.GetValueNames() -contains $name) {
            return [ordered]@{
                Path   = $path
                Name   = $name
                Exists = $true
                Value  = $item.GetValue($name, $null, "DoNotExpandEnvironmentNames")
                Kind   = $item.GetValueKind($name).ToString()
            }
        }
    }
    return [ordered]@{ Path = $path; Name = $name; Exists = $false; Value = $null; Kind = $null }
}

function Set-Reg($path, $name, $value, $type) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null
}

function Get-GuidFromText($text) {
    $m = [regex]::Match(($text -join " "), "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
    if ($m.Success) { return $m.Value } else { return $null }
}

function Ok($t)   { Log ("  [OK] " + $t) Green }
function Warn($t) { Log ("  [!]  " + $t) Yellow }
function Bad($t)  { Log ("  [X]  " + $t) Red }

# ------------------------------------------------------------
#  [1] Profil anwenden
# ------------------------------------------------------------
function Select-Profile {
    Write-Host ""
    Write-Host -ForegroundColor Green "  Welches Profil?"
    Write-Host -ForegroundColor Green "  [1] Leicht   - Energieplan, Spielmodus, Aufraeumen"
    Write-Host -ForegroundColor Green "  [2] Gaming   - Leicht + Spiele-Prioritaet, FiveM/GTA-Prioritaet, Maus 1:1"
    Write-Host -ForegroundColor Green "  [3] Max FPS  - Gaming + GTA/FiveM-Grafik auf FPS"
    Write-Host -ForegroundColor Green "  [0] Abbrechen"
    switch (Read-Host "  Profil") {
        "1" { return "Leicht" }
        "2" { return "Gaming" }
        "3" { return "Max FPS" }
        default { return $null }
    }
}

function Invoke-ApplyProfile($Preset) {
    if (Test-Path $BackupFile) {
        Warn "Es sind bereits Tweaks aktiv (Sicherung vorhanden)."
        Warn "Bitte zuerst [3] Rueckgaengig ausfuehren, wenn du ein anderes Profil willst."
        return
    }
    $prof = if ($Preset) { $Preset } else { Select-Profile }
    if (-not $prof) { return }
    Log "`n######## Profil: $prof ########" Green

    $list = @($Tweaks | Where-Object { $_.Group -eq "Basis" })
    if ($prof -ne "Leicht") { $list += @($Tweaks | Where-Object { $_.Group -eq "Gaming" }); $list += @(Get-PrioTweaks); $list += @(Get-GpuPrefTweaks) }

    New-GTRestorePoint "Vor GreenTweak"

    # Sicherung anlegen
    $backup = [ordered]@{
        Created       = (Get-Date).ToString("s")
        Version       = $Version
        Profile       = $prof
        Registry      = @()
        PrevPowerPlan = $null
        NewPowerPlan  = $null
    }
    foreach ($t in $list) { $backup.Registry += (Get-RegState $t.Path $t.Name) }

    # Energieplan
    Log "`n== Energieplan ==" Green
    $backup.PrevPowerPlan = Get-GuidFromText (powercfg /getactivescheme)
    $newGuid = Get-GuidFromText (powercfg -duplicatescheme $UltimateGuid 2>$null)
    if (-not $newGuid) { $newGuid = Get-GuidFromText (powercfg -duplicatescheme $HighPerfGuid 2>$null) }
    if ($newGuid) {
        powercfg -changename $newGuid "GreenTweak Gaming" "Maximale Leistung, keine Kernparkierung" | Out-Null
        powercfg -setacvalueindex $newGuid SUB_PROCESSOR CPMINCORES 100 2>$null | Out-Null
        powercfg -setacvalueindex $newGuid SUB_PROCESSOR PROCTHROTTLEMIN 100 2>$null | Out-Null
        powercfg -setacvalueindex $newGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null | Out-Null
        powercfg -setactive $newGuid | Out-Null
        $backup.NewPowerPlan = $newGuid
        Ok "Energieplan 'GreenTweak Gaming' aktiv (Kernparkierung aus, CPU min. 100 %)."
    } else {
        Warn "Energieplan konnte nicht erstellt werden - wird uebersprungen."
    }

    # Sicherung speichern, BEVOR die Registry geaendert wird
    $backup | ConvertTo-Json -Depth 5 | Set-Content -Path $BackupFile -Encoding UTF8
    Log "  Sicherung gespeichert: $BackupFile" DarkGreen

    Log "`n== Windows-Tweaks ==" Green
    foreach ($t in $list) {
        try { Set-Reg $t.Path $t.Name $t.Value $t.Type; Ok $t.Info }
        catch { Bad ($t.Info + ": " + $_.Exception.Message) }
    }

    Invoke-Cleanup
    if ($prof -eq "Max FPS") { Invoke-GtaLow }

    Log "`nFertig! Bitte den PC neu starten, damit alles greift." Green
}

# ------------------------------------------------------------
#  [2] Aufraeumen (Temp + FiveM-Cache)
# ------------------------------------------------------------
function Remove-FolderContent($folder, $label) {
    if (-not (Test-Path $folder)) { Log "  $label - nicht gefunden, uebersprungen." DarkGreen; return }
    $before = (Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem $folder -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $after = (Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $freed = [math]::Round((([double]$before) - ([double]$after)) / 1MB, 1)
    Ok "$label - $freed MB freigegeben."
}

function Invoke-Cleanup {
    Log "`n== Aufraeumen ==" Green
    Remove-FolderContent $env:TEMP "Benutzer-Temp"
    Remove-FolderContent "$env:SystemRoot\Temp" "Windows-Temp"
    $fivemCache = Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\data\cache"
    if (Get-Process -Name "FiveM*" -ErrorAction SilentlyContinue) {
        Warn "FiveM-Cache - FiveM laeuft gerade, bitte erst schliessen. Uebersprungen."
    } else {
        Remove-FolderContent $fivemCache "FiveM-Cache"
    }
}

# ------------------------------------------------------------
#  [3] Alles rueckgaengig
# ------------------------------------------------------------
function Invoke-Undo {
    if (Test-Path $TurboFile) { Invoke-TurboOff }
    if (Test-AutoGame) { Disable-AutoGame }
    if (-not (Test-Path $BackupFile)) { Warn "Keine Sicherung gefunden - es gibt nichts rueckgaengig zu machen."; return }
    $backup = Get-Content $BackupFile -Raw | ConvertFrom-Json

    Log "`n== Registry wiederherstellen ==" Green
    foreach ($r in $backup.Registry) {
        try {
            if ($r.Exists) {
                Set-Reg $r.Path $r.Name $r.Value $r.Kind
            } elseif (Test-Path $r.Path) {
                Remove-ItemProperty -Path $r.Path -Name $r.Name -ErrorAction SilentlyContinue
                # leere PerfOptions-Schluessel von GreenTweak wieder entfernen
                if ($r.Path -like "*Image File Execution Options*\PerfOptions") {
                    $k = Get-Item $r.Path -ErrorAction SilentlyContinue
                    if ($k -and $k.ValueCount -eq 0 -and $k.SubKeyCount -eq 0) {
                        Remove-Item $r.Path -ErrorAction SilentlyContinue
                        $parent = Split-Path $r.Path -Parent
                        $p = Get-Item $parent -ErrorAction SilentlyContinue
                        if ($p -and $p.ValueCount -eq 0 -and $p.SubKeyCount -eq 0) { Remove-Item $parent -ErrorAction SilentlyContinue }
                    }
                }
            }
            Ok $r.Name
        } catch {
            Bad ($r.Name + ": " + $_.Exception.Message)
        }
    }

    Log "`n== Energieplan wiederherstellen ==" Green
    if ($backup.PrevPowerPlan) { powercfg -setactive $backup.PrevPowerPlan | Out-Null; Ok "Vorheriger Energieplan wieder aktiv." }
    if ($backup.NewPowerPlan)  { powercfg -delete $backup.NewPowerPlan 2>$null | Out-Null; Ok "Plan 'GreenTweak Gaming' geloescht." }

    Rename-Item $BackupFile ("backup_rueckgaengig_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")

    if ($backup.Profile -eq "Max FPS") { Invoke-GtaRestore }
    Log "`nAlles rueckgaengig gemacht. Bitte den PC neu starten." Green
}

# ------------------------------------------------------------
#  [4] Status
# ------------------------------------------------------------
function Show-Status {
    Log "`n== Status ==" Green
    if (Test-Path $BackupFile) {
        $b = Get-Content $BackupFile -Raw | ConvertFrom-Json
        $p = if ($b.Profile) { $b.Profile } else { "Gaming (v1)" }
        Ok "Tweaks AKTIV - Profil: $p (seit $($b.Created))"
    } else { Warn "Tweaks nicht aktiv" }
    Log ("  Energieplan: " + ((powercfg /getactivescheme) -join " ")) DarkGreen
    foreach ($t in @($Tweaks) + @(Get-PrioTweaks) + @(Get-GpuPrefTweaks)) {
        $s = Get-RegState $t.Path $t.Name
        if ($s.Exists) { Log ("  {0,-45} {1}" -f $t.Info, $s.Value) DarkGreen }
    }
}

# ------------------------------------------------------------
#  [5]/[6] GTA V + FiveM: Grafik auf FPS
# ------------------------------------------------------------
$Docs = [Environment]::GetFolderPath("MyDocuments")
$GtaFiles = @(
    (Join-Path $Docs "Rockstar Games\GTA V\settings.xml"),
    (Join-Path $Docs "Rockstar Games\GTAV Enhanced\settings.xml"),
    (Join-Path $env:APPDATA "CitizenFX\gta5_settings.xml")
)
# 0 = so niedrig wie moeglich (teils niedriger als im Spielmenue)
$GtaLow = [ordered]@{
    ShadowQuality          = "0"
    Shadow_SoftShadows     = "0"
    Shadow_ParticleShadows = "false"
    Shadow_LongShadows     = "false"
    ParticleQuality        = "0"
    GrassQuality           = "0"
    ReflectionQuality      = "0"
    ReflectionMSAA         = "0"
    PostFX                 = "0"
    SSAO                   = "0"
    DoF                    = "false"
    MotionBlurStrength     = "0.000000"
}

function Test-GtaRunning {
    if (Get-Process -Name "GTA5", "GTA5_Enhanced", "PlayGTAV", "FiveM*" -ErrorAction SilentlyContinue) {
        Warn "GTA oder FiveM laeuft noch - bitte erst komplett schliessen."
        return $true
    }
    return $false
}

function Invoke-GtaLow {
    Log "`n== GTA / FiveM: Grafik auf FPS ==" Green
    Log "  (Schatten, Partikel, Gras, Spiegelungen, Effekte, Unschaerfe)" DarkGreen
    if (Test-GtaRunning) { return }
    $found = $false
    foreach ($f in $GtaFiles) {
        if (-not (Test-Path $f)) { continue }
        $found = $true
        try {
            $bak = "$f.greentweak.bak"
            if (-not (Test-Path $bak)) { Copy-Item $f $bak -Force }
            $xml = New-Object System.Xml.XmlDocument
            $xml.PreserveWhitespace = $true
            $xml.Load($f)
            $g = $xml.SelectSingleNode("//graphics")
            if (-not $g) { Warn "Kein Grafik-Bereich in $f - uebersprungen."; continue }
            foreach ($k in $GtaLow.Keys) {
                $n = $g.SelectSingleNode($k)
                if (-not $n) { $n = $xml.CreateElement($k); [void]$g.AppendChild($n) }
                $n.SetAttribute("value", $GtaLow[$k])
            }
            $xml.Save($f)
            Ok $f
        } catch {
            Bad ($f + ": " + $_.Exception.Message)
        }
    }
    if (-not $found) {
        Warn "Keine GTA/FiveM-Grafikdatei gefunden. Starte GTA/FiveM einmal und versuch es dann nochmal."
    } else {
        Log "  Tipp: Aendere danach im Spiel nichts an der Grafik, sonst ueberschreibt das Spiel die Werte." DarkGreen
    }
}

function Invoke-GtaRestore {
    Log "`n== GTA / FiveM: Grafik zuruecksetzen ==" Green
    if (Test-GtaRunning) { return }
    $found = $false
    foreach ($f in $GtaFiles) {
        $bak = "$f.greentweak.bak"
        if (Test-Path $bak) {
            Copy-Item $bak $f -Force
            Remove-Item $bak -Force
            Ok "wiederhergestellt: $f"
            $found = $true
        }
    }
    if (-not $found) { Warn "Keine Grafik-Sicherung gefunden - nichts zu tun." }
}

# ------------------------------------------------------------
#  [7] Systemcheck
# ------------------------------------------------------------
function Invoke-SystemCheck {
    Log "`n######## Systemcheck ########" Green
    $tips = @()

    # System
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Log ("  System: " + $os.Caption + " | CPU: " + $cpu.Name.Trim()) DarkGreen

    # Arbeitsspeicher + XMP
    Log "`n== Arbeitsspeicher ==" Green
    $mem = @(Get-CimInstance Win32_PhysicalMemory)
    $totalGB = [math]::Round(($mem | Measure-Object Capacity -Sum).Sum / 1GB)
    $type = switch ($mem[0].SMBIOSMemoryType) { 26 { "DDR4" } 34 { "DDR5" } default { "RAM" } }
    $cur = ($mem | Measure-Object ConfiguredClockSpeed -Minimum).Minimum
    $max = ($mem | Measure-Object Speed -Maximum).Maximum
    Log ("  {0} GB {1}, {2} Riegel, laeuft mit {3} MT/s" -f $totalGB, $type, $mem.Count, $cur) DarkGreen
    if ($totalGB -lt 16) { Warn "Weniger als 16 GB RAM - fuer FiveM-Server mit vielen Mods knapp."; $tips += "Mehr RAM (16-32 GB) hilft bei FiveM spuerbar." }
    else { Ok "RAM-Menge reicht." }
    $xmpOff = ($type -eq "DDR4" -and $cur -le 2666) -or ($type -eq "DDR5" -and $cur -le 4800)
    if ($xmpOff) {
        Warn "RAM laeuft nur mit $cur MT/s - XMP/EXPO ist wahrscheinlich AUS."
        $tips += "Im BIOS XMP (Intel) bzw. EXPO (AMD) aktivieren - oft +10-20 % FPS in CPU-lastigen Spielen wie FiveM."
    } else { Ok "RAM-Takt sieht gut aus (XMP/EXPO vermutlich an)." }
    if ($mem.Count -eq 1) { Warn "Nur 1 RAM-Riegel - kein Dual-Channel."; $tips += "Zwei gleiche RAM-Riegel (Dual-Channel) bringen deutlich mehr FPS als einer." }

    # Grafikkarte + Treiber
    Log "`n== Grafikkarte ==" Green
    $gpus = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Microsoft|Basic|Virtual|Parsec" }
    foreach ($g in $gpus) {
        $age = if ($g.DriverDate) { [int]((Get-Date) - $g.DriverDate).TotalDays } else { -1 }
        Log ("  {0} - Treiber {1} ({2} Tage alt)" -f $g.Name, $g.DriverVersion, $age) DarkGreen
        if ($age -gt 180) { Warn "Grafiktreiber ist ueber 6 Monate alt."; $tips += "Grafiktreiber updaten (NVIDIA App / AMD Adrenalin)." }
        elseif ($age -ge 0) { Ok "Treiber ist aktuell genug." }
    }
    $hags = Get-RegState "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode"
    if ($hags.Exists -and $hags.Value -eq 2) { Ok "Hardwarebeschleunigte GPU-Planung an." } else { Warn "GPU-Planung aus (wird mit Profil Leicht/Gaming eingeschaltet)." }

    # Energieplan
    Log "`n== Energie ==" Green
    $plan = (powercfg /getactivescheme) -join " "
    if ($plan -match "GreenTweak|Hoechstleistung|H.chstleistung|Ultimative|Ultimate|High performance") { Ok "Energieplan: Leistung" }
    else { Warn "Energieplan ist nicht auf Leistung."; $tips += "GreenTweak-Profil anwenden (setzt den Energieplan auf Leistung)." }

    # Festplatte
    Log "`n== Speicherplatz ==" Green
    $sys = Get-PSDrive -Name ($env:SystemDrive.TrimEnd(':'))
    $freeGB = [math]::Round($sys.Free / 1GB)
    if ($freeGB -lt 20) { Bad "Nur $freeGB GB frei auf $env:SystemDrive - Windows wird langsam!"; $tips += "Mindestens 20-30 GB auf $env:SystemDrive frei machen." }
    elseif ($freeGB -lt 50) { Warn "$freeGB GB frei auf $env:SystemDrive - wird langsam knapp." }
    else { Ok "$freeGB GB frei auf $env:SystemDrive" }

    # Autostart + RAM-Fresser
    Log "`n== Hintergrund ==" Green
    $auto = @(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Count
    if ($auto -gt 8) { Warn "$auto Programme starten mit Windows."; $tips += "Autostart ausmisten: Seite 'Autostart' in GreenTweak." }
    else { Ok "$auto Programme im Autostart." }
    Log "  Groesste RAM-Verbraucher gerade:" DarkGreen
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 | ForEach-Object {
        Log ("    {0,-28} {1,6} MB" -f $_.ProcessName, [math]::Round($_.WorkingSet64 / 1MB)) DarkGreen
    }

    # Zusammenfassung
    Log "`n######## Empfehlungen ########" Green
    if ($tips.Count -eq 0) { Ok "Alles im gruenen Bereich - dein PC ist gut eingestellt!" }
    else { $i = 1; foreach ($t in $tips) { Log ("  $i. " + $t) Yellow; $i++ } }
}

# ------------------------------------------------------------
#  [8]/[9]/[10] Netzwerk
# ------------------------------------------------------------
$NetBackupFile = Join-Path $BackupDir "net_backup.json"
$NetAdvKeywords = @("*EEE", "EEELinkAdvertisement", "AdvancedEEE", "EnableGreenEthernet", "GreenEthernet",
                    "PowerSavingMode", "ULPMode", "*SelectiveSuspend")

function Get-ActiveAdapters {
    $gw = @(Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPv4DefaultGateway } | ForEach-Object { $_.InterfaceIndex })
    Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" -and $gw -contains $_.ifIndex }
}

function Test-IsWifi($a) {
    return ($a.PhysicalMediaType -match "802\.11") -or ($a.InterfaceDescription -match "Wi-?Fi|Wireless|WLAN")
}

function Measure-Ping($target, $count = 30) {
    $p = New-Object System.Net.NetworkInformation.Ping
    $times = @(); $lost = 0
    for ($i = 0; $i -lt $count; $i++) {
        try {
            $r = $p.Send($target, 1000)
            if ($r.Status -eq "Success") { $times += [int]$r.RoundtripTime } else { $lost++ }
        } catch { $lost++ }
        Start-Sleep -Milliseconds 100
    }
    $res = [ordered]@{ Target = $target; Avg = $null; Min = $null; Max = $null; Jitter = $null; Loss = [math]::Round($lost / $count * 100) }
    if ($times.Count -gt 0) {
        $res.Avg = [math]::Round(($times | Measure-Object -Average).Average)
        $res.Min = ($times | Measure-Object -Minimum).Minimum
        $res.Max = ($times | Measure-Object -Maximum).Maximum
        if ($times.Count -gt 1) {
            $diffs = for ($i = 1; $i -lt $times.Count; $i++) { [math]::Abs($times[$i] - $times[$i - 1]) }
            $res.Jitter = [math]::Round(($diffs | Measure-Object -Average).Average, 1)
        } else { $res.Jitter = 0 }
    }
    return $res
}

function Invoke-NetTest {
    Log "`n######## Netzwerk-Test ########" Green
    $tips = @()
    $ads = @(Get-ActiveAdapters)
    if ($ads.Count -eq 0) { Bad "Keine aktive Internetverbindung gefunden."; return }
    foreach ($a in $ads) {
        $wifi = Test-IsWifi $a
        Log ("  Verbindung: {0} - {1} - {2}" -f $a.Name, $(if ($wifi) { "WLAN" } else { "LAN-Kabel" }), $a.LinkSpeed) DarkGreen
        if ($wifi) {
            Warn "Du spielst ueber WLAN."
            $tips += "LAN-Kabel statt WLAN - das bringt mit Abstand am meisten gegen Lags und Ping-Spitzen."
        } else { Ok "LAN-Kabel - beste Voraussetzung." }
    }
    Log "  Messe Ping (30 Pakete je Ziel, dauert ca. 8 Sekunden) ..." DarkGreen
    foreach ($t in @("1.1.1.1", "8.8.8.8")) {
        $m = Measure-Ping $t
        if ($null -eq $m.Avg) { Bad "$t nicht erreichbar."; continue }
        Log ("  {0,-8}  Ping {1} ms (min {2} / max {3})  Jitter {4} ms  Verlust {5} %" -f $t, $m.Avg, $m.Min, $m.Max, $m.Jitter, $m.Loss) DarkGreen
        if ($m.Loss -gt 0)    { Warn "Paketverlust $($m.Loss) % zu $t."; $tips += "Paketverlust: Router neu starten, Kabel pruefen, sonst beim Anbieter melden." }
        if ($m.Jitter -gt 10) { Warn "Hoher Jitter ($($m.Jitter) ms) - der Ping schwankt stark."; $tips += "Starker Jitter kommt oft von WLAN oder Downloads/Streams im Hintergrund." }
        if ($m.Avg -gt 60)    { Warn "Grundping ueber 60 ms."; $tips += "Hoher Grundping liegt meist am Anbieter oder der Leitung, nicht am PC." }
        if ($m.Loss -eq 0 -and $m.Jitter -le 10 -and $m.Avg -le 60) { Ok "Verbindung zu $t ist gut." }
    }
    Log "`n######## Empfehlungen ########" Green
    if ($tips.Count -eq 0) { Ok "Deine Verbindung ist gut. Der Ping im Spiel haengt jetzt vor allem vom Serverstandort ab." }
    else { $i = 1; foreach ($t in ($tips | Select-Object -Unique)) { Log ("  $i. " + $t) Yellow; $i++ } }
}

function Invoke-NetTweaks {
    Log "`n######## Netzwerk optimieren ########" Green
    if (Test-Path $NetBackupFile) { Warn "Netzwerk-Tweaks sind schon aktiv. Zum Neu-Anwenden erst zuruecksetzen."; return }
    $ads = @(Get-ActiveAdapters)
    if ($ads.Count -eq 0) { Bad "Keine aktive Internetverbindung gefunden."; return }

    $bk = [ordered]@{ Created = (Get-Date).ToString("s"); Registry = @(); AdvProps = @(); Power = @(); Adapters = @() }
    $regs = @()
    foreach ($a in $ads) {
        $bk.Adapters += $a.Name
        $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($a.InterfaceGuid)"
        $regs += @{ Path = $p; Name = "TcpAckFrequency"; Value = 1; Type = "DWord"; Info = "Sofortige Bestaetigung (TcpAckFrequency) - $($a.Name)" }
        $regs += @{ Path = $p; Name = "TCPNoDelay";      Value = 1; Type = "DWord"; Info = "Nagle aus (TCPNoDelay) - $($a.Name)" }
        $regs += @{ Path = $p; Name = "TcpDelAckTicks";  Value = 0; Type = "DWord"; Info = "Keine verzoegerte Bestaetigung - $($a.Name)" }
        foreach ($k in $NetAdvKeywords) {
            $prop = Get-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $k -ErrorAction SilentlyContinue
            if ($prop -and ("" + $prop.RegistryValue) -ne "0") {
                $bk.AdvProps += [ordered]@{ Adapter = $a.Name; Keyword = $k; Old = ("" + $prop.RegistryValue); Display = $prop.DisplayName }
            }
        }
        $pm = Get-NetAdapterPowerManagement -Name $a.Name -ErrorAction SilentlyContinue
        if ($pm -and ("" + $pm.AllowComputerToTurnOffDevice) -eq "Enabled") { $bk.Power += [ordered]@{ Adapter = $a.Name; Old = "Enabled" } }
    }
    foreach ($r in $regs) { $bk.Registry += (Get-RegState $r.Path $r.Name) }
    $bk | ConvertTo-Json -Depth 5 | Set-Content -Path $NetBackupFile -Encoding UTF8
    Log "  Sicherung gespeichert: $NetBackupFile" DarkGreen

    foreach ($r in $regs) {
        try { Set-Reg $r.Path $r.Name $r.Value $r.Type; Ok $r.Info } catch { Bad ($r.Info + ": " + $_.Exception.Message) }
    }
    foreach ($x in $bk.AdvProps) {
        try {
            Set-NetAdapterAdvancedProperty -Name $x.Adapter -RegistryKeyword $x.Keyword -RegistryValue "0" -NoRestart -ErrorAction Stop
            Ok ("Energiesparen aus: " + $x.Display + " - " + $x.Adapter)
        } catch { Warn ("Nicht moeglich: " + $x.Display) }
    }
    foreach ($x in $bk.Power) {
        try {
            Set-NetAdapterPowerManagement -Name $x.Adapter -AllowComputerToTurnOffDevice Disabled -NoRestart -ErrorAction Stop
            Ok ("Windows schaltet den Adapter nicht mehr zum Stromsparen ab - " + $x.Adapter)
        } catch { Warn ("Energieverwaltung nicht aenderbar - " + $x.Adapter) }
    }
    ipconfig /flushdns | Out-Null
    Ok "DNS-Cache geleert."

    if ($bk.AdvProps.Count -gt 0 -or $bk.Power.Count -gt 0) {
        Log "  Netzwerkadapter wird neu gestartet (Internet ist ein paar Sekunden weg) ..." DarkGreen
        foreach ($n in $bk.Adapters) { Restart-NetAdapter -Name $n -ErrorAction SilentlyContinue }
    }
    Log "`nFertig! Teste danach am besten nochmal mit dem Netzwerk-Test." Green
}

function Invoke-NetUndo {
    Log "`n######## Netzwerk zuruecksetzen ########" Green
    if (-not (Test-Path $NetBackupFile)) { Warn "Keine Netzwerk-Sicherung gefunden - nichts zu tun."; return }
    $bk = Get-Content $NetBackupFile -Raw | ConvertFrom-Json
    foreach ($r in $bk.Registry) {
        try {
            if ($r.Exists) { Set-Reg $r.Path $r.Name $r.Value $r.Kind }
            elseif (Test-Path $r.Path) { Remove-ItemProperty -Path $r.Path -Name $r.Name -ErrorAction SilentlyContinue }
            Ok $r.Name
        } catch { Bad ($r.Name + ": " + $_.Exception.Message) }
    }
    foreach ($x in $bk.AdvProps) {
        try { Set-NetAdapterAdvancedProperty -Name $x.Adapter -RegistryKeyword $x.Keyword -RegistryValue $x.Old -NoRestart -ErrorAction Stop; Ok ("Wiederhergestellt: " + $x.Display) }
        catch { Warn ("Nicht wiederherstellbar: " + $x.Display) }
    }
    foreach ($x in $bk.Power) {
        try { Set-NetAdapterPowerManagement -Name $x.Adapter -AllowComputerToTurnOffDevice Enabled -NoRestart -ErrorAction Stop; Ok ("Energieverwaltung wiederhergestellt - " + $x.Adapter) }
        catch { Warn ("Energieverwaltung nicht wiederherstellbar - " + $x.Adapter) }
    }
    if ($bk.AdvProps.Count -gt 0 -or $bk.Power.Count -gt 0) {
        Log "  Netzwerkadapter wird neu gestartet ..." DarkGreen
        foreach ($n in $bk.Adapters) { Restart-NetAdapter -Name $n -ErrorAction SilentlyContinue }
    }
    Rename-Item $NetBackupFile ("net_backup_rueckgaengig_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
    Log "`nNetzwerk-Einstellungen sind wieder wie vorher." Green
}


# ------------------------------------------------------------
#  Windows entschlacken
# ------------------------------------------------------------
$DebloatBackupFile = Join-Path $BackupDir "debloat_backup.json"

# Telemetrie, Werbung und Vorschlaege (Registry)
$DebloatReg = @(
    @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Value=1; Type="DWord"; Info="Telemetrie auf Minimum" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name="Enabled"; Value=0; Type="DWord"; Info="Werbe-ID aus" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name="TailoredExperiencesWithDiagnosticDataEnabled"; Value=0; Type="DWord"; Info="Personalisierte Werbung aus" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SilentInstalledAppsEnabled"; Value=0; Type="DWord"; Info="Keine automatisch installierten Werbe-Apps" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SystemPaneSuggestionsEnabled"; Value=0; Type="DWord"; Info="Startmenue-Vorschlaege aus" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338388Enabled"; Value=0; Type="DWord"; Info="Startmenue-Werbung aus" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338389Enabled"; Value=0; Type="DWord"; Info="Tipps und Tricks aus" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-353694Enabled"; Value=0; Type="DWord"; Info="Vorschlaege in Einstellungen aus" },
    @{ Path="HKCU:\Software\Microsoft\Siuf\Rules"; Name="NumberOfSIUFInPeriod"; Value=0; Type="DWord"; Info="Feedback-Anfragen aus" }
)

# Dienste, die beim Spielen nichts tun (Name, gewuenschter Starttyp)
$DebloatServices = [ordered]@{
    "DiagTrack"        = "Disabled"   # Telemetrie-Dienst
    "dmwappushservice" = "Disabled"   # Telemetrie-Weiterleitung
    "MapsBroker"       = "Manual"     # Offline-Karten
    "RetailDemo"       = "Disabled"   # Laden-Demo-Modus
    "Fax"              = "Manual"     # Fax
    "WerSvc"           = "Manual"     # Fehlerberichte (startet nur bei Bedarf)
}

# Vorinstallierte Apps, die sicher weg koennen (nur fuer den aktuellen Benutzer, im Store wieder installierbar)
$BloatApps = [ordered]@{
    "Microsoft.BingNews"                 = "Microsoft News"
    "Microsoft.BingWeather"              = "Wetter"
    "Microsoft.GetHelp"                  = "Hilfe anfordern"
    "Microsoft.Getstarted"               = "Tipps"
    "Microsoft.MicrosoftSolitaireCollection" = "Solitaire"
    "Microsoft.People"                   = "Kontakte"
    "Microsoft.WindowsFeedbackHub"       = "Feedback-Hub"
    "Microsoft.WindowsMaps"              = "Karten"
    "Microsoft.MicrosoftOfficeHub"       = "Office-Werbe-App"
    "Microsoft.SkypeApp"                 = "Skype"
    "Clipchamp.Clipchamp"                = "Clipchamp"
    "Microsoft.Todos"                    = "To Do"
    "Microsoft.549981C3F5F10"            = "Cortana"
    "Microsoft.ZuneVideo"                = "Filme und TV"
    "MicrosoftCorporationII.QuickAssist" = "Remotehilfe"
}

function Invoke-Debloat {
    Log "`n######## Windows entschlacken ########" Green
    if (Test-Path $DebloatBackupFile) { Warn "Entschlacken ist schon aktiv. Zum Neu-Anwenden erst zuruecksetzen."; return }
    New-GTRestorePoint "Vor GreenTweak Entschlacken"
    $bk = [ordered]@{ Created = (Get-Date).ToString("s"); Registry = @(); Services = @() }
    foreach ($r in $DebloatReg) { $bk.Registry += (Get-RegState $r.Path $r.Name) }
    foreach ($n in $DebloatServices.Keys) {
        $svc = Get-Service -Name $n -ErrorAction SilentlyContinue
        if ($svc) { $bk.Services += [ordered]@{ Name = $n; StartType = ("" + $svc.StartType); Running = ($svc.Status -eq "Running") } }
    }
    $bk | ConvertTo-Json -Depth 5 | Set-Content -Path $DebloatBackupFile -Encoding UTF8
    Log "  Sicherung gespeichert: $DebloatBackupFile" DarkGreen

    Log "`n== Telemetrie und Werbung ==" Green
    foreach ($r in $DebloatReg) {
        try { Set-Reg $r.Path $r.Name $r.Value $r.Type; Ok $r.Info } catch { Bad ($r.Info + ": " + $_.Exception.Message) }
    }
    Log "`n== Dienste ==" Green
    foreach ($s in $bk.Services) {
        $target = $DebloatServices[$s.Name]
        try {
            if ($target -eq "Disabled") { Stop-Service -Name $s.Name -Force -ErrorAction SilentlyContinue }
            Set-Service -Name $s.Name -StartupType $target -ErrorAction Stop
            Ok ("{0} -> {1}" -f $s.Name, $(if ($target -eq "Disabled") { "aus" } else { "nur bei Bedarf" }))
        } catch { Warn ("{0} nicht aenderbar" -f $s.Name) }
    }
    Log "`nFertig. Rueckgaengig ueber 'Entschlacken zuruecksetzen'." Green
}

function Invoke-DebloatUndo {
    Log "`n######## Entschlacken zuruecksetzen ########" Green
    if (-not (Test-Path $DebloatBackupFile)) { Warn "Keine Sicherung gefunden - nichts zu tun."; return }
    $bk = Get-Content $DebloatBackupFile -Raw | ConvertFrom-Json
    foreach ($r in $bk.Registry) {
        try {
            if ($r.Exists) { Set-Reg $r.Path $r.Name $r.Value $r.Kind }
            elseif (Test-Path $r.Path) { Remove-ItemProperty -Path $r.Path -Name $r.Name -ErrorAction SilentlyContinue }
            Ok $r.Name
        } catch { Bad ($r.Name + ": " + $_.Exception.Message) }
    }
    foreach ($s in $bk.Services) {
        try {
            $st = if ($s.StartType -eq "Disabled") { "Disabled" } elseif ($s.StartType -eq "Manual") { "Manual" } else { "Automatic" }
            Set-Service -Name $s.Name -StartupType $st -ErrorAction Stop
            if ($s.Running) { Start-Service -Name $s.Name -ErrorAction SilentlyContinue }
            Ok ("{0} wiederhergestellt ({1})" -f $s.Name, $st)
        } catch { Warn ("{0} nicht wiederherstellbar" -f $s.Name) }
    }
    Rename-Item $DebloatBackupFile ("debloat_backup_rueckgaengig_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
    Log "`nWieder wie vorher." Green
}

function Get-BloatAppsInstalled {
    foreach ($id in $BloatApps.Keys) {
        $pkg = Get-AppxPackage -Name $id -ErrorAction SilentlyContinue
        if ($pkg) { [pscustomobject]@{ Id = $id; Name = $BloatApps[$id]; Package = $pkg } }
    }
}

function Invoke-RemoveBloatApps {
    Log "`n######## Vorinstallierte Apps entfernen ########" Green
    $found = @(Get-BloatAppsInstalled)
    if ($found.Count -eq 0) { Ok "Keine der unnoetigen Apps gefunden - schon sauber."; return }
    foreach ($a in $found) {
        try { $a.Package | Remove-AppxPackage -ErrorAction Stop; Ok ("Entfernt: " + $a.Name) }
        catch { Warn ("Nicht entfernbar: " + $a.Name) }
    }
    Log "  Hinweis: Entfernte Apps kannst du jederzeit kostenlos im Microsoft Store neu installieren." DarkGreen
}

function Invoke-DeepClean {
    Log "`n######## Zwischenspeicher leeren ########" Green
    Remove-FolderContent $env:TEMP "Benutzer-Temp"
    Remove-FolderContent "$env:SystemRoot\Temp" "Windows-Temp"
    Remove-FolderContent "$env:ProgramData\Microsoft\Windows\WER\ReportArchive" "Alte Fehlerberichte"
    Remove-FolderContent "$env:ProgramData\Microsoft\Windows\WER\ReportQueue" "Wartende Fehlerberichte"
    try {
        Stop-Service wuauserv -Force -ErrorAction Stop
        Remove-FolderContent "$env:SystemRoot\SoftwareDistribution\Download" "Windows-Update-Downloads"
        Start-Service wuauserv -ErrorAction SilentlyContinue
    } catch { Warn "Windows-Update-Cache uebersprungen (Update laeuft gerade?)." }
    try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop; Ok "Uebermittlungsoptimierung-Cache geleert." } catch {}
    ipconfig /flushdns | Out-Null; Ok "DNS-Cache geleert."
}

# ------------------------------------------------------------
#  Spielprofile
# ------------------------------------------------------------
$GamesBackupFile = Join-Path $BackupDir "games_backup.json"
$GameDefs = [ordered]@{
    "Fortnite" = @("Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe",
                   "Program Files\Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe")
    "Valorant" = @("Riot Games\VALORANT\live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe",
                   "Program Files\Riot Games\VALORANT\live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe")
    "CS2"      = @("Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64\cs2.exe",
                   "SteamLibrary\steamapps\common\Counter-Strike Global Offensive\game\bin\win64\cs2.exe",
                   "Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64\cs2.exe")
}

function Find-GameExe($game) {
    $roots = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Root -match "^[A-Z]:\\$" } | ForEach-Object { $_.Root }
    foreach ($r in $roots) { foreach ($rel in $GameDefs[$game]) { $p = Join-Path $r $rel; if (Test-Path $p) { return $p } } }
    return $null
}

function Invoke-GameProfile($game) {
    Log "`n######## Spielprofil: $game ########" Green
    $exe = Find-GameExe $game
    if (-not $exe) { Warn "$game wurde nicht gefunden (Standard-Installationsordner)."; return }
    Log "  Gefunden: $exe" DarkGreen
    $bk = if (Test-Path $GamesBackupFile) { Get-Content $GamesBackupFile -Raw | ConvertFrom-Json } else { [pscustomobject]@{ Registry = @() } }
    $reg = @{ Path = $GpuPrefKey; Name = $exe; Value = "GpuPreference=2;"; Type = "String" }
    if (-not ($bk.Registry | Where-Object { $_.Name -eq $exe })) {
        $bk.Registry = @($bk.Registry) + (Get-RegState $reg.Path $reg.Name)
        $bk | ConvertTo-Json -Depth 5 | Set-Content -Path $GamesBackupFile -Encoding UTF8
    }
    try { Set-Reg $reg.Path $reg.Name $reg.Value $reg.Type; Ok "$game laeuft auf der starken Grafikkarte (Hoechstleistung)." } catch { Bad $_.Exception.Message }
    Log "  Tipp: Im Spiel 'Vollbild' statt 'Fenster' nutzen und V-Sync aus - das bringt am meisten." DarkGreen
}

function Invoke-GameProfilesUndo {
    Log "`n######## Spielprofile zuruecksetzen ########" Green
    if (-not (Test-Path $GamesBackupFile)) { Warn "Keine Spielprofile aktiv."; return }
    $bk = Get-Content $GamesBackupFile -Raw | ConvertFrom-Json
    foreach ($r in $bk.Registry) {
        if ($r.Exists) { Set-Reg $r.Path $r.Name $r.Value $r.Kind } elseif (Test-Path $r.Path) { Remove-ItemProperty -Path $r.Path -Name $r.Name -ErrorAction SilentlyContinue }
        Ok ("Zurueckgesetzt: " + (Split-Path $r.Name -Leaf))
    }
    Rename-Item $GamesBackupFile ("games_backup_rueckgaengig_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")
}

function Invoke-FiveMDeepClean {
    Log "`n######## FiveM komplett bereinigen ########" Green
    if (Get-Process -Name "FiveM*" -ErrorAction SilentlyContinue) { Warn "FiveM laeuft noch - bitte erst schliessen."; return }
    $app = Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app"
    if (-not (Test-Path $app)) { Warn "FiveM wurde nicht gefunden."; return }
    Remove-FolderContent (Join-Path $app "data\cache")             "Cache"
    Remove-FolderContent (Join-Path $app "data\server-cache")      "Server-Cache"
    Remove-FolderContent (Join-Path $app "data\server-cache-priv") "Server-Cache (privat)"
    Remove-FolderContent (Join-Path $app "logs")                   "Logs"
    Remove-FolderContent (Join-Path $app "crashes")                "Absturzberichte"
    Log "  Deine Einstellungen, Keybinds und die GTA-Spieldateien bleiben erhalten." DarkGreen
    Log "  Der erste Serverbeitritt danach dauert etwas laenger (Dateien werden neu geladen)." DarkGreen
}


# ============================================================
#  v2.6: Wiederherstellungspunkt, Autostart, FPS-Messung, Hintergrund-Check
# ============================================================
$FpsHistoryFile = Join-Path $BackupDir "fps_history.json"
$ToolsDir       = Join-Path $BackupDir "tools"
$PresentMonUrl  = "https://github.com/GameTechDev/PresentMon/releases/download/v2.6.0/PresentMon-2.6.0-x64.exe"
$PresentMonExe  = Join-Path $ToolsDir "PresentMon-2.6.0-x64.exe"

function New-GTRestorePoint($label) {
    Log "`n== Wiederherstellungspunkt ==" Green
    try {
        $k = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
        Set-ItemProperty -Path $k -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description $label -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Ok "Wiederherstellungspunkt erstellt ($label)."
    } catch {
        Warn "Kein Wiederherstellungspunkt moeglich (Computerschutz evtl. aus)."
        Warn "Die eigene Sicherung von GreenTweak wird trotzdem angelegt."
    }
}

# ---------- Autostart ----------
$StartupSources = @(
    @{ Kind = "Reg";    Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run";              Approved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
    @{ Kind = "Reg";    Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";              Approved = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" },
    @{ Kind = "Reg";    Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run";  Approved = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32" },
    @{ Kind = "Folder"; Path = (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup");     Approved = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" },
    @{ Kind = "Folder"; Path = (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\StartUp"); Approved = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" }
)
$StartupProtected = "SecurityHealth|Defender|RtkAud|Realtek|Waves|Synaptics|ELAN|igfx|Nahimic|ctfmon"

function Get-StartupItems {
    $items = @()
    foreach ($s in $StartupSources) {
        $names = @()
        if ($s.Kind -eq "Reg") {
            if (-not (Test-Path $s.Path)) { continue }
            $p = Get-ItemProperty -Path $s.Path -ErrorAction SilentlyContinue
            if (-not $p) { continue }
            foreach ($prop in $p.PSObject.Properties) {
                if ($prop.Name -like "PS*") { continue }
                $names += [pscustomobject]@{ Name = $prop.Name; Cmd = ("" + $prop.Value) }
            }
        } else {
            if (-not (Test-Path $s.Path)) { continue }
            foreach ($f in Get-ChildItem -Path $s.Path -File -ErrorAction SilentlyContinue) {
                if ($f.Name -eq "desktop.ini") { continue }
                $names += [pscustomobject]@{ Name = $f.Name; Cmd = $f.FullName }
            }
        }
        foreach ($n in $names) {
            $enabled = $true
            try {
                $v = (Get-ItemProperty -Path $s.Approved -Name $n.Name -ErrorAction Stop).($n.Name)
                if ($v -and $v.Length -gt 0 -and (($v[0] -band 1) -eq 1)) { $enabled = $false }
            } catch {}
            $items += [pscustomobject]@{
                Name      = $n.Name
                Cmd       = $n.Cmd
                Approved  = $s.Approved
                Enabled   = $enabled
                Protected = ($n.Name -match $StartupProtected -or $n.Cmd -match $StartupProtected)
            }
        }
    }
    return $items | Sort-Object Name
}

function Set-StartupItem($item, [bool]$enable) {
    if (-not (Test-Path $item.Approved)) { New-Item -Path $item.Approved -Force | Out-Null }
    if ($enable) {
        $bytes = [byte[]](2,0,0,0,0,0,0,0,0,0,0,0)
    } else {
        $ft = [BitConverter]::GetBytes((Get-Date).ToFileTime())
        $bytes = [byte[]](@(3,0,0,0) + $ft)
    }
    Set-ItemProperty -Path $item.Approved -Name $item.Name -Value $bytes -Type Binary
    if ($enable) { Ok ("Autostart an: " + $item.Name) } else { Ok ("Autostart aus: " + $item.Name) }
}

# ---------- Hintergrund-Check ----------
$HogTips = [ordered]@{
    "chrome|msedge|firefox|opera|brave" = "Browser offen - beim Zocken schliessen spart RAM und CPU."
    "obs64|obs32"                        = "OBS laeuft - nur offen lassen, wenn du aufnimmst/streamst."
    "Discord"                            = "Discord: Einstellungen > Erweitert > Hardwarebeschleunigung aus und Spiel-Overlay aus."
    "Spotify"                            = "Spotify: Hardwarebeschleunigung in den Einstellungen ausschalten."
    "steamwebhelper"                     = "Steam: Overlay und Browser-Hintergrund verbrauchen RAM."
    "EpicGamesLauncher"                  = "Epic Launcher im Hintergrund - schliessen, wenn du ihn nicht brauchst."
    "OneDrive"                           = "OneDrive synchronisiert - beim Zocken pausieren."
    "Teams|ms-teams"                     = "Teams im Hintergrund - schliessen, wenn nicht gebraucht."
    "wallpaper32|wallpaper64"            = "Wallpaper Engine - kostet GPU-Leistung."
    "iCUE|NZXT CAM|SignalRgb|LightingService" = "RGB-Software kann kleine Ruckler verursachen."
}

function Invoke-BackgroundCheck {
    Log "`n######## Hintergrund-Check ########" Green
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID }
    $groups = $procs | Group-Object ProcessName | ForEach-Object {
        [pscustomobject]@{ Name = $_.Name; MB = [math]::Round((($_.Group | Measure-Object WorkingSet64 -Sum).Sum) / 1MB) }
    } | Sort-Object MB -Descending
    Log "  Groesste RAM-Verbraucher:" DarkGreen
    foreach ($g in ($groups | Select-Object -First 8)) { Log ("    {0,-28} {1,6} MB" -f $g.Name, $g.MB) DarkGreen }
    $found = 0
    foreach ($k in $HogTips.Keys) {
        $hit = $groups | Where-Object { $_.Name -match ("^(" + $k + ")$") } | Select-Object -First 1
        if ($hit) { Warn ($hit.Name + " (" + $hit.MB + " MB): " + $HogTips[$k]); $found++ }
    }
    if ($found -eq 0) { Ok "Keine typischen FPS-Fresser im Hintergrund gefunden." }
    $os = Get-CimInstance Win32_OperatingSystem
    $usedPct = [math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100)
    if ($usedPct -gt 80) { Warn "RAM zu $usedPct % belegt - Programme schliessen hilft gegen Ruckler." }
    else { Ok "RAM zu $usedPct % belegt." }
}

# ---------- FPS-Messung (Intel PresentMon) ----------
function Get-GameProcess {
    $pattern = "GTAProcess|^GTA5$|^GTA5_Enhanced$|^FortniteClient-Win64-Shipping$|^VALORANT-Win64-Shipping$|^cs2$"
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match $pattern } |
        Sort-Object WorkingSet64 -Descending | Select-Object -First 1
}

function Get-PresentMon {
    if (Test-Path $PresentMonExe) { return $PresentMonExe }
    Log "  Lade Messwerkzeug (Intel PresentMon, ca. 1 MB) ..." DarkGreen
    if (-not (Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
    $tmp = $PresentMonExe + ".download"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $PresentMonUrl -OutFile $tmp -UseBasicParsing -TimeoutSec 60
    } catch { Bad "Download fehlgeschlagen. Internet pruefen."; return $null }
    $sig = Get-AuthenticodeSignature $tmp
    if ($sig.Status -ne "Valid" -or $sig.SignerCertificate.Subject -notmatch "Intel") {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Bad "Messwerkzeug hat keine gueltige Intel-Signatur - abgebrochen."
        return $null
    }
    Move-Item $tmp $PresentMonExe -Force
    Ok "Messwerkzeug bereit (signiert von Intel)."
    return $PresentMonExe
}

function Get-FpsHistory {
    $out = @()
    if (Test-Path $FpsHistoryFile) {
        try {
            $j = Get-Content $FpsHistoryFile -Raw | ConvertFrom-Json
            foreach ($e in $j) { $out += $e }
        } catch {}
    }
    return $out
}

function Invoke-FpsMeasure([int]$Seconds = 30, [int]$Delay = 10) {
    Log "`n######## FPS-Messung ########" Green
    $game = Get-GameProcess
    if (-not $game) {
        Warn "Kein Spiel gefunden. Starte zuerst FiveM/GTA (oder Fortnite, Valorant, CS2) und geh ins Spiel."
        return $null
    }
    $exe = Get-PresentMon
    if (-not $exe) { return $null }
    $csv = Join-Path $ToolsDir "messung.csv"
    Remove-Item $csv -Force -ErrorAction SilentlyContinue
    Log ("  Spiel erkannt: " + $game.ProcessName) DarkGreen
    Log "  Wechsle jetzt ins Spiel! Messung startet in $Delay Sekunden und dauert $Seconds Sekunden." Yellow
    Log "  Tipp: Fuer faire Vergleiche immer an der gleichen Stelle messen." DarkGreen
    $pmArgs = "--process_id $($game.Id) --delay $Delay --timed $Seconds --terminate_after_timed --output_file `"$csv`" --stop_existing_session --no_console_stats --v1_metrics --session_name GreenTweakFps"
    $p = Start-Process -FilePath $exe -ArgumentList $pmArgs -WindowStyle Hidden -PassThru
    $limit = (Get-Date).AddSeconds($Delay + $Seconds + 20)
    $lastSay = -1
    while (-not $p.HasExited -and (Get-Date) -lt $limit) {
        Start-Sleep -Milliseconds 250
        $left = [int](($limit.AddSeconds(-20) - (Get-Date)).TotalSeconds)
        if ($left -ne $lastSay -and $left -ge 0 -and ($left % 5 -eq 0)) { Log "  ... noch $left Sekunden" DarkGreen; $lastSay = $left }
        if (Get-Command Update-UI -ErrorAction SilentlyContinue) { Update-UI }
    }
    if (-not $p.HasExited) { try { $p.Kill() } catch {} }
    if (-not (Test-Path $csv)) { Bad "Keine Messdaten. War das Spiel im Vordergrund?"; return $null }
    $ms = @()
    foreach ($row in (Import-Csv $csv)) {
        $v = 0.0
        if ([double]::TryParse(("" + $row.MsBetweenPresents), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$v)) {
            if ($v -gt 0 -and $v -lt 1000) { $ms += $v }
        }
    }
    if ($ms.Count -lt 50) { Bad "Zu wenige Bilder gemessen. Bitte im Spiel bleiben und nochmal messen."; return $null }
    $avg    = 1000 / (($ms | Measure-Object -Average).Average)
    $sorted = $ms | Sort-Object
    $p99    = $sorted[[math]::Min($sorted.Count - 1, [int][math]::Floor($sorted.Count * 0.99))]
    $low1   = 1000 / $p99
    $res = [pscustomobject]@{
        Date  = (Get-Date).ToString("dd.MM.yyyy HH:mm")
        Game  = $game.ProcessName
        Avg   = [math]::Round($avg)
        Low1  = [math]::Round($low1)
        Tweak = (Test-Path $BackupFile)
    }
    $hist = @(Get-FpsHistory) + $res
    $hist | Select-Object -Last 50 | ConvertTo-Json | Set-Content -Path $FpsHistoryFile -Encoding UTF8
    Ok ("Durchschnitt: " + $res.Avg + " FPS | 1% Low: " + $res.Low1 + " FPS")
    $before = $hist | Where-Object { -not $_.Tweak -and $_.Game -eq $res.Game } | Select-Object -First 1
    if ($res.Tweak -and $before) {
        $diff = $res.Avg - $before.Avg
        $pct  = [math]::Round($diff / [math]::Max(1, $before.Avg) * 100)
        Ok ("Vergleich mit Messung ohne Tweak (" + $before.Date + "): " + $before.Avg + " -> " + $res.Avg + " FPS (" + $(if ($diff -ge 0) { "+" } else { "" }) + $pct + " %)")
    } elseif (-not $res.Tweak) {
        Log "  Das war deine Messung OHNE Tweak. Wende jetzt ein Profil an, starte neu und miss nochmal." Yellow
    }
    return $res
}

# ============================================================
#  v2.7: Gaming-Modus (vor dem Zocken an, danach aus)
# ============================================================
$GameModeFile = Join-Path $BackupDir "gamemode.json"
$GameModeClose = @("OneDrive", "Teams", "ms-teams", "PhoneExperienceHost", "YourPhone", "Widgets", "WidgetService",
                   "GoogleDriveFS", "Dropbox", "AdobeCollabSync", "CCleaner64", "CCleaner")
$GameModeRestart = @("OneDrive", "GoogleDriveFS", "Dropbox")
$ToastKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"

function Test-GameMode { return (Test-Path $GameModeFile) }

function Get-GameModeTargets {
    Get-Process -ErrorAction SilentlyContinue | Where-Object { $GameModeClose -contains $_.ProcessName } |
        Sort-Object ProcessName -Unique
}

function Invoke-GameModeOn {
    Log "`n######## Gaming-Modus AN ########" Green
    if (Test-GameMode) { Warn "Gaming-Modus ist schon an."; return }
    $state = [ordered]@{ Created = (Get-Date).ToString("s"); PowerPlan = $null; Toasts = $null; Restart = @() }

    # Energieplan
    $state.PowerPlan = Get-GuidFromText (powercfg /getactivescheme)
    $gt = (powercfg /list) | Where-Object { $_ -match "GreenTweak Gaming" } | Select-Object -First 1
    $target = if ($gt) { Get-GuidFromText $gt } else { "SCHEME_MIN" }
    powercfg /setactive $target 2>$null | Out-Null
    Ok "Energieplan auf Hoechstleistung."

    # Benachrichtigungen aus
    $state.Toasts = Get-RegState $ToastKey "ToastEnabled"
    Set-Reg $ToastKey "ToastEnabled" 0 "DWord"
    Ok "Windows-Benachrichtigungen pausiert."

    # Hintergrund-Programme schliessen
    $n = 0
    foreach ($p in @(Get-GameModeTargets)) {
        $path = $null
        try { $path = $p.Path } catch {}
        if ($path -and ($GameModeRestart -contains $p.ProcessName)) { $state.Restart += $path }
        Get-Process -Name $p.ProcessName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Ok ("Geschlossen: " + $p.ProcessName)
        $n++
    }
    if ($n -eq 0) { Ok "Keine stoerenden Hintergrund-Programme gefunden." }

    # Browser nur melden, nicht schliessen (offene Tabs!)
    $br = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match "^(chrome|msedge|firefox|opera|brave)$" } | Select-Object -ExpandProperty ProcessName -Unique
    foreach ($b in $br) { Warn "$b ist offen - am besten selbst schliessen (wegen deiner Tabs nicht automatisch)." }

    [void][System.GC]::Collect()
    $state | ConvertTo-Json -Depth 4 | Set-Content -Path $GameModeFile -Encoding UTF8
    Log "  Gaming-Modus ist AN. Nach dem Zocken wieder ausschalten." Yellow
}

function Invoke-GameModeOff {
    Log "`n######## Gaming-Modus AUS ########" Green
    if (-not (Test-GameMode)) { Warn "Gaming-Modus ist nicht an."; return }
    $s = Get-Content $GameModeFile -Raw | ConvertFrom-Json
    if ($s.PowerPlan) { powercfg /setactive $s.PowerPlan 2>$null | Out-Null; Ok "Vorheriger Energieplan wieder aktiv." }
    if ($s.Toasts) {
        if ($s.Toasts.Exists) { Set-Reg $ToastKey "ToastEnabled" $s.Toasts.Value "DWord" }
        else { Remove-ItemProperty -Path $ToastKey -Name "ToastEnabled" -ErrorAction SilentlyContinue }
        Ok "Benachrichtigungen wieder an."
    }
    foreach ($path in @($s.Restart)) {
        if ($path -and (Test-Path $path)) {
            $a = if ($path -match "OneDrive") { "/background" } else { "" }
            try {
                if ($a) { Start-Process -FilePath $path -ArgumentList $a } else { Start-Process -FilePath $path }
                Ok ("Wieder gestartet: " + (Split-Path $path -Leaf))
            } catch {}
        }
    }
    Remove-Item $GameModeFile -Force -ErrorAction SilentlyContinue
    Log "  Gaming-Modus ist AUS. Alles wie vorher." Yellow
}

# ============================================================
#  v2.8: 1-Klick-Optimierung (erkennt die Hardware selbst)
# ============================================================
function Get-HardwareInfo {
    $hw = [ordered]@{ Gpu = "Unbekannt"; Vendor = "Unbekannt"; Dedicated = $false; Laptop = $false; OnBattery = $false
                      RamGB = 0; RamType = "RAM"; RamSpeed = 0; XmpOff = $false; Cpu = ""; Cores = 0; DriverDays = -1 }
    try {
        $gpus = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Microsoft|Basic|Virtual|Parsec|Remote|Meta" })
        $dg = $gpus | Where-Object { $_.Name -match "NVIDIA|GeForce|Quadro|Radeon RX|Radeon Pro|Arc\(TM\) [AB]\d|Arc [AB]\d" } | Select-Object -First 1
        $g = if ($dg) { $dg } else { $gpus | Select-Object -First 1 }
        if ($g) {
            $hw.Gpu = $g.Name.Trim()
            $hw.Vendor = if ($g.Name -match "NVIDIA|GeForce|Quadro") { "NVIDIA" } elseif ($g.Name -match "AMD|Radeon") { "AMD" } elseif ($g.Name -match "Intel") { "Intel" } else { "Unbekannt" }
            $hw.Dedicated = [bool]$dg
            try { $hw.DriverDays = [int]((Get-Date) - $g.DriverDate).TotalDays } catch {}
        }
    } catch {}
    try {
        $ch = @((Get-CimInstance Win32_SystemEnclosure).ChassisTypes)
        $bat = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
        $hw.Laptop = ($bat.Count -gt 0) -or (@($ch | Where-Object { @(8,9,10,11,12,14,18,21,30,31,32) -contains $_ }).Count -gt 0)
        if ($bat.Count -gt 0) { $hw.OnBattery = ($bat[0].BatteryStatus -eq 1) }
    } catch {}
    try {
        $mem = @(Get-CimInstance Win32_PhysicalMemory)
        $hw.RamGB = [math]::Round(($mem | Measure-Object Capacity -Sum).Sum / 1GB)
        $hw.RamSpeed = ($mem | Measure-Object ConfiguredClockSpeed -Minimum).Minimum
        $hw.RamType = switch ($mem[0].SMBIOSMemoryType) { 26 { "DDR4" } 34 { "DDR5" } default { "RAM" } }
        $hw.XmpOff = ($hw.RamType -eq "DDR4" -and $hw.RamSpeed -le 2666) -or ($hw.RamType -eq "DDR5" -and $hw.RamSpeed -le 4800)
    } catch {}
    try {
        $c = Get-CimInstance Win32_Processor | Select-Object -First 1
        $hw.Cpu = $c.Name.Trim(); $hw.Cores = $c.NumberOfCores
    } catch {}
    return [pscustomobject]$hw
}

function Get-AutoPlan($hw) {
    $weak = (-not $hw.Dedicated) -or ($hw.RamGB -gt 0 -and $hw.RamGB -le 8)
    $plan = [ordered]@{ Profile = $null; Debloat = $false; Weak = $weak; Steps = @(); Tips = @() }
    if (-not (Test-Path $BackupFile)) {
        $plan.Profile = if ($weak) { "Max FPS" } else { "Gaming" }
        if ($weak) { $plan.Steps += "Profil 'Max FPS' (schwaechere Hardware: auch GTA/FiveM-Grafik auf FPS)" }
        else       { $plan.Steps += "Profil 'Gaming' (starke Hardware: Grafik bleibt schoen, System wird schneller)" }
    } else { $plan.Tips += "Ein Profil ist schon aktiv - wird nicht nochmal angewendet." }
    if (-not (Test-Path $DebloatBackupFile)) { $plan.Debloat = $true; $plan.Steps += "Windows entschlacken (Telemetrie, Werbung, unnoetige Dienste)" }
    $plan.Steps += "Temporaere Dateien und FiveM-Cache aufraeumen"
    $plan.Steps += "Hintergrund-Check (FPS-Fresser finden)"
    if ($hw.OnBattery) { $plan.Tips += "Laptop laeuft auf Akku - zum Zocken unbedingt das Ladekabel einstecken!" }
    if ($hw.XmpOff)    { $plan.Tips += "RAM laeuft nur mit $($hw.RamSpeed) MT/s - XMP/EXPO im BIOS einschalten bringt oft viele FPS." }
    if ($hw.DriverDays -gt 120) { $plan.Tips += "Grafiktreiber ist $($hw.DriverDays) Tage alt - Update beim Hersteller ($($hw.Vendor)) holen." }
    if ($hw.RamGB -gt 0 -and $hw.RamGB -lt 16) { $plan.Tips += "Nur $($hw.RamGB) GB RAM - fuer FiveM sind 16 GB empfohlen. Browser beim Zocken schliessen." }
    return [pscustomobject]$plan
}

function Invoke-AutoOptimize {
    Log "`n################ 1-KLICK-OPTIMIERUNG ################" Green
    $hw = Get-HardwareInfo
    Log ("  Grafikkarte: " + $hw.Gpu + $(if ($hw.Dedicated) { " (dediziert)" } else { " (integriert)" })) DarkGreen
    Log ("  CPU: " + $hw.Cpu + " | RAM: " + $hw.RamGB + " GB " + $hw.RamType + " | " + $(if ($hw.Laptop) { "Laptop" } else { "Desktop-PC" })) DarkGreen
    $plan = Get-AutoPlan $hw
    if ($plan.Profile) { Invoke-ApplyProfile $plan.Profile }
    if ($plan.Debloat) { Invoke-Debloat }
    Invoke-Cleanup
    Invoke-BackgroundCheck
    if ($plan.Tips.Count -gt 0) {
        Log "`n== Tipps fuer deinen PC ==" Green
        foreach ($t in $plan.Tips) { Warn $t }
    }
    Log "`n  FERTIG! Bitte den PC neu starten, damit alles wirkt." Yellow
    Log "  Tipp: Miss deine FPS vorher und nachher auf der Seite 'FPS-Test'." DarkGreen
}

# ------------------------------------------------------------
#  Turbo (v3.1) - zusaetzliche FPS-Einstellungen, komplett umkehrbar
# ------------------------------------------------------------
$TurboFile = Join-Path $BackupDir "turbo.json"
$HvciKey   = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$FsoKey    = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

function Test-Turbo { return (Test-Path $TurboFile) }

function Get-HvciState {
    $s = [ordered]@{ Running = $false; Configured = $false; Locked = $false }
    try {
        $dg = Get-CimInstance -Namespace "root\Microsoft\Windows\DeviceGuard" -ClassName Win32_DeviceGuard -ErrorAction Stop
        if (@($dg.SecurityServicesRunning) -contains 2) { $s.Running = $true }
    } catch {}
    $r = Get-RegState $HvciKey "Enabled"
    if ($r.Exists -and $r.Value -eq 1) { $s.Configured = $true }
    $l = Get-RegState $HvciKey "Locked"
    if ($l.Exists -and $l.Value -eq 1) { $s.Locked = $true }
    return $s
}

function Get-TurboTweaks([bool]$Hvci) {
    $list = @()
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    # Optimierungen fuer Spiele im Fenstermodus (vorhandene Werte behalten)
    $dx = Get-RegState $GpuPrefKey "DirectXUserGlobalSettings"
    $parts = [ordered]@{}
    if ($dx.Exists -and $dx.Value) {
        foreach ($p in ("$($dx.Value)" -split ";")) { if ($p -match "^(.+?)=(.*)$") { $parts[$Matches[1]] = $Matches[2] } }
    }
    $parts["SwapEffectUpgradeEnable"] = "1"
    $val = (($parts.Keys | ForEach-Object { "$_=" + $parts[$_] }) -join ";") + ";"
    $list += @{ Path = $GpuPrefKey; Name = "DirectXUserGlobalSettings"; Value = $val; Type = "String"; Info = "Optimierungen fuer Spiele im Fenstermodus an" }

    # Vollbildoptimierung fuer GTA / FiveM aus
    foreach ($exe in Get-GameExePaths) {
        $cur = Get-RegState $FsoKey $exe
        if ($cur.Exists -and "$($cur.Value)" -match "DISABLEDXMAXIMIZEDWINDOWEDMODE") { continue }
        $v = if ($cur.Exists -and $cur.Value) { "$($cur.Value) DISABLEDXMAXIMIZEDWINDOWEDMODE" } else { "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" }
        if ($v -notmatch "^~") { $v = "~ " + $v }
        $list += @{ Path = $FsoKey; Name = $exe; Value = $v; Type = "String"; Info = "Vollbildoptimierung aus: " + (Split-Path $exe -Leaf) }
    }

    # Windows-Effekte auf Leistung
    $list += @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name = "VisualFXSetting"; Value = 3; Type = "DWord"; Info = "Visuelle Effekte: benutzerdefiniert" }
    $list += @{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "MinAnimate"; Value = "0"; Type = "String"; Info = "Fenster-Animationen aus" }
    $list += @{ Path = $adv; Name = "TaskbarAnimations"; Value = 0; Type = "DWord"; Info = "Taskleisten-Animationen aus" }
    $list += @{ Path = $adv; Name = "ListviewAlphaSelect"; Value = 0; Type = "DWord"; Info = "Transparente Auswahl aus" }
    $list += @{ Path = $adv; Name = "ListviewShadow"; Value = 0; Type = "DWord"; Info = "Schatten unter Symbolen aus" }
    $list += @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"; Value = 0; Type = "DWord"; Info = "Transparenz-Effekte aus" }
    $list += @{ Path = "HKCU:\Software\Microsoft\Windows\DWM"; Name = "EnableAeroPeek"; Value = 0; Type = "DWord"; Info = "Aero Peek aus" }

    if ($Hvci) {
        $list += @{ Path = $HvciKey; Name = "Enabled"; Value = 0; Type = "DWord"; Info = "Speicher-Integritaet aus (wirkt nach Neustart)" }
    }
    return $list
}

function Invoke-TurboOn([bool]$Hvci = $false) {
    Log "`n== Turbo einschalten ==" Green
    if ($Hvci) {
        $h = Get-HvciState
        if ($h.Locked) { Warn "Speicher-Integritaet ist per UEFI gesperrt und kann hier nicht ausgeschaltet werden."; $Hvci = $false }
        elseif (-not $h.Running -and -not $h.Configured) { Ok "Speicher-Integritaet ist bei dir schon aus."; $Hvci = $false }
    }
    $old = @()
    if (Test-Path $TurboFile) {
        try { foreach ($o in (Get-Content $TurboFile -Raw | ConvertFrom-Json).Registry) { $old += $o } } catch {}
    }
    $saved = @{}
    foreach ($o in $old) { $saved["$($o.Path)|$($o.Name)"] = $true }
    $backup = @() + $old
    foreach ($t in (Get-TurboTweaks $Hvci)) {
        try {
            if (-not $saved.ContainsKey("$($t.Path)|$($t.Name)")) { $backup += [pscustomobject](Get-RegState $t.Path $t.Name) }
            Set-Reg $t.Path $t.Name $t.Value $t.Type
            Ok $t.Info
        } catch { Bad ($t.Info + ": " + $_.Exception.Message) }
    }
    $hv = @($backup | Where-Object { $_.Path -eq $HvciKey }).Count -gt 0
    [pscustomobject]@{ Created = (Get-Date).ToString("dd.MM.yyyy HH:mm"); Hvci = $hv; Registry = $backup } |
        ConvertTo-Json -Depth 4 | Set-Content -Path $TurboFile -Encoding UTF8
    Log "`nTurbo ist an. Bitte den PC neu starten, damit alles wirkt." Green
    Log "Tipp: Danach den FPS-Test machen und mit vorher vergleichen." Green
}

function Invoke-TurboOff {
    if (-not (Test-Path $TurboFile)) { Warn "Turbo ist nicht aktiv."; return }
    Log "`n== Turbo ausschalten ==" Green
    $t = Get-Content $TurboFile -Raw | ConvertFrom-Json
    foreach ($r in $t.Registry) {
        try {
            if ($r.Exists) { Set-Reg $r.Path $r.Name $r.Value $r.Kind }
            elseif (Test-Path $r.Path) { Remove-ItemProperty -Path $r.Path -Name $r.Name -ErrorAction SilentlyContinue }
            Ok ("wiederhergestellt: " + (Split-Path $r.Name -Leaf))
        } catch { Bad ($r.Name + ": " + $_.Exception.Message) }
    }
    Remove-Item $TurboFile -Force -ErrorAction SilentlyContinue
    Log "`nTurbo ist aus. Bitte den PC neu starten." Green
}

# ============================================================
#  v3.2: Auto-Gaming-Modus (an, sobald FiveM laeuft)
# ============================================================
$AutoGameTask = "GreenTweak AutoGame"
$AutoGameVbs  = Join-Path $BackupDir "autogame.vbs"

function Test-AutoGame {
    try { return [bool](Get-ScheduledTask -TaskName $AutoGameTask -ErrorAction Stop) } catch { return $false }
}

function Stop-AutoGameProcess {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*-AutoGame*" -and $_.ProcessId -ne $PID } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Enable-AutoGame {
    Log "`n== Auto-Gaming-Modus einschalten ==" Green
    $script = Join-Path $PSScriptRoot "GreenTweak.ps1"
    $vbs = 'CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""' + $script + '"" -AutoGame", 0, False'
    Set-Content -Path $AutoGameVbs -Value $vbs -Encoding ASCII
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $act  = New-ScheduledTaskAction -Execute "wscript.exe" -Argument ('"' + $AutoGameVbs + '"')
    $trg  = New-ScheduledTaskTrigger -AtLogOn -User $user
    $prn  = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
    $set  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -TaskName $AutoGameTask -Action $act -Trigger $trg -Principal $prn -Settings $set -Force | Out-Null
    Stop-AutoGameProcess
    Start-ScheduledTask -TaskName $AutoGameTask
    Ok "Auto-Gaming-Modus ist an. Sobald FiveM laeuft, geht der Gaming-Modus automatisch an - danach wieder aus."
}

function Disable-AutoGame {
    Log "`n== Auto-Gaming-Modus ausschalten ==" Green
    try { Unregister-ScheduledTask -TaskName $AutoGameTask -Confirm:$false -ErrorAction Stop } catch {}
    Stop-AutoGameProcess
    Remove-Item $AutoGameVbs -Force -ErrorAction SilentlyContinue
    Ok "Auto-Gaming-Modus ist aus."
}

function Start-AutoGameWatcher {
    $m = New-Object System.Threading.Mutex($false, "Global\GreenTweakAutoGame")
    if (-not $m.WaitOne(0)) { return }
    $mine = $false
    while ($true) {
        try {
            $game = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match "^FiveM|GTAProcess|^GTA5$|^GTA5_Enhanced$" }).Count -gt 0
            if ($game -and -not $mine -and -not (Test-GameMode)) { Invoke-GameModeOn; $mine = $true }
            elseif ((-not $game) -and $mine) {
                if (Test-GameMode) { Invoke-GameModeOff }
                $mine = $false
            }
        } catch {}
        Start-Sleep -Seconds 5
    }
}

# ============================================================
#  v3.2: Live-Werte (Temperatur, Auslastung)
# ============================================================
function Get-NvidiaSmi {
    $cands = @((Join-Path $env:SystemRoot "System32\nvidia-smi.exe"), (Join-Path $env:ProgramFiles "NVIDIA Corporation\NVSMI\nvidia-smi.exe"))
    foreach ($p in $cands) { if (Test-Path $p) { return $p } }
    return $null
}

function Get-LiveStats {
    $s = [ordered]@{ GpuName = ""; GpuTemp = $null; GpuLoad = $null; VramUsed = $null; VramTotal = $null; CpuLoad = $null; CpuTemp = $null }
    $smi = Get-NvidiaSmi
    if ($smi) {
        try {
            $line = & $smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>$null | Select-Object -First 1
            $f = "$line" -split ","
            if ($f.Count -ge 5) {
                $s.GpuName = $f[0].Trim()
                $s.GpuTemp = [int]$f[1].Trim()
                $s.GpuLoad = [int]$f[2].Trim()
                $s.VramUsed = [int]$f[3].Trim()
                $s.VramTotal = [int]$f[4].Trim()
            }
        } catch {}
    }
    try { $s.CpuLoad = [int]((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average) } catch {}
    try {
        $tz = Get-CimInstance -Namespace "root/wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Select-Object -First 1
        $c = [math]::Round($tz.CurrentTemperature / 10 - 273.15)
        if ($c -gt 15 -and $c -lt 115) { $s.CpuTemp = [int]$c }
    } catch {}
    return $s
}

if ($AutoGame) { Start-AutoGameWatcher; return }
if ($NoMenu) { return }

# ------------------------------------------------------------
#  Menue
# ------------------------------------------------------------
do {
    Clear-Host
    Write-Host ""
    Write-Host "   ____                     _____                    _    " -ForegroundColor Green
    Write-Host "  / ___|_ __ ___  ___ _ __ |_   _|_      _____  __ _| | __" -ForegroundColor Green
    Write-Host " | |  _| '__/ _ \/ _ \ '_ \  | | \ \ /\ / / _ \/ _' | |/ /" -ForegroundColor Green
    Write-Host " | |_| | | |  __/  __/ | | | | |  \ V  V /  __/ (_| |   < " -ForegroundColor Green
    Write-Host "  \____|_|  \___|\___|_| |_| |_|   \_/\_/ \___|\__,_|_|\_\" -ForegroundColor Green
    Write-Host "                                                     v$Version" -ForegroundColor DarkGreen
    Write-Host "  =========================================================" -ForegroundColor DarkGreen
    if (Test-Path $BackupFile) {
        $b = Get-Content $BackupFile -Raw | ConvertFrom-Json
        $p = if ($b.Profile) { $b.Profile } else { "Gaming" }
        Write-Host "  Status: Tweaks AKTIV ($p)" -ForegroundColor Green
    } else { Write-Host "  Status: Tweaks nicht aktiv" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host -ForegroundColor Green "  [7] Systemcheck (zuerst ausfuehren!)"
    Write-Host ""
    Write-Host -ForegroundColor Green "  [1] Profil anwenden (Leicht / Gaming / Max FPS)"
    Write-Host -ForegroundColor Green "  [2] Nur aufraeumen (Temp + FiveM-Cache)"
    Write-Host -ForegroundColor Green "  [3] Alles rueckgaengig machen"
    Write-Host -ForegroundColor Green "  [4] Status anzeigen"
    Write-Host ""
    Write-Host -ForegroundColor Green "  [5] GTA/FiveM: Grafik auf FPS"
    Write-Host -ForegroundColor Green "  [6] GTA/FiveM: Grafik zuruecksetzen"
    Write-Host ""
    Write-Host -ForegroundColor Green "  [8] Netzwerk-Test (Ping, Jitter, Paketverlust)"
    Write-Host -ForegroundColor Green "  [9] Netzwerk optimieren"
    Write-Host -ForegroundColor Green "  [10] Netzwerk zuruecksetzen"
    Write-Host ""
    Write-Host -ForegroundColor Green "  [11] Windows entschlacken    [12] Entschlacken zuruecksetzen"
    Write-Host -ForegroundColor Green "  [13] Vorinstallierte Apps entfernen"
    Write-Host -ForegroundColor Green "  [14] Zwischenspeicher leeren  [15] FiveM komplett bereinigen"
    Write-Host ""
    Write-Host -ForegroundColor Green "  [0] Beenden"
    Write-Host ""
    $choice = Read-Host "Auswahl"
    switch ($choice) {
        "1" { Invoke-ApplyProfile; Read-Host "`nEnter druecken" | Out-Null }
        "2" { Invoke-Cleanup;      Read-Host "`nEnter druecken" | Out-Null }
        "3" { Invoke-Undo;         Read-Host "`nEnter druecken" | Out-Null }
        "4" { Show-Status;         Read-Host "`nEnter druecken" | Out-Null }
        "5" { Invoke-GtaLow;       Read-Host "`nEnter druecken" | Out-Null }
        "6" { Invoke-GtaRestore;   Read-Host "`nEnter druecken" | Out-Null }
        "7" { Invoke-SystemCheck;  Read-Host "`nEnter druecken" | Out-Null }
        "8" { Invoke-NetTest;      Read-Host "`nEnter druecken" | Out-Null }
        "9" { Invoke-NetTweaks;    Read-Host "`nEnter druecken" | Out-Null }
        "10" { Invoke-NetUndo;     Read-Host "`nEnter druecken" | Out-Null }
        "11" { Invoke-Debloat;          Read-Host "`nEnter druecken" | Out-Null }
        "12" { Invoke-DebloatUndo;      Read-Host "`nEnter druecken" | Out-Null }
        "13" { Invoke-RemoveBloatApps;  Read-Host "`nEnter druecken" | Out-Null }
        "14" { Invoke-DeepClean;        Read-Host "`nEnter druecken" | Out-Null }
        "15" { Invoke-FiveMDeepClean;   Read-Host "`nEnter druecken" | Out-Null }
    }
} while ($choice -ne "0")
