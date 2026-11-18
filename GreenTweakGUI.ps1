# ============================================================
#  GreenTweak - Oberflaeche (WPF)
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Fehler sichtbar machen statt still abzustuerzen
trap {
    $msg = "GreenTweak konnte nicht starten:`n`n" + $_.Exception.Message + "`n`nZeile: " + $_.InvocationInfo.ScriptLineNumber + " in " + $_.InvocationInfo.ScriptName
    try {
        $d = Join-Path $env:ProgramData "GreenTweak"
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        Add-Content -Path (Join-Path $d "fehler.txt") -Value ("[" + (Get-Date) + "] " + $msg + "`n" + $_.ScriptStackTrace + "`n")
    } catch {}
    try { [Windows.MessageBox]::Show($msg + "`n`nSchick davon einen Screenshot im Discord-Support.", "GreenTweak - Fehler", "OK", "Error") | Out-Null } catch { Write-Host $msg -ForegroundColor Red; Read-Host }
    exit
}

# Konsolenfenster-Steuerung (wird erst ausgeblendet, wenn das Fenster bereit ist)
try { Add-Type -Name Win -Namespace GT -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);' } catch {}

# Logik aus GreenTweak.ps1 laden (ohne Konsolen-Menue)
$AppDir = Split-Path -Parent $PSCommandPath
. (Join-Path $AppDir "GreenTweak.ps1") -NoMenu

