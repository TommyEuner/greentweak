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
          <TextBlock x:Name="UserText" Text="" Foreground="#7E9A83" FontSize="12" Margin="4,0,0,8" TextWrapping="Wrap"/>
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
          <Button x:Name="NavFps"    Style="{StaticResource Nav}" Content="FPS-Test"/>
          <Button x:Name="NavTurbo"  Style="{StaticResource Nav}" Content="Turbo"/>
          <Button x:Name="NavLive"   Style="{StaticResource Nav}" Content="Leistung (neu)"/>
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
        <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14" Margin="0,16,12,0"><StackPanel>
          <TextBlock Text="FPS-Rangliste (neu)" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
          <TextBlock Text="Lade deine letzte Messung hoch und vergleiche dich mit den anderen Boostern. Es zählt dein bester Wert pro Spiel." Style="{StaticResource Small}" Margin="0,8,0,14" TextWrapping="Wrap"/>
          <StackPanel Orientation="Horizontal">
            <Button x:Name="FpsUpload" Style="{StaticResource Primary}" Content="In Rangliste hochladen" Width="260" Margin="0,0,12,0"/>
            <Button x:Name="FpsBoard" Style="{StaticResource Btn}" Content="Rangliste ansehen" Width="200" Margin="0,0,12,0"/>
            <Button x:Name="FpsImage" Style="{StaticResource Btn}" Content="Vorher/Nachher-Bild" Width="210"/>
          </StackPanel>
        </StackPanel></Border>
      </StackPanel>

      <!-- Turbo -->
      <StackPanel x:Name="PageTurbo" Grid.Row="0" Visibility="Collapsed">
        <TextBlock Text="Turbo" Style="{StaticResource H1}"/>
        <TextBlock Text="Zusätzliche Einstellungen für mehr FPS und ruhigere Frametimes. Alles wird gesichert und ist mit einem Klick wieder rückgängig." Style="{StaticResource Sub}"/>
        <Border Style="{StaticResource CardBorder}" Margin="0,0,12,12"><StackPanel>
          <TextBlock Text="Das macht Turbo" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
          <TextBlock Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,0" Text="• Optimierungen für Spiele im Fenstermodus an (besser für FiveM im randlosen Fenster)&#10;• Vollbildoptimierung für GTA und FiveM aus (stabilere Frametimes)&#10;• Windows-Effekte auf Leistung: Animationen, Transparenz und Schatten aus"/>
        </StackPanel></Border>
        <Border Style="{StaticResource CardBorder}" BorderBrush="#FFB347" Margin="0,0,12,12"><StackPanel>
          <CheckBox x:Name="TurboHvci" Foreground="#FFB347" FontSize="14" FontWeight="Bold" Content="Speicher-Integrität ausschalten (bringt am meisten)"/>
          <TextBlock x:Name="TurboHvciInfo" Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,0"/>
        </StackPanel></Border>
        <StackPanel Orientation="Horizontal">
          <Button x:Name="TurboOn" Style="{StaticResource Primary}" Content="Turbo einschalten" Width="260" Margin="0,0,12,0"/>
          <Button x:Name="TurboOff" Style="{StaticResource Btn}" Content="Turbo ausschalten" Width="220"/>
        </StackPanel>
        <TextBlock x:Name="TurboState" Style="{StaticResource Small}" Margin="0,12,0,0"/>
      </StackPanel>

      <!-- Leistung (v3.2) -->
      <ScrollViewer x:Name="PageLive" Grid.Row="0" Visibility="Collapsed" VerticalScrollBarVisibility="Auto"><StackPanel>
        <TextBlock Text="Leistung" Style="{StaticResource H1}"/>
        <TextBlock Text="Live-Temperaturen, dein FPS-Verlauf und Extras für mehr Leistung. Die Werte aktualisieren sich alle paar Sekunden." Style="{StaticResource Sub}"/>
        <UniformGrid Columns="3">
          <Border x:Name="LiveGpuCard" Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Grafikkarte" Style="{StaticResource Small}"/>
            <TextBlock x:Name="LiveGpu" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="LiveGpuSub" Text="Wird gelesen..." Style="{StaticResource Small}"/>
          </StackPanel></Border>
          <Border x:Name="LiveCpuCard" Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Prozessor" Style="{StaticResource Small}"/>
            <TextBlock x:Name="LiveCpu" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="LiveCpuSub" Text="Wird gelesen..." Style="{StaticResource Small}"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Zustand" Style="{StaticResource Small}"/>
            <TextBlock x:Name="LiveState" Text="-" Style="{StaticResource Big}"/>
            <TextBlock x:Name="LiveStateSub" Text="" Style="{StaticResource Small}"/>
          </StackPanel></Border>
        </UniformGrid>
        <Border Style="{StaticResource CardBorder}"><StackPanel>
          <DockPanel>
            <TextBlock Text="FPS-Verlauf" Style="{StaticResource CardTitle}" Foreground="#39FF14"/>
            <TextBlock DockPanel.Dock="Right" HorizontalAlignment="Right" Style="{StaticResource Small}" VerticalAlignment="Center">
              <Run Text="━ Durchschnitt" Foreground="#39FF14"/><Run Text="   ━ 1% Low" Foreground="#FFB347"/><Run Text="   ● ohne Tweak" Foreground="#E3F5E5"/>
            </TextBlock>
          </DockPanel>
          <Canvas x:Name="FpsChart" Height="150" Margin="0,12,0,0" ClipToBounds="True"/>
        </StackPanel></Border>
        <UniformGrid Columns="3">
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <CheckBox x:Name="AutoGameBox" Foreground="#39FF14" FontSize="15" FontWeight="Bold" Content="Auto-Gaming-Modus"/>
            <TextBlock Style="{StaticResource Small}" Margin="0,8,0,0" Text="Startest du FiveM oder GTA, geht der Gaming-Modus von selbst an. Schließt du das Spiel, ist alles wieder wie vorher. Läuft unsichtbar im Hintergrund."/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <CheckBox x:Name="ECoreBox" Foreground="#39FF14" FontSize="15" FontWeight="Bold" Content="E-Kern-Modus"/>
            <TextBlock Style="{StaticResource Small}" Margin="0,8,0,0" Text="FiveM und GTA laufen nur auf den starken Kernen deines Prozessors. Discord, OBS und Windows bekommen die Sparkerne. Für Intel ab 12. Generation (z. B. i5/i7-12xxx, 13xxx, 14xxx)."/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Grafikkarten-Einstellungen" Style="{StaticResource CardTitle}"/>
            <TextBlock x:Name="NvidiaInfo" Style="{StaticResource Small}" Margin="0,8,0,12" Text="Niedrige Latenz und maximale Leistung im Treiber einstellen."/>
            <Button x:Name="NvidiaGuide" Style="{StaticResource Primary}" Content="Anleitung + Treiber öffnen" Width="260" HorizontalAlignment="Left"/>
          </StackPanel></Border>
        </UniformGrid>
        <UniformGrid Columns="2">
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <TextBlock Text="Engpass prüfen" Style="{StaticResource CardTitle}"/>
            <TextBlock Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,12" Text="FiveM starten, an eine typische Stelle gehen, dann hier drücken. GreenTweak misst 15 Sekunden, ob Grafikkarte oder Prozessor bremst."/>
            <DockPanel>
              <Button x:Name="Bottleneck" Style="{StaticResource Primary}" Content="Jetzt messen" Width="170" DockPanel.Dock="Left"/>
              <TextBlock x:Name="EngpassText" Foreground="#39FF14" FontSize="15" FontWeight="Bold" VerticalAlignment="Center" Margin="14,0,0,0" TextWrapping="Wrap" Text=""/>
            </DockPanel>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="NVIDIA-Profil automatisch" Style="{StaticResource CardTitle}"/>
            <TextBlock Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,12" Text="Eigenes Treiber-Profil nur für FiveM/GTA: maximale Leistung, niedrige Latenz (Ultra), 10 GB Shader-Cache. Andere Spiele bleiben unverändert."/>
            <UniformGrid Columns="2">
              <Button x:Name="NvProfile" Style="{StaticResource Primary}" Content="Einstellen" Margin="0,0,4,0"/>
              <Button x:Name="NvUndo" Style="{StaticResource Btn}" Content="Zurücksetzen" Margin="4,0,0,0"/>
            </UniformGrid>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <CheckBox x:Name="MemBox" Foreground="#39FF14" FontSize="15" FontWeight="Bold" Content="RAM-Freiräumer"/>
            <TextBlock Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,0" Text="Leert während FiveM läuft automatisch den Standby-Speicher, wenn der freie RAM knapp wird. Hilft gegen Ruckler bei langen Sessions."/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <CheckBox x:Name="TimerBox" Foreground="#39FF14" FontSize="15" FontWeight="Bold" Content="Timer-Auflösung (Windows 11)"/>
            <TextBlock Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,0" Text="Spiele bekommen wieder den genauen Windows-Timer. Gleichmäßigere Frames und bessere 1%-Lows. Braucht einen Neustart."/>
          </StackPanel></Border>
        </UniformGrid>
      </StackPanel></ScrollViewer>

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
          <Border Style="{StaticResource CardBorder}" BorderBrush="#39FF14"><StackPanel>
            <TextBlock Text="FiveM starten" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Gaming-Modus an, RAM freiräumen und FiveM starten – alles mit einem Klick." Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="FiveMStart" Style="{StaticResource Primary}" Content="FiveM starten"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Shader-Cache leeren" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Hilft gegen Ruckler nach Treiber-Updates. Erster Start danach kann kurz ruckeln." Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="ShaderClean" Style="{StaticResource Btn}" Content="Cache leeren"/>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Vollbild-Optimierung" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Schaltet die Windows-Vollbild-Optimierung für FiveM/GTA aus. Etwas weniger Input-Lag." Style="{StaticResource Small}" TextWrapping="Wrap" Margin="0,8,0,16" Height="48"/>
            <UniformGrid Columns="2">
              <Button x:Name="FsoOff" Style="{StaticResource Primary}" Content="Aus" Margin="0,0,4,0"/>
              <Button x:Name="FsoUndo" Style="{StaticResource Btn}" Content="Zurück" Margin="4,0,0,0"/>
            </UniformGrid>
          </StackPanel></Border>
          <Border Style="{StaticResource CardBorder}"><StackPanel>
            <TextBlock Text="Ultra-FPS (Potato)" Style="{StaticResource CardTitle}"/>
            <TextBlock Text="Maximale FPS: zusätzlich Sichtweite, Details, Kantenglättung, Wasser, Shader und VSync runter. Texturen bleiben." Style="{StaticResource Small}" Margin="0,8,0,16" Height="48"/>
            <Button x:Name="GtaUltra" Style="{StaticResource Primary}" Content="Anwenden"/>
          </StackPanel></Border>
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
        <Button x:Name="BtnLogout" Style="{StaticResource Btn}" Content="Abmelden" Width="260" HorizontalAlignment="Left" Margin="0,10,0,0"/>
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
$pages = @{ NavDash="PageDash"; NavCheck="PageCheck"; NavFps="PageFps"; NavTurbo="PageTurbo"; NavLive="PageLive"; NavAuto="PageAuto"; NavProf="PageProf"; NavFiveM="PageFiveM"; NavNet="PageNet"; NavDebloat="PageDebloat"; NavGames="PageGames"; NavClean="PageClean"; NavInfo="PageInfo" }
function Show-Page($nav) {
    foreach ($k in $pages.Keys) {
        (C $pages[$k]).Visibility = if ($k -eq $nav) { "Visible" } else { "Collapsed" }
        (C $k).Tag = if ($k -eq $nav) { "active" } else { $null }
    }
    if ($nav -eq "NavDash") { Update-Dashboard }
    if ($nav -eq "NavFps")  { Update-FpsCards }
    if ($nav -eq "NavTurbo") { Update-TurboPage }
    if ($nav -eq "NavAuto") { Fill-AutoList }
    if ($script:LiveTimer) {
        if ($nav -eq "NavLive") { Update-LivePage; $script:LiveTimer.Start() } else { $script:LiveTimer.Stop() }
    }
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
(C "GtaUltra").Add_Click({ Run { Invoke-GtaUltra } })
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


# --- Booster-Login und FPS-Rangliste (v3.0) ---
$ApiBase       = "https://greentweak-api.janpoh9.workers.dev"
$BoardUrl      = "https://tommyeuner.github.io/greentweak/#rangliste"
$AuthFile      = Join-Path $BackupDir "auth.json"
$AuthPort      = 53682
$AuthGraceDays = 7
$script:GTUser = $null
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

function Get-GTAuth {
    try { if (Test-Path $AuthFile) { return (Get-Content $AuthFile -Raw | ConvertFrom-Json) } } catch {}
    return $null
}
function Save-GTAuth($token, $user) {
    [pscustomobject]@{ token = $token; id = $user.id; name = $user.name; exp = $user.exp; checked = (Get-Date).ToString("o") } |
        ConvertTo-Json | Set-Content -Path $AuthFile -Encoding UTF8
}
function Test-GTToken($token) {
    # Rueckgabe: Nutzer-Objekt, "invalid" oder "offline"
    try {
        $r = Invoke-RestMethod -Uri "$ApiBase/verify" -Headers @{ Authorization = "Bearer $token" } -TimeoutSec 8 -UseBasicParsing
        if ($r.ok) { return $r.user }
        return "invalid"
    } catch {
        $code = 0
        try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        if ($code -eq 401) { return "invalid" }
        return "offline"
    }
}
function Get-AuthSwitch {
    # Not-Aus: steht in auth.txt auf GitHub "off", ist kein Login noetig
    try {
        $t = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TommyEuner/greentweak/main/auth.txt" -UseBasicParsing -TimeoutSec 6).Content
        if ("$t".Trim().ToLower() -eq "off") { return $false }
    } catch {}
    return $true
}

function Show-LoginWindow {
    [xml]$lx = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Title="GreenTweak - Anmelden" Width="470" Height="430" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#0A120C">
  <StackPanel Margin="36,28,36,20">
    <Image x:Name="LLogo" Width="76" Height="76" Margin="0,0,0,10"/>
    <TextBlock Text="GreenTweak" Foreground="#39FF14" FontSize="28" FontWeight="Bold" HorizontalAlignment="Center"/>
    <TextBlock Text="Exklusiv für Booster der Green Community" Foreground="#CFE6D2" FontSize="14" HorizontalAlignment="Center" Margin="0,6,0,20"/>
    <Button x:Name="LBtn" Content="Mit Discord anmelden" Height="48" FontSize="15" FontWeight="Bold" Foreground="White" Background="#5865F2" BorderThickness="0" Cursor="Hand"/>
    <TextBlock x:Name="LStatus" Text="Dein Browser öffnet sich. Melde dich bei Discord an und klicke auf 'Autorisieren'." Foreground="#7E9A83" FontSize="12.5" TextWrapping="Wrap" TextAlignment="Center" Margin="0,14,0,12"/>
    <Button x:Name="LJoin" Content="Noch kein Booster? Zum Discord" Height="34" FontSize="12.5" Foreground="#39FF14" Background="Transparent" BorderThickness="0" Cursor="Hand"/>
  </StackPanel>
</Window>
"@
    $lw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $lx))
    $icoL = Join-Path $AppDir "GreenTweak.ico"
    if (Test-Path $icoL) {
        $lw.Icon = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]$icoL)
        $lw.FindName("LLogo").Source = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]$icoL)
    }
    $lBtn = $lw.FindName("LBtn"); $lStatus = $lw.FindName("LStatus")
    $state = @{ ok = $false; user = $null; listener = $null; ar = $null; started = $null }
    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(300)

    $reset = {
        param($msg)
        $timer.Stop()
        try { if ($state.listener) { $state.listener.Stop(); $state.listener.Close() } } catch {}
        $state.listener = $null; $state.ar = $null
        $lStatus.Text = $msg; $lStatus.Foreground = $Bc.ConvertFromString("#FFB347")
        $lBtn.IsEnabled = $true; $lBtn.Content = "Nochmal anmelden"
    }

    $timer.Add_Tick({
        if (-not $state.ar) { return }
        if ($state.ar.IsCompleted) {
            $timer.Stop()
            $token = $null
            try {
                $ctx = $state.listener.EndGetContext($state.ar)
                $token = $ctx.Request.QueryString["token"]
                $html = "<!doctype html><html><head><meta charset='utf-8'><title>GreenTweak</title></head>" +
                        "<body style='background:#07110b;color:#e8fff0;font-family:Segoe UI,Arial;display:grid;place-items:center;height:100vh;margin:0'>" +
                        "<div style='text-align:center'><h1 style='color:#39ff88'>Angemeldet!</h1><p>Du kannst dieses Fenster schließen und zu GreenTweak zurückgehen.</p></div></body></html>"
                $buf = [Text.Encoding]::UTF8.GetBytes($html)
                $ctx.Response.ContentType = "text/html; charset=utf-8"
                $ctx.Response.OutputStream.Write($buf, 0, $buf.Length)
                $ctx.Response.Close()
            } catch {}
            try { $state.listener.Stop(); $state.listener.Close() } catch {}
            $state.listener = $null; $state.ar = $null
            if (-not $token) { & $reset "Anmeldung abgebrochen. Bitte nochmal versuchen."; return }
            $lStatus.Text = "Prüfe Anmeldung..."
            $u = Test-GTToken $token
            if ($u -is [string]) { & $reset "Anmeldung konnte nicht geprüft werden. Bitte nochmal versuchen."; return }
            Save-GTAuth $token $u
            $state.ok = $true; $state.user = $u
            $lw.Close()
        } elseif (((Get-Date) - $state.started).TotalSeconds -gt 300) {
            & $reset "Zeit abgelaufen. Falls Discord 'Nur für Booster' anzeigt, boost zuerst den Server."
        }
    })

    $lBtn.Add_Click({
        try {
            $l = New-Object Net.HttpListener
            $l.Prefixes.Add("http://127.0.0.1:$AuthPort/")
            $l.Start()
        } catch { & $reset "Login-Port $AuthPort ist belegt. Starte den PC neu und versuche es nochmal."; return }
        $state.listener = $l
        $state.ar = $l.BeginGetContext($null, $null)
        $state.started = Get-Date
        $timer.Start()
        $lBtn.IsEnabled = $false; $lBtn.Content = "Warte auf Discord..."
        $lStatus.Text = "Bestätige die Anmeldung im Browser. Danach geht es hier automatisch weiter."
        $lStatus.Foreground = $Bc.ConvertFromString("#7E9A83")
        Start-Process "$ApiBase/login?port=$AuthPort"
    })
    $lw.FindName("LJoin").Add_Click({ Start-Process $DiscordLink })
    $lw.Add_Closed({ $timer.Stop(); try { if ($state.listener) { $state.listener.Stop(); $state.listener.Close() } } catch {} })
    [void]$lw.ShowDialog()
    return $state
}