$DiscordLink = "https://discord.gg/KMZKewWQTp"
$FpsChannelUrl = "https://discord.com/channels/1564392998060433498"

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="GreenTweak" Width="1180" Height="760" MinWidth="980" MinHeight="640"
        WindowStartupLocation="CenterScreen" Background="#070C08" FontFamily="Segoe UI">
  <Window.Resources>
    <SolidColorBrush x:Key="Green" Color="#39FF14"/>
    <SolidColorBrush x:Key="Card" Color="#0E1610"/>
    <SolidColorBrush x:Key="Line" Color="#1C2E20"/>
    <SolidColorBrush x:Key="Text" Color="#E3F5E5"/>
    <SolidColorBrush x:Key="Muted" Color="#7E9A83"/>

    <Style x:Key="Nav" TargetType="Button">
      <Setter Property="Foreground" Value="#CFE6D2"/>
      <Setter Property="FontSize" Value="15"/>
      <Setter Property="Height" Value="38"/>
      <Setter Property="Margin" Value="0,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="Transparent" CornerRadius="8" BorderThickness="1" BorderBrush="Transparent" Padding="14,0">
              <ContentPresenter VerticalAlignment="Center" HorizontalAlignment="Left"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#13221A"/>
              </Trigger>
              <Trigger Property="Tag" Value="active">
                <Setter TargetName="b" Property="Background" Value="#14301A"/>
                <Setter TargetName="b" Property="BorderBrush" Value="#39FF14"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Foreground" Value="#E3F5E5"/>
      <Setter Property="Background" Value="#16241A"/>
      <Setter Property="FontSize" Value="15"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Height" Value="46"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="9" BorderBrush="#24402B" BorderThickness="1">
              <ContentPresenter VerticalAlignment="Center" HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.85"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Primary" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="#1FB30E"/>
      <Setter Property="Foreground" Value="#03140A"/>
    </Style>
    <Style x:Key="Warn" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="#C9A227"/>
      <Setter Property="Foreground" Value="#1A1405"/>
    </Style>

    <Style x:Key="CardBorder" TargetType="Border">
      <Setter Property="Background" Value="#0E1610"/>
      <Setter Property="BorderBrush" Value="#1C2E20"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="12"/>
      <Setter Property="Padding" Value="18"/>
      <Setter Property="Margin" Value="0,0,12,12"/>
    </Style>
    <Style x:Key="H1" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#E3F5E5"/><Setter Property="FontSize" Value="26"/><Setter Property="FontWeight" Value="Bold"/>
    </Style>
    <Style x:Key="Sub" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#7E9A83"/><Setter Property="FontSize" Value="13"/><Setter Property="Margin" Value="0,2,0,16"/><Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="Big" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#39FF14"/><Setter Property="FontSize" Value="26"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Margin" Value="0,6,0,2"/>
    </Style>
    <Style x:Key="Small" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#7E9A83"/><Setter Property="FontSize" Value="12.5"/><Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="CardTitle" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#E3F5E5"/><Setter Property="FontSize" Value="17"/><Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="250"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <!-- Seitenleiste -->
    <Border Grid.Column="0" Background="#0A120C" BorderBrush="#1C2E20" BorderThickness="0,0,1,0">
      <DockPanel Margin="16,20,16,16">
        <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="4,0,0,4">
          <Image x:Name="Logo" Width="48" Height="48" Margin="0,0,10,0"/>
          <StackPanel VerticalAlignment="Center">
            <TextBlock Text="GREENTWEAK" Foreground="#39FF14" FontSize="21" FontWeight="Black"/>
            <TextBlock x:Name="VerText" Text="v2" Foreground="#7E9A83" FontSize="12"/>
          </StackPanel>
        </StackPanel>
        <TextBlock DockPanel.Dock="Top" Text="FPS-Tool für GTA &amp; FiveM" Foreground="#7E9A83" FontSize="12.5" Margin="4,4,0,18"/>

        <StackPanel DockPanel.Dock="Bottom">
          <Button x:Name="BtnDiscord" Style="{StaticResource Btn}" Content="Discord öffnen" Height="40"/>
        </StackPanel>

        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel>
          <TextBlock Text="ALLGEMEIN" Foreground="#4F6B55" FontSize="11" FontWeight="Bold" Margin="6,0,0,4"/>
          <Button x:Name="NavDash"   Style="{StaticResource Nav}" Content="Dashboard"/>
          <Button x:Name="NavCheck"  Style="{StaticResource Nav}" Content="Systemcheck"/>
          <Button x:Name="NavAuto"   Style="{StaticResource Nav}" Content="Autostart"/>
          <Button x:Name="NavProf"   Style="{StaticResource Nav}" Content="Profile"/>
          <Button x:Name="NavDebloat" Style="{StaticResource Nav}" Content="Windows entschlacken"/>
          <TextBlock Text="SPIELE" Foreground="#4F6B55" FontSize="11" FontWeight="Bold" Margin="6,14,0,4"/>
          <Button x:Name="NavFps"    Style="{StaticResource Nav}" Content="FPS-Test (neu)"/>
          <Button x:Name="NavFiveM"  Style="{StaticResource Nav}" Content="FiveM &amp; GTA"/>
          <Button x:Name="NavGames"  Style="{StaticResource Nav}" Content="Weitere Spiele"/>
          <Button x:Name="NavNet"    Style="{StaticResource Nav}" Content="Netzwerk"/>
          <Button x:Name="NavClean"  Style="{StaticResource Nav}" Content="Aufräumen"/>
          <TextBlock Text="SONSTIGES" Foreground="#4F6B55" FontSize="11" FontWeight="Bold" Margin="6,14,0,4"/>
          <Button x:Name="NavInfo"   Style="{StaticResource Nav}" Content="Info"/>
        </StackPanel></ScrollViewer>
      </DockPanel>
    </Border>

    <!-- Inhalt -->
    <Grid Grid.Column="1" Margin="28,22,16,16">
      <Grid.RowDefinitions>
        <RowDefinition Height="*"/>
        <RowDefinition Height="190"/>
      </Grid.RowDefinitions>

      <!-- Dashboard -->
      <StackPanel x:Name="PageDash" Grid.Row="0">
        <TextBlock Text="Dashboard" Style="{StaticResource H1}"/>
        <TextBlock Text="Übersicht &amp; Schnellaktionen" Style="{StaticResource Sub}"/>
        <UniformGrid Columns="4">
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Status" Style="{StaticResource Small}"/>
            <TextBlock x:Name="CardStatus" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="CardStatusSub" Text="" Style="{StaticResource Small}"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Arbeitsspeicher" Style="{StaticResource Small}"/>
            <TextBlock x:Name="CardRam" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="CardRamSub" Text="" Style="{StaticResource Small}"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Freier Speicher" Style="{StaticResource Small}"/>
            <TextBlock x:Name="CardDisk" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="CardDiskSub" Text="" Style="{StaticResource Small}"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Grafikkarte" Style="{StaticResource Small}"/>
            <TextBlock x:Name="CardGpu" Text="-" Style="{StaticResource Big}" FontSize="17" TextWrapping="Wrap"/>
            <TextBlock x:Name="CardGpuSub" Text="" Style="{StaticResource Small}"/>
          </StackPanel></Border>
        </UniformGrid>
        <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14" Margin="0,4,12,12">
          <DockPanel>
            <Button x:Name="AutoOpt" DockPanel.Dock="Right" Style="{StaticResource Primary}" Content="1-Klick-Optimierung starten" Width="280" VerticalAlignment="Center"/>
            <StackPanel Margin="0,0,16,0">
              <TextBlock Text="1-Klick-Optimierung (empfohlen)" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
              <TextBlock Text="GreenTweak erkennt deine Hardware (Grafikkarte, RAM, Laptop oder PC) und wählt automatisch die passenden Tweaks. Alles wird vorher gesichert." Style="{StaticResource Small}" Margin="0,6,0,0"/>
            </StackPanel>
          </DockPanel>
        </Border>
        <TextBlock Text="Schnellaktionen" Style="{StaticResource CardTitle}" Margin="0,8,0,10"/>
        <UniformGrid Columns="4">
          <Button x:Name="QuickMax"     Style="{StaticResource Primary}" Content="Max FPS anwenden"   Margin="0,0,12,0"/>
          <Button x:Name="QuickGame"    Style="{StaticResource Btn}"     Content="Gaming-Modus AN"    Margin="0,0,12,0"/>
          <Button x:Name="QuickUndo"    Style="{StaticResource Btn}"     Content="Alles rückgängig"   Margin="0,0,12,0"/>
          <Button x:Name="QuickRestart" Style="{StaticResource Warn}"    Content="PC neu starten"     Margin="0,0,12,0"/>
        </UniformGrid>
      </StackPanel>

      <!-- Systemcheck -->
      <StackPanel x:Name="PageCheck" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Systemcheck" Style="{StaticResource H1}"/>
        <TextBlock Text="Prüft RAM-Takt (XMP/EXPO), Grafiktreiber, Energieplan, Speicherplatz und Autostart und sagt dir, was du verbessern kannst." Style="{StaticResource Sub}"/>
        <Button x:Name="BtnCheck" Style="{StaticResource Primary}" Content="Systemcheck starten" Width="260" HorizontalAlignment="Left"/>
        <TextBlock Text="Das Ergebnis erscheint unten im Protokoll." Style="{StaticResource Small}" Margin="0,10,0,0"/>
      </StackPanel>

      <!-- Profile -->
      <StackPanel x:Name="PageProf" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Profile" Style="{StaticResource H1}"/>
        <TextBlock Text="Wähle, wie stark GreenTweak eingreifen soll. Alles wird vorher gesichert und ist mit 'Alles rückgängig' zurückzusetzen." Style="{StaticResource Sub}"/>
        <UniformGrid Columns="3">
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Leicht" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Energieplan Leistung, Spielmodus, Game DVR aus, GPU-Planung, Aufräumen." Style="{StaticResource Small}" Margin="0,8,0,16" Height="64"/>
            <Button x:Name="ProfLight" Style="{StaticResource Btn}" Content="Anwenden"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Gaming" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Leicht + Spiele-Priorität, FiveM &amp; GTA mit hoher Priorität und auf der starken Grafikkarte, Maus 1:1." Style="{StaticResource Small}" Margin="0,8,0,16" Height="64"/>
            <Button x:Name="ProfGaming" Style="{StaticResource Btn}" Content="Anwenden"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <TextBlock Text="Max FPS" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
            <TextBlock Text="Gaming + GTA/FiveM-Grafik auf FPS (Schatten, Partikel, Gras, Spiegelungen, Effekte)." Style="{StaticResource Small}" Margin="0,8,0,16" Height="64"/>
            <Button x:Name="ProfMax" Style="{StaticResource Primary}" Content="Anwenden"/>
          </StackPanel></Border>
        </UniformGrid>
        <Button x:Name="BtnUndo2" Style="{StaticResource Btn}" Content="Alles rückgängig machen" Width="260" HorizontalAlignment="Left" Margin="0,4,0,0"/>
      </StackPanel>

      <!-- FPS-Test -->
      <StackPanel x:Name="PageFps" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="FPS-Test" Style="{StaticResource H1}"/>
        <TextBlock Text="Misst deine echten FPS im Spiel, einmal ohne und einmal mit GreenTweak. So siehst du schwarz auf weiß, was es bei dir bringt." Style="{StaticResource Sub}"/>
        <UniformGrid Columns="3">
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <TextBlock Text="FPS messen" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
            <TextBlock Text="Spiel starten, hier klicken, ins Spiel wechseln. Nach 10 Sekunden wird 30 Sekunden lang gemessen." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="FpsMeasure" Style="{StaticResource Primary}" Content="Messung starten"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Ohne Tweak" Style="{StaticResource Small}"/>
            <TextBlock x:Name="FpsBefore" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="FpsBeforeSub" Text="Noch nicht gemessen" Style="{StaticResource Small}"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Letzte Messung" Style="{StaticResource Small}"/>
            <TextBlock x:Name="FpsLast" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="FpsLastSub" Text="Noch nicht gemessen" Style="{StaticResource Small}"/>
          </StackPanel></Border>
        </UniformGrid>
        <StackPanel Orientation="Horizontal" Margin="0,4,0,0">
          <Button x:Name="BgCheck" Style="{StaticResource Btn}" Content="Hintergrund-Check (FPS-Fresser finden)" Width="330" Margin="0,0,12,0"/>
          <Button x:Name="FpsHistory" Style="{StaticResource Btn}" Content="Verlauf anzeigen" Width="200" Margin="0,0,12,0"/>
          <Button x:Name="FpsShare" Style="{StaticResource Primary}" Content="Ergebnis im Discord teilen" Width="260"/>
        </StackPanel>
      </StackPanel>

      <!-- Autostart -->
      <Grid x:Name="PageAuto" Grid.Row="0" Visibility="Collapsed">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0">
          <TextBlock Text="Autostart" Style="{StaticResource H1}"/>
          <TextBlock Text="Programme, die mit Windows starten. Haken weg = startet nicht mehr von selbst. Wie im Task-Manager und jederzeit wieder einschaltbar. Wichtige Einträge (Sicherheit, Sound, Touchpad) sind gesperrt." Style="{StaticResource Sub}"/>
        </StackPanel>
        <Button Grid.Row="1" x:Name="AutoRefresh" Style="{StaticResource Btn}" Content="Liste neu laden" Width="200" Height="38" HorizontalAlignment="Left" Margin="0,0,0,10"/>
        <Border Grid.Row="2" Style="{StaticResource CardBorder}" Padding="12">
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="AutoList"/>
          </ScrollViewer>
        </Border>
      </Grid>

      <!-- FiveM -->
      <StackPanel x:Name="PageFiveM" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="FiveM &amp; GTA" Style="{StaticResource H1}"/>
        <TextBlock Text="Bitte GTA und FiveM vorher komplett schließen." Style="{StaticResource Sub}"/>
        <UniformGrid Columns="4">
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Grafik auf FPS" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Schatten, Partikel, Gras, Spiegelungen, Effekte und Unschärfe auf Minimum." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="GtaLow" Style="{StaticResource Primary}" Content="Anwenden"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Grafik zurücksetzen" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Stellt deine vorherigen GTA/FiveM-Grafikeinstellungen wieder her." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="GtaRestore" Style="{StaticResource Btn}" Content="Zurücksetzen"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="FiveM-Cache leeren" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Hilft, wenn FiveM plötzlich ruckelt oder lange lädt." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="FiveMClean" Style="{StaticResource Btn}" Content="Cache leeren"/>
          </StackPanel></Border>
        <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="FiveM komplett" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Cache, Server-Cache, Logs und Absturzberichte. Einstellungen bleiben." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="FiveMDeep" Style="{StaticResource Btn}" Content="Bereinigen"/>
          </StackPanel></Border>
        </UniformGrid>
      </StackPanel>

      <!-- Entschlacken -->
      <StackPanel x:Name="PageDebloat" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Windows entschlacken" Style="{StaticResource H1}"/>
        <TextBlock Text="Nur was beim Spielen nichts tut. Windows Update, Defender, Suche, Xbox/Game Bar und Store bleiben unangetastet." Style="{StaticResource Sub}"/>
        <UniformGrid Columns="3">
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <TextBlock Text="Telemetrie &amp; Dienste" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
            <TextBlock Text="Telemetrie auf Minimum, Werbung und Vorschläge aus, unnötige Dienste aus. Mit Sicherung." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="Debloat" Style="{StaticResource Primary}" Content="Entschlacken"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Vorinstallierte Apps" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="News, Wetter, Solitaire, Cortana, Clipchamp und Co. entfernen. Im Store wieder installierbar." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="BloatApps" Style="{StaticResource Btn}" Content="Apps entfernen"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Zwischenspeicher" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Temp, Fehlerberichte, Windows-Update-Downloads und DNS-Cache leeren." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="DeepClean" Style="{StaticResource Btn}" Content="Leeren"/>
          </StackPanel></Border>
        </UniformGrid>
        <Button x:Name="DebloatUndo" Style="{StaticResource Btn}" Content="Entschlacken zurücksetzen" Width="260" HorizontalAlignment="Left" Margin="0,4,0,0"/>
      </StackPanel>

      <!-- Weitere Spiele -->
      <StackPanel x:Name="PageGames" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Weitere Spiele" Style="{StaticResource H1}"/>
        <TextBlock Text="Lässt das Spiel immer auf der starken Grafikkarte laufen. Anti-Cheat-sicher: es wird nichts am Spiel selbst verändert." Style="{StaticResource Sub}"/>
        <UniformGrid Columns="3">
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Fortnite" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Grafikkarte Höchstleistung" Style="{StaticResource Small}" Margin="0,8,0,16"/>
            <Button x:Name="GameFortnite" Style="{StaticResource Btn}" Content="Anwenden"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Valorant" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Grafikkarte Höchstleistung" Style="{StaticResource Small}" Margin="0,8,0,16"/>
            <Button x:Name="GameValorant" Style="{StaticResource Btn}" Content="Anwenden"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Counter-Strike 2" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Grafikkarte Höchstleistung" Style="{StaticResource Small}" Margin="0,8,0,16"/>
            <Button x:Name="GameCS2" Style="{StaticResource Btn}" Content="Anwenden"/>
          </StackPanel></Border>
        </UniformGrid>
        <Button x:Name="GamesUndo" Style="{StaticResource Btn}" Content="Spielprofile zurücksetzen" Width="260" HorizontalAlignment="Left" Margin="0,4,0,0"/>
      </StackPanel>

      <!-- Netzwerk -->
      <StackPanel x:Name="PageNet" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Netzwerk" Style="{StaticResource H1}"/>
        <TextBlock Text="Weniger Verzögerung auf deinem PC und eine ehrliche Messung deiner Verbindung. Den Ping zum Server bestimmen vor allem Serverstandort, Anbieter und Kabel statt WLAN." Style="{StaticResource Sub}"/>
        <UniformGrid Columns="3">
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Netzwerk-Test" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Prüft WLAN oder Kabel und misst Ping, Jitter und Paketverlust." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="NetTest" Style="{StaticResource Btn}" Content="Test starten"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <TextBlock Text="Netzwerk optimieren" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
            <TextBlock Text="Nagle aus, sofortige Paket-Bestätigung, Energiesparen am Netzwerkadapter aus, DNS-Cache leeren." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="NetTweak" Style="{StaticResource Primary}" Content="Optimieren"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Zurücksetzen" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Stellt deine vorherigen Netzwerk-Einstellungen wieder her." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="NetUndo" Style="{StaticResource Btn}" Content="Zurücksetzen"/>
          </StackPanel></Border>
        </UniformGrid>
      </StackPanel>

      <!-- Aufraeumen -->
      <StackPanel x:Name="PageClean" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Aufräumen" Style="{StaticResource H1}"/>
        <TextBlock Text="Löscht temporäre Dateien von Windows und den FiveM-Cache." Style="{StaticResource Sub}"/>
        <Button x:Name="BtnClean" Style="{StaticResource Primary}" Content="Jetzt aufräumen" Width="260" HorizontalAlignment="Left"/>
      </StackPanel>

      <!-- Info -->
      <StackPanel x:Name="PageInfo" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Info" Style="{StaticResource H1}"/>
        <TextBlock Text="GreenTweak von der Green Community. Updates kommen automatisch beim Start." Style="{StaticResource Sub}"/>
        <Border Style="{StaticResource CardBorder}" HorizontalAlignment="Left" Width="520"><StackPanel>
          <TextBlock x:Name="InfoText" Style="{StaticResource Small}" FontSize="14" Foreground="#CFE6D2"/>
        </StackPanel></Border>
        <Button x:Name="BtnStatus" Style="{StaticResource Btn}" Content="Aktive Tweaks anzeigen" Width="260" HorizontalAlignment="Left"/>
      </StackPanel>

      <!-- Protokoll -->
      <Border Grid.Row="1" Background="#050906" BorderBrush="#1C2E20" BorderThickness="1" CornerRadius="10" Margin="0,8,12,0">
        <DockPanel>
          <TextBlock DockPanel.Dock="Top" Text="Protokoll" Foreground="#7E9A83" FontSize="12" Margin="12,8,0,0"/>
          <TextBox x:Name="LogBox" Background="Transparent" Foreground="#39FF14" BorderThickness="0" IsReadOnly="True"
                   FontFamily="Consolas" FontSize="12.5" Margin="8,4,8,8" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"/>
        </DockPanel>
      </Border>
    </Grid>
  </Grid>
</Window>
"@

$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
function C($n) { $win.FindName($n) }

# Logo
$ico = Join-Path $AppDir "GreenTweak.ico"
if (Test-Path $ico) {
    $win.Icon = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]$ico)
    (C "Logo").Source = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]$ico)
}
(C "VerText").Text = "Version $Version"

# --- Protokoll statt Konsole ---
$LogBox = C "LogBox"
function Update-UI { $win.Dispatcher.Invoke([action]{}, [Windows.Threading.DispatcherPriority]::Background) }
function Log($text, $color = "DarkGreen") {
    $LogBox.AppendText(($text -replace "^`n", "`r`n") + "`r`n")
    $LogBox.ScrollToEnd()
    Add-Content -Path $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $text)
    Update-UI
}

# --- Seiten-Navigation ---
$pages = @{ NavDash="PageDash"; NavCheck="PageCheck"; NavFps="PageFps"; NavAuto="PageAuto"; NavProf="PageProf"; NavFiveM="PageFiveM"; NavNet="PageNet"; NavDebloat="PageDebloat"; NavGames="PageGames"; NavClean="PageClean"; NavInfo="PageInfo" }
function Show-Page($nav) {
    foreach ($k in $pages.Keys) {
        (C $pages[$k]).Visibility = if ($k -eq $nav) { "Visible" } else { "Collapsed" }
        (C $k).Tag = if ($k -eq $nav) { "active" } else { $null }
    }
    if ($nav -eq "NavDash") { Update-Dashboard }
    if ($nav -eq "NavFps")  { Update-FpsCards }
    if ($nav -eq "NavAuto") { Fill-AutoList }
}
foreach ($k in @($pages.Keys)) { (C $k).Add_Click({ Show-Page $this.Name }) }