function Invoke-AuthGate {
    if (-not (Get-AuthSwitch)) { return $true }
    $a = Get-GTAuth
    if ($a -and $a.token) {
        $u = Test-GTToken $a.token
        if ($u -is [string]) {
            if ($u -eq "offline") {
                $chk = [datetime]::MinValue
                try { $chk = [datetime]::Parse($a.checked) } catch {}
                if (((Get-Date) - $chk).TotalDays -le $AuthGraceDays) { $script:GTUser = $a; return $true }
            }
            Remove-Item $AuthFile -Force -ErrorAction SilentlyContinue
        } else {
            Save-GTAuth $a.token $u
            $script:GTUser = $u
            return $true
        }
    }
    $s = Show-LoginWindow
    if ($s.ok) { $script:GTUser = $s.user; return $true }
    return $false
}

function Get-BoardGame($proc) {
    if ($proc -match "FiveM") { return "FiveM" }
    if ($proc -match "^GTA5") { return "GTA5" }
    if ($proc -match "Fortnite") { return "Fortnite" }
    if ($proc -match "VALORANT") { return "Valorant" }
    if ($proc -match "^cs2$") { return "CS2" }
    return "Andere"
}

(C "FpsUpload").Add_Click({
    $h = @(Get-FpsHistory)
    if ($h.Count -eq 0) { [Windows.MessageBox]::Show("Mach zuerst eine FPS-Messung.", "GreenTweak") | Out-Null; return }
    $last = $h | Select-Object -Last 1
    $a = Get-GTAuth
    if (-not $a -or -not $a.token) {
        [Windows.MessageBox]::Show("Du bist nicht angemeldet. Starte GreenTweak neu und melde dich mit Discord an.", "GreenTweak") | Out-Null; return
    }
    $game = Get-BoardGame $last.Game
    $hw = @{ Gpu = ""; Cpu = "" }
    try { $hw = Get-HardwareInfo } catch {}
    $body = @{ game = $game; avg = $last.Avg; low1 = $last.Low1; gpu = $hw.Gpu; cpu = $hw.Cpu; ver = $Version } | ConvertTo-Json
    try {
        $r = Invoke-RestMethod -Uri "$ApiBase/fps" -Method Post -Headers @{ Authorization = "Bearer $($a.token)" } `
             -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8" -TimeoutSec 15 -UseBasicParsing
        if ($r.best) {
            $msg = "Hochgeladen!`n`n$game - $($last.Avg) FPS (1% Low: $($last.Low1))`nDu bist auf Platz $($r.rank) von $($r.total)."
        } else {
            $msg = "Dein bisheriger Bestwert in $game ist höher und bleibt stehen.`nDu bist auf Platz $($r.rank) von $($r.total)."
        }
        Log "Rangliste: $game $($last.Avg) FPS hochgeladen (Platz $($r.rank))."
        $q = [Windows.MessageBox]::Show("$msg`n`nRangliste jetzt ansehen?", "GreenTweak - Rangliste", "YesNo", "Information")
        if ($q -eq "Yes") { Start-Process $BoardUrl }
    } catch {
        $err = ""
        try { $err = ($_.ErrorDetails.Message | ConvertFrom-Json).error } catch {}
        if (-not $err) { $err = "Server nicht erreichbar. Bitte später nochmal versuchen." }
        if ($err -eq "auth") { $err = "Deine Anmeldung ist abgelaufen. Starte GreenTweak neu und melde dich an." }
        [Windows.MessageBox]::Show("Upload hat nicht geklappt:`n$err", "GreenTweak") | Out-Null
    }
})
(C "FpsBoard").Add_Click({ Start-Process $BoardUrl })
(C "BtnLogout").Add_Click({
    $q = [Windows.MessageBox]::Show("Wirklich abmelden? Beim nächsten Start musst du dich neu mit Discord anmelden.", "GreenTweak", "YesNo", "Question")
    if ($q -eq "Yes") {
        Remove-Item $AuthFile -Force -ErrorAction SilentlyContinue
        [Windows.MessageBox]::Show("Abgemeldet. GreenTweak wird jetzt beendet.", "GreenTweak") | Out-Null
        $win.Close()
    }
})


# --- Turbo (v3.1) ---
function Update-TurboPage {
    try {
        $h = Get-HvciState
        $cb = C "TurboHvci"
        $txt = "Die Speicher-Integrität (Kernisolierung) schützt Windows zusätzlich vor Schadsoftware, kostet in Spielen aber oft 5-10 % FPS. " +
               "Ausgeschaltet ist dein PC etwas weniger geschützt. Wirkt erst nach einem Neustart. 'Turbo ausschalten' stellt sie wieder her."
        if ($h.Locked) { $txt += "`nBei dir ist sie per UEFI gesperrt und kann nicht ausgeschaltet werden."; $cb.IsChecked = $false; $cb.IsEnabled = $false }
        elseif (-not $h.Running -and -not $h.Configured) { $txt += "`nBei dir ist sie schon aus."; $cb.IsChecked = $false; $cb.IsEnabled = $false }
        else { $txt += "`nStatus bei dir: AN"; $cb.IsEnabled = $true }
        (C "TurboHvciInfo").Text = $txt
        $st = C "TurboState"
        if (Test-Turbo) {
            $b = Get-Content $TurboFile -Raw | ConvertFrom-Json
            $st.Text = "Turbo ist AKTIV (seit $($b.Created))."
            $st.Foreground = $Bc.ConvertFromString("#39FF14")
        } else {
            $st.Text = "Turbo ist aus."
            $st.Foreground = $Bc.ConvertFromString("#7E9A83")
        }
    } catch {}
}