# --- Dashboard-Daten ---
function Update-Dashboard {
    if (Test-Path $BackupFile) {
        $b = Get-Content $BackupFile -Raw | ConvertFrom-Json
        (C "CardStatus").Text = "AKTIV"
        (C "CardStatusSub").Text = "Profil: " + $(if ($b.Profile) { $b.Profile } else { "Gaming" })
    } else {
        (C "CardStatus").Text = "Inaktiv"
        (C "CardStatusSub").Text = "Noch kein Profil angewendet"
    }
    try {
        $mem = @(Get-CimInstance Win32_PhysicalMemory)
        $gb = [math]::Round(($mem | Measure-Object Capacity -Sum).Sum / 1GB)
        $cur = ($mem | Measure-Object ConfiguredClockSpeed -Minimum).Minimum
        $type = switch ($mem[0].SMBIOSMemoryType) { 26 { "DDR4" } 34 { "DDR5" } default { "RAM" } }
        (C "CardRam").Text = "$gb GB"
        $xmpOff = ($type -eq "DDR4" -and $cur -le 2666) -or ($type -eq "DDR5" -and $cur -le 4800)
        (C "CardRamSub").Text = "$type, $cur MT/s" + $(if ($xmpOff) { " - XMP aus?" } else { "" })
    } catch {}
    try {
        $d = Get-PSDrive -Name ($env:SystemDrive.TrimEnd(':'))
        (C "CardDisk").Text = ("{0} GB" -f [math]::Round($d.Free / 1GB))
        (C "CardDiskSub").Text = "frei auf $env:SystemDrive"
    } catch {}
    try {
        $all = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Microsoft|Basic|Virtual|Parsec|Remote|Meta" })
        $g = $all | Where-Object { $_.Name -match "NVIDIA|GeForce|Quadro|Radeon RX|Radeon Pro|Arc\(TM\) [AB]\d|Arc [AB]\d" } | Select-Object -First 1
        if (-not $g) { $g = $all | Select-Object -First 1 }
        (C "CardGpu").Text = ($g.Name -replace "NVIDIA GeForce |AMD Radeon ", "")
        $age = [int]((Get-Date) - $g.DriverDate).TotalDays
        (C "CardGpuSub").Text = "Treiber $age Tage alt"
    } catch {}
}