(C "TurboOn").Add_Click({
    $cb = C "TurboHvci"
    $hv = ([bool]$cb.IsChecked) -and $cb.IsEnabled
    $msg = "Turbo jetzt einschalten?`n`nVorher wird ein Wiederherstellungspunkt erstellt. Mit 'Turbo ausschalten' ist alles wieder wie vorher."
    if ($hv) { $msg += "`n`nACHTUNG: Die Speicher-Integrität wird ausgeschaltet. Dein PC ist dann etwas weniger gegen Schadsoftware geschützt." }
    $r = [Windows.MessageBox]::Show($msg, "GreenTweak - Turbo", "YesNo", $(if ($hv) { "Warning" } else { "Question" }))
    if ($r -ne "Yes") { return }
    Run { New-GTRestorePoint "Vor GreenTweak Turbo"; Invoke-TurboOn $hv }
    Update-TurboPage
    $q = [Windows.MessageBox]::Show("Turbo ist an. Damit alles wirkt, muss der PC neu starten.`n`nJetzt neu starten? Speichere vorher alles!", "GreenTweak", "YesNo", "Question")
    if ($q -eq "Yes") { Restart-Computer -Force }
})
(C "TurboOff").Add_Click({
    if (-not (Test-Turbo)) { [Windows.MessageBox]::Show("Turbo ist gerade nicht aktiv.", "GreenTweak") | Out-Null; return }
    Run { Invoke-TurboOff }
    Update-TurboPage
    $q = [Windows.MessageBox]::Show("Turbo ist aus. Damit alles wieder wie vorher ist, muss der PC neu starten.`n`nJetzt neu starten?", "GreenTweak", "YesNo", "Question")
    if ($q -eq "Yes") { Restart-Computer -Force }
})

# ============================================================
#  v3.2: Leistung (Temperaturen, FPS-Diagramm, Auto-Gaming, NVIDIA)
# ============================================================
function Set-Card($name, $level) {
    $col = switch ($level) { "hot" { "#FF4D4D" } "warm" { "#FFB347" } default { "#1C2E20" } }
    (C $name).BorderBrush = $Bc.ConvertFromString($col)
}

function Update-LiveStats {
    $s = $null
    try { $s = Get-LiveStats } catch { return }
    $warn = @()
    if ($null -ne $s.GpuTemp) {
        (C "LiveGpu").Text = "$($s.GpuTemp) °C"
        $sub = "Auslastung $($s.GpuLoad) %"
        if ($s.VramTotal) { $sub += " | VRAM $([math]::Round($s.VramUsed/1024,1)) / $([math]::Round($s.VramTotal/1024,1)) GB" }
        (C "LiveGpuSub").Text = $sub
        $lvl = if ($s.GpuTemp -ge 83) { "hot" } elseif ($s.GpuTemp -ge 75) { "warm" } else { "ok" }
        Set-Card "LiveGpuCard" $lvl
        if ($lvl -eq "hot") { $warn += "Grafikkarte zu heiß" } elseif ($lvl -eq "warm") { $warn += "Grafikkarte warm" }
    } else {
        (C "LiveGpu").Text = "-"
        (C "LiveGpuSub").Text = "Temperatur nur bei NVIDIA-Karten lesbar"
    }
    if ($null -ne $s.CpuTemp) {
        (C "LiveCpu").Text = "$($s.CpuTemp) °C"
        (C "LiveCpuSub").Text = "Auslastung $($s.CpuLoad) % | Mainboard-Sensor"
        $lvl = if ($s.CpuTemp -ge 90) { "hot" } elseif ($s.CpuTemp -ge 80) { "warm" } else { "ok" }
        Set-Card "LiveCpuCard" $lvl
        if ($lvl -eq "hot") { $warn += "Prozessor zu heiß" } elseif ($lvl -eq "warm") { $warn += "Prozessor warm" }
    } else {
        (C "LiveCpu").Text = "$($s.CpuLoad) %"
        (C "LiveCpuSub").Text = "Auslastung (Temperatur meldet dein PC nicht)"
    }
    if ($warn.Count -eq 0) {
        (C "LiveState").Text = "Alles gut"
        (C "LiveState").Foreground = $Bc.ConvertFromString("#39FF14")
        (C "LiveStateSub").Text = "Temperaturen im grünen Bereich."
    } else {
        $hot = ($warn -join " ") -match "heiß"
        (C "LiveState").Text = if ($hot) { "Zu heiß!" } else { "Warm" }
        (C "LiveState").Foreground = $Bc.ConvertFromString($(if ($hot) { "#FF4D4D" } else { "#FFB347" }))
        (C "LiveStateSub").Text = ($warn -join ", ") + ". Tipp: Lüfter und Staub prüfen, Gehäuse nicht zustellen."
        if ($hot -and -not $script:HotWarned) {
            $script:HotWarned = $true
            Log ("  [!] Achtung: " + ($warn -join ", ") + " - das kostet FPS (Drosselung). Lüfter/Staub prüfen.")
        }
    }
}