# --- Gaming-Modus-Button ---
function Update-GameModeButton {
    $b = C "QuickGame"
    if (Test-GameMode) { $b.Content = "Gaming-Modus AUS"; $b.Background = $Bc.ConvertFromString("#1FB30E"); $b.Foreground = $Bc.ConvertFromString("#03140A") }
    else { $b.Content = "Gaming-Modus AN"; $b.Background = $Bc.ConvertFromString("#16241A"); $b.Foreground = $Bc.ConvertFromString("#E3F5E5") }
}

# --- Aktionen ---
function Run($block) {
    $win.Cursor = [Windows.Input.Cursors]::Wait
    try { & $block } catch { Log ("  [X] Fehler: " + $_.Exception.Message) }
    $win.Cursor = $null
    Update-Dashboard
    Update-GameModeButton
}
(C "QuickMax").Add_Click({ Run { Invoke-ApplyProfile "Max FPS" } })
(C "ProfLight").Add_Click({ Run { Invoke-ApplyProfile "Leicht" } })
(C "ProfGaming").Add_Click({ Run { Invoke-ApplyProfile "Gaming" } })
(C "ProfMax").Add_Click({ Run { Invoke-ApplyProfile "Max FPS" } })
(C "QuickUndo").Add_Click({ Run { Invoke-Undo } })
(C "BtnUndo2").Add_Click({ Run { Invoke-Undo } })
(C "BtnCheck").Add_Click({ Run { Invoke-SystemCheck } })
(C "GtaLow").Add_Click({ Run { Invoke-GtaLow } })
(C "GtaRestore").Add_Click({ Run { Invoke-GtaRestore } })
(C "FiveMClean").Add_Click({ Run {
    Log "`n== FiveM-Cache leeren =="
    if (Get-Process -Name "FiveM*" -ErrorAction SilentlyContinue) { Warn "FiveM laeuft noch - bitte erst schliessen." }
    else { Remove-FolderContent (Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\data\cache") "FiveM-Cache" }
} })
(C "NetTest").Add_Click({ Run { Invoke-NetTest } })
(C "NetTweak").Add_Click({
    $r = [Windows.MessageBox]::Show("Netzwerk optimieren?`nDas Internet ist danach fuer ein paar Sekunden weg (Adapter-Neustart).", "GreenTweak", "YesNo", "Question")
    if ($r -eq "Yes") { Run { Invoke-NetTweaks } }
})
(C "NetUndo").Add_Click({ Run { Invoke-NetUndo } })
(C "Debloat").Add_Click({
    $r = [Windows.MessageBox]::Show("Telemetrie, Werbung und unnoetige Dienste abschalten?`nAlles wird gesichert und ist zuruecksetzbar.", "GreenTweak", "YesNo", "Question")
    if ($r -eq "Yes") { Run { Invoke-Debloat } }
})
(C "DebloatUndo").Add_Click({ Run { Invoke-DebloatUndo } })
(C "BloatApps").Add_Click({
    $list = @(Get-BloatAppsInstalled | ForEach-Object { $_.Name })
    if ($list.Count -eq 0) { Run { Invoke-RemoveBloatApps }; return }
    $r = [Windows.MessageBox]::Show("Diese Apps werden entfernt:`n`n" + ($list -join ", ") + "`n`nDu kannst sie jederzeit im Microsoft Store neu installieren. Fortfahren?", "GreenTweak", "YesNo", "Question")
    if ($r -eq "Yes") { Run { Invoke-RemoveBloatApps } }
})
(C "DeepClean").Add_Click({ Run { Invoke-DeepClean } })
(C "FiveMDeep").Add_Click({ Run { Invoke-FiveMDeepClean } })
(C "GameFortnite").Add_Click({ Run { Invoke-GameProfile "Fortnite" } })
(C "GameValorant").Add_Click({ Run { Invoke-GameProfile "Valorant" } })
(C "GameCS2").Add_Click({ Run { Invoke-GameProfile "CS2" } })
(C "GamesUndo").Add_Click({ Run { Invoke-GameProfilesUndo } })
(C "BtnClean").Add_Click({ Run { Invoke-Cleanup } })
(C "BtnStatus").Add_Click({ Run { Show-Status } })
(C "QuickRestart").Add_Click({
    $r = [Windows.MessageBox]::Show("PC jetzt neu starten? Speichere vorher alles!", "GreenTweak", "YesNo", "Question")
    if ($r -eq "Yes") { Restart-Computer -Force }
})
(C "BtnDiscord").Add_Click({ Start-Process $DiscordLink })

# --- FPS-Test ---
function Update-FpsCards {
    try {
        $h = @(Get-FpsHistory)
        $before = $h | Where-Object { -not $_.Tweak } | Select-Object -First 1
        $last   = $h | Select-Object -Last 1
        if ($before) {
            (C "FpsBefore").Text = "$($before.Avg) FPS"
            (C "FpsBeforeSub").Text = "1% Low: $($before.Low1) FPS | $($before.Date)"
        }
        if ($last) {
            (C "FpsLast").Text = "$($last.Avg) FPS"
            $sub = "1% Low: $($last.Low1) FPS | $($last.Date)"
            if ($last.Tweak -and $before -and $before.Avg -gt 0) {
                $pct = [math]::Round(($last.Avg - $before.Avg) / $before.Avg * 100)
                $sub += " | " + $(if ($pct -ge 0) { "+" } else { "" }) + "$pct %"
            }
            (C "FpsLastSub").Text = $sub
        }
    } catch {}
}
(C "FpsMeasure").Add_Click({ Run { Invoke-FpsMeasure | Out-Null; Update-FpsCards } })
(C "BgCheck").Add_Click({ Run { Invoke-BackgroundCheck } })
(C "FpsHistory").Add_Click({ Run {
    Log "`n== FPS-Verlauf =="
    $h = @(Get-FpsHistory)
    if ($h.Count -eq 0) { Log "  Noch keine Messungen." }
    foreach ($e in ($h | Select-Object -Last 10)) {
        Log ("  {0}  {1,-24} {2,4} FPS  (1% Low {3})  {4}" -f $e.Date, $e.Game, $e.Avg, $e.Low1, $(if ($e.Tweak) { "mit Tweak" } else { "ohne Tweak" }))
    }
} })

# --- Autostart ---
$Bc = New-Object Windows.Media.BrushConverter
function Fill-AutoList {
    $list = C "AutoList"
    $list.Children.Clear()
    $items = @()
    try { $items = @(Get-StartupItems) } catch { Log ("  [X] Autostart konnte nicht gelesen werden: " + $_.Exception.Message); return }
    if ($items.Count -eq 0) {
        $t = New-Object Windows.Controls.TextBlock
        $t.Text = "Keine Autostart-Einträge gefunden."
        $t.Foreground = $Bc.ConvertFromString("#7E9A83")
        $list.Children.Add($t) | Out-Null
        return
    }
    foreach ($it in $items) {
        $cb = New-Object Windows.Controls.CheckBox
        $cb.IsChecked = [bool]$it.Enabled
        $cb.IsEnabled = -not $it.Protected
        $cb.Margin = New-Object Windows.Thickness(0, 5, 0, 5)
        $cb.VerticalContentAlignment = "Center"
        $sp = New-Object Windows.Controls.StackPanel
        $sp.Margin = New-Object Windows.Thickness(8, 0, 0, 0)
        $t1 = New-Object Windows.Controls.TextBlock
        $t1.Text = $it.Name + $(if ($it.Protected) { "  (gesperrt, wichtig)" } else { "" })
        $t1.FontSize = 14
        $t1.Foreground = $Bc.ConvertFromString("#E3F5E5")
        $t2 = New-Object Windows.Controls.TextBlock
        $t2.Text = $it.Cmd
        $t2.FontSize = 11.5
        $t2.MaxWidth = 760
        $t2.TextTrimming = "CharacterEllipsis"
        $t2.Foreground = $Bc.ConvertFromString("#7E9A83")
        $sp.Children.Add($t1) | Out-Null
        $sp.Children.Add($t2) | Out-Null
        $cb.Content = $sp
        $cb.Tag = $it
        $cb.Add_Click({
            try { Set-StartupItem $this.Tag ([bool]$this.IsChecked) }
            catch { Log ("  [X] Fehler: " + $_.Exception.Message) }
        })
        $list.Children.Add($cb) | Out-Null
    }
    $on = @($items | Where-Object { $_.Enabled }).Count
    Log ("  Autostart: " + $items.Count + " Einträge, davon " + $on + " aktiv.")
}
(C "AutoRefresh").Add_Click({ Fill-AutoList })

# --- 1-Klick-Optimierung ---
(C "AutoOpt").Add_Click({
    $win.Cursor = [Windows.Input.Cursors]::Wait
    $hw = Get-HardwareInfo
    $plan = Get-AutoPlan $hw
    $win.Cursor = $null
    $gpuTxt = $hw.Gpu + $(if ($hw.Dedicated) { " (eigene Grafikkarte)" } else { " (im Prozessor)" })
    $pcTxt = if ($hw.Laptop) { "Laptop" } else { "Desktop-PC" }
    $steps = ($plan.Steps | ForEach-Object { "- " + $_ }) -join "`n"
    $msg = "Erkannt:`n- Grafikkarte: $gpuTxt`n- RAM: $($hw.RamGB) GB $($hw.RamType)`n- $pcTxt`n`nGreenTweak macht jetzt:`n$steps`n`nAlles wird vorher gesichert und ist mit 'Alles rückgängig' zurückzusetzen. Starten?"
    $r = [Windows.MessageBox]::Show($msg, "GreenTweak - 1-Klick-Optimierung", "YesNo", "Question")
    if ($r -ne "Yes") { return }
    Run { Invoke-AutoOptimize }
    $r2 = [Windows.MessageBox]::Show("Fertig! Damit alles wirkt, muss der PC neu starten.`n`nJetzt neu starten? (Vorher alles speichern!)", "GreenTweak", "YesNo", "Question")
    if ($r2 -eq "Yes") { Restart-Computer -Force }
})


# --- Gaming-Modus ---
(C "QuickGame").Add_Click({
    if (Test-GameMode) { Run { Invoke-GameModeOff }; return }
    $t = @(Get-GameModeTargets | ForEach-Object { $_.ProcessName })
    $msg = "Gaming-Modus einschalten?`n`n- Energieplan auf Höchstleistung`n- Windows-Benachrichtigungen pausieren"
    if ($t.Count -gt 0) { $msg += "`n- Diese Programme schließen: " + ($t -join ", ") }
    $msg += "`n`nNach dem Zocken einfach wieder auf 'Gaming-Modus AUS' klicken."
    $r = [Windows.MessageBox]::Show($msg, "GreenTweak", "YesNo", "Question")
    if ($r -eq "Yes") { Run { Invoke-GameModeOn } }
})

# --- FPS-Ergebnis teilen ---
(C "FpsShare").Add_Click({
    $h = @(Get-FpsHistory)
    if ($h.Count -eq 0) { [Windows.MessageBox]::Show("Mach zuerst eine FPS-Messung.", "GreenTweak") | Out-Null; return }
    $last = $h | Select-Object -Last 1
    $before = $h | Where-Object { -not $_.Tweak -and $_.Game -eq $last.Game } | Select-Object -First 1
    $game = ($last.Game -replace "FiveM_b\d+_GTAProcess|FiveM_GTAProcess", "FiveM" -replace "-Win64-Shipping|Client", "")
    $txt = "**GreenTweak FPS-Test** ($game)`n"
    if ($last.Tweak -and $before -and $before.Avg -gt 0) {
        $pct = [math]::Round(($last.Avg - $before.Avg) / $before.Avg * 100)
        $txt += "Ohne Tweak: $($before.Avg) FPS -> Mit Tweak: $($last.Avg) FPS (" + $(if ($pct -ge 0) { "+" } else { "" }) + "$pct %)`n"
        $txt += "1% Low: $($before.Low1) -> $($last.Low1) FPS"
    } else {
        $txt += "$($last.Avg) FPS im Schnitt, 1% Low: $($last.Low1) FPS"
    }
    [Windows.Clipboard]::SetText($txt)
    [Windows.MessageBox]::Show("Dein Ergebnis ist kopiert:`n`n$txt`n`nDiscord öffnet sich jetzt. Einfach im Kanal mit Strg + V einfügen und senden.", "GreenTweak") | Out-Null
    Start-Process $FpsChannelUrl
})


# --- Neu in dieser Version ---
$win.Add_ContentRendered({
    try {
        $seenFile = Join-Path $BackupDir "version_seen.txt"
        $seen = if (Test-Path $seenFile) { (Get-Content $seenFile -Raw).Trim() } else { "" }
        if ($seen -ne $Version) {
            Set-Content -Path $seenFile -Value $Version
            $txt = "Neu in GreenTweak $($Version):`n`n" +
                   "- FPS-Test: Miss deine echten FPS ohne und mit Tweak`n" +
                   "- Autostart: Programme per Haken vom Windows-Start abhalten`n" +
                   "- Hintergrund-Check: Findet FPS-Fresser wie Browser, OBS und Co.`n" +
                   "- Wiederherstellungspunkt jetzt auch vor dem Entschlacken`n`n" +
                   "Viel Spaß! - Green Community"
            [Windows.MessageBox]::Show($txt, "GreenTweak - Update", "OK", "Information") | Out-Null
        }
    } catch {}
})


(C "InfoText").Text = "Version: $Version`nSicherung und Protokoll: $BackupDir`nDiscord: $DiscordLink`n`nAlle Änderungen werden vorher gesichert. Mit 'Alles rückgängig' ist dein PC wieder wie vorher."

Show-Page "NavDash"
Update-GameModeButton
Log "GreenTweak v$Version bereit. Tipp: Starte zuerst den Systemcheck."
try { [GT.Win]::ShowWindow([GT.Win]::GetConsoleWindow(), 0) | Out-Null } catch {}
[void]$win.ShowDialog()