function Draw-FpsChart {
    $cv = C "FpsChart"
    $cv.Children.Clear()
    $w = $cv.ActualWidth; $h = $cv.ActualHeight
    if ($w -lt 50) { return }
    $data = @(Get-FpsHistory | Select-Object -Last 20)
    if ($data.Count -lt 2) {
        $t = New-Object Windows.Controls.TextBlock
        $t.Text = "Noch zu wenige Messungen. Mach im FPS-Test mindestens zwei Messungen, dann siehst du hier deinen Verlauf."
        $t.Foreground = $Bc.ConvertFromString("#7E9A83"); $t.TextWrapping = "Wrap"; $t.Width = $w
        [Windows.Controls.Canvas]::SetTop($t, 50); [void]$cv.Children.Add($t)
        return
    }
    $max = [double](($data | ForEach-Object { [double]$_.Avg } | Measure-Object -Maximum).Maximum)
    $max = [math]::Ceiling($max * 1.15 / 10) * 10
    if ($max -le 0) { $max = 100 }
    $left = 40; $top = 8; $bottom = 22
    $pw = $w - $left - 10; $ph = $h - $top - $bottom
    foreach ($f in 0, 0.5, 1) {
        $y = $top + $ph - $ph * $f
        $ln = New-Object Windows.Shapes.Line
        $ln.X1 = $left; $ln.X2 = $w - 10; $ln.Y1 = $y; $ln.Y2 = $y
        $ln.Stroke = $Bc.ConvertFromString("#1C2E20"); $ln.StrokeThickness = 1
        [void]$cv.Children.Add($ln)
        $lb = New-Object Windows.Controls.TextBlock
        $lb.Text = [string][math]::Round($max * $f); $lb.FontSize = 11
        $lb.Foreground = $Bc.ConvertFromString("#7E9A83")
        [Windows.Controls.Canvas]::SetLeft($lb, 0); [Windows.Controls.Canvas]::SetTop($lb, $y - 8)
        [void]$cv.Children.Add($lb)
    }
    $n = $data.Count
    foreach ($key in "Low1", "Avg") {
        $pl = New-Object Windows.Shapes.Polyline
        $pl.Stroke = $Bc.ConvertFromString($(if ($key -eq "Avg") { "#39FF14" } else { "#FFB347" }))
        $pl.StrokeThickness = if ($key -eq "Avg") { 3 } else { 2 }
        $pts = New-Object Windows.Media.PointCollection
        for ($i = 0; $i -lt $n; $i++) {
            $x = $left + $pw * $i / ($n - 1)
            $y = $top + $ph - $ph * ([double]$data[$i].$key / $max)
            $pts.Add((New-Object Windows.Point($x, $y)))
            if ($key -eq "Avg") {
                $d = New-Object Windows.Shapes.Ellipse
                $d.Width = 9; $d.Height = 9
                $d.Fill = $Bc.ConvertFromString($(if ($data[$i].Tweak) { "#39FF14" } else { "#E3F5E5" }))
                $d.ToolTip = "$($data[$i].Date)  $($data[$i].Game)`n$($data[$i].Avg) FPS (1% Low $($data[$i].Low1))  " + $(if ($data[$i].Tweak) { "mit Tweak" } else { "ohne Tweak" })
                [Windows.Controls.Canvas]::SetLeft($d, $x - 4.5); [Windows.Controls.Canvas]::SetTop($d, $y - 4.5)
                [Windows.Controls.Panel]::SetZIndex($d, 5)
                [void]$cv.Children.Add($d)
            }
        }
        $pl.Points = $pts
        [void]$cv.Children.Add($pl)
    }
    foreach ($i in 0, ($n - 1)) {
        $lb = New-Object Windows.Controls.TextBlock
        $lb.Text = ([string]$data[$i].Date).Split(" ")[0]; $lb.FontSize = 11
        $lb.Foreground = $Bc.ConvertFromString("#7E9A83")
        $x = $left + $pw * $i / ($n - 1)
        [Windows.Controls.Canvas]::SetLeft($lb, $(if ($i -eq 0) { $x } else { $x - 60 }))
        [Windows.Controls.Canvas]::SetTop($lb, $h - 16)
        [void]$cv.Children.Add($lb)
    }
}
(C "FpsChart").Add_SizeChanged({ try { Draw-FpsChart } catch {} })

$script:LiveTimer = New-Object Windows.Threading.DispatcherTimer
$script:LiveTimer.Interval = [TimeSpan]::FromSeconds(4)
$script:LiveTimer.Add_Tick({ try { Update-LiveStats } catch {} })

function Update-LivePage {
    $script:SettingAuto = $true
    try { (C "AutoGameBox").IsChecked = (Test-AutoGame) } catch {}
    try { (C "ECoreBox").IsChecked = (Test-ECore) } catch {}
    try { (C "MemBox").IsChecked = (Test-MemClean) } catch {}
    try { (C "TimerBox").IsChecked = (Test-TimerRes) } catch {}
    $script:SettingAuto = $false
    try {
        if (-not $script:HwVendor) { $script:HwVendor = (Get-HardwareInfo).Gpu }
        $g = [string]$script:HwVendor
        if ($g -match "NVIDIA|GeForce|RTX|GTX") { (C "NvidiaInfo").Text = "$($g): Niedrige Latenz und maximale Leistung im NVIDIA-Treiber einstellen (2 Minuten)." }
        elseif ($g -match "Radeon|AMD") { (C "NvidiaInfo").Text = "$($g): Anti-Lag und Leistung in AMD Adrenalin einstellen (2 Minuten)." }
        else { (C "NvidiaInfo").Text = "$($g): Treiber-Einstellungen für mehr Leistung." }
    } catch {}
    try { Draw-FpsChart } catch {}
    Update-LiveStats
}

(C "AutoGameBox").Add_Checked({ if (-not $script:SettingAuto) { Run { Enable-AutoGame } } })
(C "AutoGameBox").Add_Unchecked({ if (-not $script:SettingAuto) { Run { Disable-AutoGame } } })
(C "ECoreBox").Add_Checked({ if (-not $script:SettingAuto) { Run {
    $r = @(Enable-ECore)
    if ($r.Count -eq 0 -or -not $r[-1]) { $script:SettingAuto = $true; (C "ECoreBox").IsChecked = $false; $script:SettingAuto = $false }
} } })
(C "ECoreBox").Add_Unchecked({ if (-not $script:SettingAuto) { Run { Disable-ECore } } })
(C "MemBox").Add_Checked({ if (-not $script:SettingAuto) { Run { Enable-MemClean } } })
(C "MemBox").Add_Unchecked({ if (-not $script:SettingAuto) { Run { Disable-MemClean } } })
(C "TimerBox").Add_Checked({ if (-not $script:SettingAuto) { Run {
    $r = @(Enable-TimerRes)
    if ($r.Count -eq 0 -or -not $r[-1]) { $script:SettingAuto = $true; (C "TimerBox").IsChecked = $false; $script:SettingAuto = $false }
} } })
(C "TimerBox").Add_Unchecked({ if (-not $script:SettingAuto) { Run { Disable-TimerRes } } })
(C "Bottleneck").Add_Click({ Run {
    (C "EngpassText").Text = "Messe..."
    $r = @(Invoke-BottleneckCheck)
    if ($r.Count) { (C "EngpassText").Text = [string]$r[-1] }
} })
(C "NvProfile").Add_Click({ Run { Invoke-NvidiaProfile } })
(C "NvUndo").Add_Click({ Run { Invoke-NvidiaProfileUndo } })
(C "FiveMStart").Add_Click({ Run { Invoke-FiveMStart; Update-GameModeButton } })
(C "ShaderClean").Add_Click({ Run { Invoke-ShaderCacheClean } })
(C "FsoOff").Add_Click({ Run { Invoke-FsoOff } })
(C "FsoUndo").Add_Click({ Run { Invoke-FsoUndo } })

(C "NvidiaGuide").Add_Click({ Run {
    $g = [string]$script:HwVendor
    if ($g -match "Radeon|AMD") {
        $txt = "So stellst du AMD Adrenalin auf Leistung:`n`n" +
               "1. Rechtsklick auf den Desktop > AMD Software: Adrenalin Edition`n" +
               "2. Oben auf 'Gaming' > 'Grafik'`n" +
               "3. Radeon Anti-Lag: EIN (weniger Eingabeverzögerung)`n" +
               "4. Radeon Chill: AUS`n" +
               "5. Warten auf vertikale Aktualisierung: Immer aus`n" +
               "6. Texturfilterungsqualität: Leistung`n`n" +
               "Danach Adrenalin schließen - fertig."
        Log "`n== AMD-Einstellungen =="
        [Windows.MessageBox]::Show($txt, "GreenTweak - Grafikkarte", "OK", "Information") | Out-Null
        return
    }
    $txt = "So stellst du NVIDIA auf maximale Leistung (das Fenster öffnet sich gleich):`n`n" +
           "1. Links auf '3D-Einstellungen verwalten'`n" +
           "2. Reiter 'Globale Einstellungen'`n" +
           "3. Modus für niedrige Latenz: Ultra`n" +
           "4. Energieverwaltungsmodus: Maximale Leistung bevorzugen`n" +
           "5. Shader-Cache-Größe: Unbegrenzt`n" +
           "6. Texturfilterung - Qualität: Hohe Leistung`n" +
           "7. Bevorzugte Aktualisierungsrate: Höchste verfügbare`n" +
           "8. Unten rechts auf 'Übernehmen'`n`n" +
           "Zurück geht immer über 'Wiederherstellen' oben rechts."
    Log "`n== NVIDIA-Einstellungen =="
    [Windows.MessageBox]::Show($txt, "GreenTweak - NVIDIA", "OK", "Information") | Out-Null
    $opened = $false
    $old = Join-Path $env:ProgramFiles "NVIDIA Corporation\Control Panel Client\nvcplui.exe"
    if (Test-Path $old) { Start-Process $old; $opened = $true }
    else {
        $pkg = Get-AppxPackage -Name "NVIDIACorp.NVIDIAControlPanel" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pkg) { Start-Process "explorer.exe" ("shell:AppsFolder\" + $pkg.PackageFamilyName + "!NVIDIACorp.NVIDIAControlPanel"); $opened = $true }
    }
    if ($opened) { Ok "NVIDIA-Systemsteuerung geöffnet. Stell die Werte aus der Anleitung ein." }
    else { Warn "NVIDIA-Systemsteuerung nicht gefunden. Rechtsklick auf den Desktop > NVIDIA-Systemsteuerung (oder im Microsoft Store installieren)." }
} })

# ============================================================
#  v3.2: Vorher/Nachher-Bild zum Teilen
# ============================================================
function New-FpsShareImage {
    $h = @(Get-FpsHistory)
    $after = $h | Where-Object { $_.Tweak } | Select-Object -Last 1
    if (-not $after) { Warn "Noch keine Messung MIT Tweak. Profil anwenden, neu starten und im FPS-Test messen."; return }
    $before = $h | Where-Object { -not $_.Tweak -and $_.Game -eq $after.Game } | Select-Object -First 1
    if (-not $before) { Warn "Keine Messung OHNE Tweak für $($after.Game) gefunden - ohne Vorher-Wert gibt es kein Vergleichsbild."; return }
    $best = $h | Where-Object { $_.Tweak -and $_.Game -eq $after.Game } | Sort-Object { [int]$_.Avg } -Descending | Select-Object -First 1
    if ($best) { $after = $best }

    Add-Type -AssemblyName System.Drawing, System.Windows.Forms
    $S = 1080
    $bmp = New-Object System.Drawing.Bitmap($S, $S)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = "AntiAlias"; $g.TextRenderingHint = "AntiAliasGridFit"; $g.InterpolationMode = "HighQualityBicubic"
    $rect = New-Object System.Drawing.Rectangle(0, 0, $S, $S)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(7, 12, 8), [System.Drawing.Color]::FromArgb(14, 40, 20), 60)
    $g.FillRectangle($bg, $rect)
    $green = [System.Drawing.Color]::FromArgb(57, 255, 20)
    $white = [System.Drawing.Color]::FromArgb(227, 245, 229)
    $grey  = [System.Drawing.Color]::FromArgb(126, 154, 131)
    $pen = New-Object System.Drawing.Pen($green, 6)
    $g.DrawRectangle($pen, 24, 24, $S - 48, $S - 48)
    $c = New-Object System.Drawing.StringFormat; $c.Alignment = "Center"; $c.LineAlignment = "Center"
    function T($text, $size, $color, $y, $style = "Bold") {
        $f = New-Object System.Drawing.Font("Segoe UI", $size, [System.Drawing.FontStyle]$style, [System.Drawing.GraphicsUnit]::Pixel)
        $b = New-Object System.Drawing.SolidBrush($color)
        $g.DrawString($text, $f, $b, (New-Object System.Drawing.RectangleF(40, $y, ($S - 80), ($size * 1.5))), $c)
        $f.Dispose(); $b.Dispose()
    }
    $ico = Join-Path $AppDir "GreenTweak.ico"
    if (Test-Path $ico) {
        try { $ic = New-Object System.Drawing.Icon($ico, 256, 256); $lg = $ic.ToBitmap(); $g.DrawImage($lg, ($S / 2 - 80), 70, 160, 160); $lg.Dispose(); $ic.Dispose() } catch {}
    }
    T "GreenTweak" 64 $green 245
    $game = if ($after.Game -match "FiveM") { "FiveM" } elseif ($after.Game -match "GTA") { "GTA V" } else { [string]$after.Game }
    T ("FPS-Test  |  " + $game) 36 $grey 345 "Regular"
    # Vorher / Nachher nebeneinander
    $fBig = New-Object System.Drawing.Font("Segoe UI", 150, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $fLbl = New-Object System.Drawing.Font("Segoe UI", 34, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $g.DrawString("VORHER", $fLbl, (New-Object System.Drawing.SolidBrush($grey)), (New-Object System.Drawing.RectangleF(40, 440, 420, 50)), $c)
    $g.DrawString("NACHHER", $fLbl, (New-Object System.Drawing.SolidBrush($green)), (New-Object System.Drawing.RectangleF(620, 440, 420, 50)), $c)
    $g.DrawString([string]$before.Avg, $fBig, (New-Object System.Drawing.SolidBrush($white)), (New-Object System.Drawing.RectangleF(40, 480, 420, 200)), $c)
    $g.DrawString([string]$after.Avg, $fBig, (New-Object System.Drawing.SolidBrush($green)), (New-Object System.Drawing.RectangleF(620, 480, 420, 200)), $c)
    $fArr = New-Object System.Drawing.Font("Segoe UI", 110, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $g.DrawString([string][char]0x2192, $fArr, (New-Object System.Drawing.SolidBrush($green)), (New-Object System.Drawing.RectangleF(440, 490, 200, 180)), $c)
    $pct = [math]::Round(([double]$after.Avg - [double]$before.Avg) / [math]::Max(1, [double]$before.Avg) * 100)
    $sign = if ($pct -ge 0) { "+" } else { "" }
    T ("FPS   " + $sign + $pct + " %") 92 $green 690
    T ("1% Low: " + $before.Low1 + " " + [char]0x2192 + " " + $after.Low1 + " FPS") 38 $white 830 "Regular"
    $who = if ($script:GTUser -and $script:GTUser.name) { "@" + $script:GTUser.name + "  |  " } else { "" }
    T ($who + "discord.gg/KMZKewWQTp") 32 $grey 945 "Regular"
    $g.Dispose()

    $dir = [Environment]::GetFolderPath("MyPictures")
    if (-not $dir -or -not (Test-Path $dir)) { $dir = [Environment]::GetFolderPath("Desktop") }
    $file = Join-Path $dir ("GreenTweak_FPS_" + (Get-Date -Format "yyyy-MM-dd_HH-mm") + ".png")
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
    try { [System.Windows.Forms.Clipboard]::SetImage($bmp) } catch {}
    $bmp.Dispose()
    Ok ("Bild gespeichert: " + $file)
    Ok "Das Bild ist auch kopiert - in Discord oder TikTok einfach mit Strg+V einfügen."
    Start-Process $file
}
(C "FpsImage").Add_Click({ Run { Log "`n== Vorher/Nachher-Bild =="; New-FpsShareImage } })

# --- v3.4: XMP-Hinweis beim Start ---
$win.Add_ContentRendered({
    try {
        $f = Join-Path $BackupDir "xmp_hint.txt"
        $last = if (Test-Path $f) { (Get-Content $f -Raw).Trim() } else { "" }
        if ($last -eq "never") { return }
        if ($last) {
            try { if (((Get-Date) - [datetime]::ParseExact($last, "yyyy-MM-dd", $null)).TotalDays -lt 7) { return } } catch {}
        }
        $x = Get-XmpStatus
        if (-not $x.Off) { return }
        $txt = "Dein Arbeitsspeicher ($($x.Type)) läuft nur mit $($x.Cur) MT/s.`n" +
               "Wahrscheinlich ist XMP/EXPO im BIOS aus. Das kostet in FiveM oft 10-20 % FPS.`n`n" +
               "So schaltest du es ein:`n" +
               "1. PC neu starten und beim Start mehrmals Entf (oder F2) drücken`n" +
               "2. $($x.Steps)`n" +
               "3. Mit F10 speichern und neu starten`n`n" +
               "Mainboard: $($x.Board)`n" +
               "(Ist dein RAM nur für $($x.Cur) MT/s gebaut, ist alles in Ordnung.)`n`n" +
               "In ein paar Tagen wieder erinnern?"
        $res = [Windows.MessageBox]::Show($txt, "GreenTweak - RAM läuft zu langsam", "YesNo", "Warning")
        $val = if ("$res" -eq "No") { "never" } else { (Get-Date).ToString("yyyy-MM-dd") }
        Set-Content -Path $f -Value $val
    } catch {}
})

# --- Neu in dieser Version ---
$win.Add_ContentRendered({
    try {
        $seenFile = Join-Path $BackupDir "version_seen.txt"
        $seen = if (Test-Path $seenFile) { (Get-Content $seenFile -Raw).Trim() } else { "" }
        if ($seen -ne $Version) {
            Set-Content -Path $seenFile -Value $Version
            $txt = "Neu in GreenTweak $($Version):`n`n" +
                   "Seite 'Leistung':`n" +
                   "- Engpass prüfen: zeigt, ob Grafikkarte oder Prozessor bremst`n" +
                   "- NVIDIA-Profil automatisch (nur für FiveM/GTA)`n" +
                   "- RAM-Freiräumer und Timer-Auflösung`n`n" +
                   "Seite 'FiveM & GTA':`n" +
                   "- FiveM starten mit einem Klick`n" +
                   "- Shader-Cache leeren und Vollbild-Optimierung aus`n`n" +
                   "Alles lässt sich wieder zurücksetzen.`n`n" +
                   "Viel Spaß! - Green Community"
            [Windows.MessageBox]::Show($txt, "GreenTweak - Update", "OK", "Information") | Out-Null
        }
    } catch {}
})


(C "InfoText").Text = "Version: $Version`nSicherung und Protokoll: $BackupDir`nDiscord: $DiscordLink`n`nAlle Änderungen werden vorher gesichert. Mit 'Alles rückgängig' ist dein PC wieder wie vorher."

try { [GT.Win]::ShowWindow([GT.Win]::GetConsoleWindow(), 0) | Out-Null } catch {}
$authOk = $true
try { $authOk = Invoke-AuthGate } catch { try { Add-Content -Path (Join-Path $BackupDir "fehler.txt") -Value ("[{0}] Login: {1}" -f (Get-Date), $_) } catch {}; $authOk = $true }
if (-not $authOk) { exit }
if ($script:GTUser) { (C "UserText").Text = "Angemeldet als $($script:GTUser.name)" }
Show-Page "NavDash"
Update-GameModeButton
Log "GreenTweak v$Version bereit. Tipp: Starte zuerst den Systemcheck."
[void]$win.ShowDialog()
