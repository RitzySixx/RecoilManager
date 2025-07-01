# ===== ENHANCED STEALTH INITIALIZATION =====
$signature = @"
using System;
using System.Runtime.InteropServices;

public class ProcessHider {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool FreeConsole();

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool AttachConsole(uint dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleTitle(string lpConsoleTitle);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int SetWindowText(IntPtr hWnd, string text);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
Add-Type -TypeDefinition $signature -Language CSharp

# Detach from current console
[ProcessHider]::FreeConsole() | Out-Null
[ProcessHider]::AttachConsole(0xFFFFFFFF) | Out-Null  # Attach to parent console

# Set random console title
$randomTitle = "RuntimeBroker_" + (Get-Random -Minimum 1000 -Maximum 9999)
[ProcessHider]::SetConsoleTitle($randomTitle) | Out-Null

# Hide PowerShell window completely
$consoleHandle = [ProcessHider]::FindWindow("ConsoleWindowClass", $null)
if ($consoleHandle -ne [IntPtr]::Zero) {
    [ProcessHider]::ShowWindow($consoleHandle, 0)  # SW_HIDE
    [ProcessHider]::SetWindowText($consoleHandle, $randomTitle)
}

# Add this to spoof process name in Task Manager
$dummyProcessName = "RuntimeBroker_" + (Get-Random -Minimum 1000 -Maximum 9999)
[System.Diagnostics.Process]::GetCurrentProcess().MainWindowTitle = $dummyProcessName

# Define the GitHub raw file URL
$githubScriptUrl = "https://raw.githubusercontent.com/RitzySixx/RecoilManager/refs/heads/main/recoil%20script%20maker.ps1"

# Get the current script path
$currentScript = $MyInvocation.MyCommand.Path

# Modify the update section
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
    $latestVersion = $webClient.DownloadString($githubScriptUrl).Trim()
    $currentVersion = (Get-Content -Path $currentScript -Raw).Trim()

    if ($latestVersion -ne $currentVersion) {
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $latestVersion | Out-File -FilePath $tempFile -Force -Encoding UTF8
        
        # Restart with hidden window using double-launch technique
        $startArgs = @{
            FilePath = "powershell.exe"
            ArgumentList = @(
                "-NoProfile",
                "-ExecutionPolicy Bypass",
                "-Command",
                "Start-Process powershell -ArgumentList '-NoExit -WindowStyle Hidden -File ```"$tempFile```"' -WindowStyle Hidden"
            )
            WindowStyle = 'Hidden'
        }
        Start-Process @startArgs
        exit
    }
} catch {
    Write-Host "Unable to check for updates. Continuing with current version..." -ForegroundColor Yellow
}

# Enhanced SpoofSignatures function
function SpoofSignatures {
    # Generate random memory blocks
    $size1 = Get-Random -Minimum 512 -Maximum 2048
    $dummyArray1 = New-Object byte[] $size1
    $size2 = Get-Random -Minimum 512 -Maximum 2048
    $dummyArray2 = New-Object byte[] $size2
    
    # Use secure RNG
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($dummyArray1)
    $rng.GetBytes($dummyArray2)
    $rng.Dispose()
    
    # Create decoy operations
    $dummyString = [System.Text.Encoding]::Unicode.GetString($dummyArray1)
    $null = [System.Security.Cryptography.SHA256]::Create().ComputeHash($dummyArray2)
    
    # Memory spoofing - overwrite PowerShell signatures
    $dummyProcessName = "RuntimeBroker_" + (Get-Random -Minimum 1000 -Maximum 9999)
    try {
        [System.Diagnostics.Process]::GetCurrentProcess().MainWindowTitle = $dummyProcessName
    } catch {}
    
    # Force garbage collection
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    
    # Decoy API calls
    try {
        [void][System.Runtime.InteropServices.Marshal]::AllocHGlobal(1024)
        [void][System.Runtime.InteropServices.Marshal]::FreeHGlobal([IntPtr]::Zero)
        [void][System.Diagnostics.Process]::GetProcesses()
    } catch {}
    
    # Random delay
    Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 300)
}

# Call it early
SpoofSignatures

# Initialize periodic spoofing
$spoofTimer = New-Object System.Windows.Forms.Timer
$spoofTimer.Interval = 300000  # 5 minutes
$spoofTimer.Add_Tick({ SpoofSignatures })
$spoofTimer.Start()

# Add necessary assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create preset directory if it doesn't exist
$presetPath = "C:\RecoilControl"
if (-not (Test-Path $presetPath)) {
    New-Item -Path $presetPath -ItemType Directory | Out-Null
}

[xml]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Recoil Control" 
    Height="710" 
    Width="600"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    ResizeMode="NoResize">

    <Window.Resources>
        <Style x:Key="ComboBoxStyle" TargetType="ComboBox">
            <Setter Property="Background" Value="#413e3e"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="BorderBrush" Value="#00BFFF"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="FontSize" Value="12"/>
            <Style.Resources>
                <Style TargetType="ComboBoxItem">
                    <Setter Property="Background" Value="#413e3e"/>
                    <Setter Property="Foreground" Value="#000000"/>
                    <Style.Triggers>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#5a5656"/>
                            <Setter Property="Foreground" Value="#000000"/>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Background" Value="#504c4c"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </Style.Resources>
        </Style>
        <Style x:Key="TextBoxStyle" TargetType="TextBox">
            <Setter Property="Background" Value="#413e3e"/>
            <Setter Property="Foreground" Value="#00acb3"/>
            <Setter Property="BorderBrush" Value="#00BFFF"/>
            <Setter Property="TextAlignment" Value="Center"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>

        <Style x:Key="SliderStyle" TargetType="Slider">
            <Setter Property="Minimum" Value="0"/>
            <Setter Property="Maximum" Value="350"/>
            <Setter Property="TickFrequency" Value="0.1"/>
            <Setter Property="IsSnapToTickEnabled" Value="True"/>
        </Style>

        <Style x:Key="ButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#252525"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#00BFFF"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#3A3A3A"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#505050"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    <Border Background="#0A0A0A" 
            CornerRadius="10"
            BorderBrush="#333333"
            BorderThickness="1">
        <Grid>
            <!-- Window Controls -->
            <StackPanel Orientation="Horizontal"
                         HorizontalAlignment="Right"
                         VerticalAlignment="Top"
                         Margin="0,10,10,0">
                <Button x:Name="MinimizeButton"
                         Content="—"
                         Width="30"
                         Height="30"
                        Background="Transparent"
                        Foreground="White"
                        BorderThickness="0"
                        Margin="0,0,5,0"/>
                <Button x:Name="CloseButton"
                         Content="✕"
                         Width="30"
                         Height="30"
                        Background="Transparent"
                        Foreground="White"
                        BorderThickness="0"/>
            </StackPanel>

            <!-- Main Content -->
            <StackPanel Margin="15,40,15,15">
                <!-- Header -->
                <TextBlock Text="R E C O I L  C O N T R O L"
                           Foreground="#00BFFF"
                           FontSize="24"
                           FontWeight="Bold"
                           HorizontalAlignment="Center"
                           Margin="0,0,0,10"/>
                <!-- Main Settings Section -->
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Border Background="#141414"
                             CornerRadius="8"
                             Padding="15"
                             Margin="0,0,7.5,0"
                            Grid.Column="0">
                        <StackPanel>
                            <TextBlock Text="MAIN SETTINGS"
                                       Foreground="#00BFFF"
                                       FontWeight="Bold"
                                       FontSize="14"
                                       Margin="0,0,0,10"/>

                            <!-- Enable RCS -->
                            <Grid Margin="0,5,0,5">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="Enable Recoil Control"
                                           Foreground="White"
                                           FontSize="13"
                                           VerticalAlignment="Center"/>
                                <CheckBox x:Name="EnableRCSCheckBox"
                                          Grid.Column="1"
                                          IsChecked="True"
                                          VerticalAlignment="Center"/>
                            </Grid>

                            <!-- Require Toggle -->
                            <Grid Margin="0,5,0,5">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="Require Toggle Key"
                                           Foreground="White"
                                           FontSize="13"
                                           VerticalAlignment="Center"/>
                                <CheckBox x:Name="RequireToggleCheckBox"
                                          Grid.Column="1"
                                          IsChecked="True"
                                          VerticalAlignment="Center"/>
                            </Grid>
                            <!-- Toggle Key -->
                            <Grid Margin="0,5,0,5">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="120"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="Toggle Key"
                                           Foreground="White"
                                           FontSize="13"
                                           VerticalAlignment="Center"/>
                                <ComboBox x:Name="ToggleKeyComboBox"
                                         Grid.Column="1"
                                        Style="{StaticResource ComboBoxStyle}"
                                        SelectedIndex="0">
                                    <ComboBoxItem Content="CapsLock"/>
                                    <ComboBoxItem Content="NumLock"/>
                                    <ComboBoxItem Content="ScrollLock"/>
                                </ComboBox>
                            </Grid>
                        </StackPanel>
                    </Border>

                    <!-- Status Section -->
                    <Border Background="#141414"
                            CornerRadius="8"
                            Padding="15"
                            Margin="7.5,0,0,0"
                            Grid.Column="1">
                        <StackPanel>
                            <TextBlock Text="STATUS"
                                    Foreground="#00BFFF"
                                    FontWeight="Bold"
                                    FontSize="14"
                                    Margin="0,0,0,10"/>
                            <Border Background="#0A0A0A"
                                    CornerRadius="4"
                                    Padding="10"
                                    Margin="0,15,0,15">
                                <StackPanel>
                                    <TextBlock x:Name="StatusText"
                                            Text="Status: ready"
                                            Foreground="#00FF00"
                                            HorizontalAlignment="Center"
                                            FontWeight="Bold"
                                            FontSize="14"/>
                                    <TextBlock x:Name="CurrentPresetText"
                                            Text="Preset: None"
                                            Foreground="#00BFFF"
                                            HorizontalAlignment="Center"
                                            FontWeight="Bold"
                                            FontSize="14"/>
                                </StackPanel>
                            </Border>
                            <TextBlock Text="Active when enabled"
                                    Foreground="#B0B0B0"
                                    HorizontalAlignment="Center"
                                    FontSize="12"
                                    Margin="0,5,0,0"/>
                        </StackPanel>
                    </Border>
                </Grid>
                <!-- Vertical Recoil Section -->
                <Border Background="#141414"
                         CornerRadius="8"
                         Padding="12"
                         Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="VERTICAL RECOIL"
                                    Foreground="#00BFFF"
                                    FontWeight="Bold"
                                    FontSize="14"
                                    Margin="0,0,0,10"/>

                        <!-- Vertical Recoil Mode -->
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="120"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Control Mode"
                                       Foreground="White"
                                       FontSize="13"
                                       VerticalAlignment="Center"/>
                            <ComboBox x:Name="VerticalRecoilModeComboBox"
                                      Grid.Column="1"
                                      Style="{StaticResource ComboBoxStyle}"
                                      SelectedIndex="2">
                                <ComboBoxItem Content="Low (5)" Foreground="White" Background="#252525"/>
                                <ComboBoxItem Content="Medium (10)" Foreground="White" Background="#252525"/>
                                <ComboBoxItem Content="High (15)" Foreground="White" Background="#252525"/>
                                <ComboBoxItem Content="Ultra (20)" Foreground="White" Background="#252525"/>
                                <ComboBoxItem Content="Insanity (30)" Foreground="White" Background="#252525"/>
                                <ComboBoxItem Content="Custom" Foreground="White" Background="#252525"/>
                            </ComboBox>
                        </Grid>
                        <!-- Vertical Custom Strength -->
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="40"/>
                                <ColumnDefinition Width="200"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Strength"
                                       Foreground="White"
                                       FontSize="13"
                                       VerticalAlignment="Center"/>
                            <TextBox x:Name="VerticalCustomStrengthTextBox"
                                     Grid.Column="1"
                                     Style="{StaticResource TextBoxStyle}"
                                     Text="15"/>
                            <Slider x:Name="VerticalCustomStrengthSlider"
                                    Grid.Column="2"
                                    Style="{StaticResource SliderStyle}"
                                    Value="15"
                                    Margin="10,0,0,0"/>
                        </Grid>

                        <!-- Vertical Delay -->
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="40"/>
                                <ColumnDefinition Width="200"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Delay (ms)"
                                       Foreground="White"
                                       FontSize="13"
                                       VerticalAlignment="Center"/>
                            <TextBox x:Name="VerticalDelayTextBox"
                                     Grid.Column="1"
                                     Style="{StaticResource TextBoxStyle}"
                                     Text="7"/>
                            <Slider x:Name="VerticalDelaySlider"
                                    Grid.Column="2"
                                    Style="{StaticResource SliderStyle}"
                                    Value="7"
                                    Margin="10,0,0,0"/>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Horizontal Recoil Section -->
                <Border Background="#141414"
                         CornerRadius="8"
                         Padding="12"
                         Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="HORIZONTAL RECOIL"
                                    Foreground="#00BFFF"
                                    FontWeight="Bold"
                                    FontSize="14"
                                    Margin="0,0,0,10"/>

                        <!-- Horizontal Direction -->
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="120"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Direction"
                                       Foreground="White"
                                       FontSize="13"
                                       VerticalAlignment="Center"/>
                            <ComboBox x:Name="HorizontalDirectionComboBox"
                                      Grid.Column="1"
                                      Style="{StaticResource ComboBoxStyle}"
                                      SelectedIndex="0">
                                <ComboBoxItem Content="Left" Foreground="White" Background="#252525"/>
                                <ComboBoxItem Content="Right" Foreground="White" Background="#252525"/>
                                <ComboBoxItem Content="Random" Foreground="White" Background="#252525"/>
                            </ComboBox>
                        </Grid>
                        <!-- Horizontal Strength -->
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="40"/>
                                <ColumnDefinition Width="200"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Strength"
                                       Foreground="White"
                                       FontSize="13"
                                       VerticalAlignment="Center"/>
                            <TextBox x:Name="HorizontalStrengthTextBox"
                                     Grid.Column="1"
                                     Style="{StaticResource TextBoxStyle}"
                                     Text="0"/>
                            <Slider x:Name="HorizontalStrengthSlider"
                                    Grid.Column="2"
                                    Style="{StaticResource SliderStyle}"
                                    Value="0"
                                    Maximum="350"
                                    Margin="10,0,0,0"/>
                        </Grid>

                        <!-- Horizontal Delay -->
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="40"/>
                                <ColumnDefinition Width="200"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Text="Delay (ms)"
                                       Foreground="White"
                                       FontSize="13"
                                       VerticalAlignment="Center"/>
                            <TextBox x:Name="HorizontalDelayTextBox"
                                     Grid.Column="1"
                                     Style="{StaticResource TextBoxStyle}"
                                     Text="0"/>
                            <Slider x:Name="HorizontalDelaySlider"
                                    Grid.Column="2"
                                    Style="{StaticResource SliderStyle}"
                                    Value="0"
                                    Margin="10,0,0,0"/>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Preset Management Section -->
                <Border Background="#141414"
                         CornerRadius="8"
                         Padding="12"
                         Margin="0,0,0,0">
                    <StackPanel>
                        <TextBlock Text="PRESET MANAGEMENT"
                                    Foreground="#00BFFF"
                                    FontWeight="Bold"
                                    FontSize="14"
                                    Margin="0,0,0,10"/>

                        <!-- Save and Load Buttons -->
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <Button x:Name="SavePresetButton"
                                    Content="Save Preset"
                                    Style="{StaticResource ButtonStyle}"
                                    Margin="0,0,5,0"/>

                            <Button x:Name="LoadPresetButton"
                                    Content="Load Preset"
                                    Grid.Column="1"
                                    Style="{StaticResource ButtonStyle}"
                                    Margin="5,0,0,0"/>
                        </Grid>
                    </StackPanel>
                </Border>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

# Create window
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$colors = @("#00BFFF", "#1E90FF", "#00CED1", "#20B2AA", "#4682B4")
$randomColor = $colors | Get-Random
$window.Resources["ButtonStyle"].Setters | 
    Where-Object { $_.Property -eq "BorderBrush" } | 
    ForEach-Object { $_.Value = $randomColor }
$window.Resources["ComboBoxStyle"].Setters | 
    Where-Object { $_.Property -eq "BorderBrush" } | 
    ForEach-Object { $_.Value = $randomColor }
$window.Resources["TextBoxStyle"].Setters | 
    Where-Object { $_.Property -eq "BorderBrush" } | 
    ForEach-Object { $_.Value = $randomColor }

# Get controls
$closeButton = $window.FindName("CloseButton")
$minimizeButton = $window.FindName("MinimizeButton")
$enableRCSCheckBox = $window.FindName("EnableRCSCheckBox")
$requireToggleCheckBox = $window.FindName("RequireToggleCheckBox")
$toggleKeyComboBox = $window.FindName("ToggleKeyComboBox")
$verticalRecoilModeComboBox = $window.FindName("VerticalRecoilModeComboBox")
$verticalCustomStrengthTextBox = $window.FindName("VerticalCustomStrengthTextBox")
$verticalCustomStrengthSlider = $window.FindName("VerticalCustomStrengthSlider")
$verticalDelayTextBox = $window.FindName("VerticalDelayTextBox")
$verticalDelaySlider = $window.FindName("VerticalDelaySlider")
$horizontalDirectionComboBox = $window.FindName("HorizontalDirectionComboBox")
$horizontalStrengthTextBox = $window.FindName("HorizontalStrengthTextBox")
$horizontalStrengthSlider = $window.FindName("HorizontalStrengthSlider")
$horizontalDelayTextBox = $window.FindName("HorizontalDelayTextBox")
$horizontalDelaySlider = $window.FindName("HorizontalDelaySlider")
$savePresetButton = $window.FindName("SavePresetButton")
$loadPresetButton = $window.FindName("LoadPresetButton")
$statusText = $window.FindName("StatusText")

# Initialize variables
$script:enableRCS = $true
$script:verticalRecoilMode = "High (15)"
$script:verticalRecoilStrength = 15
$script:verticalCustomStrength = 15
$script:verticalDelay = 7
$script:requireToggle = $true
$script:toggleKey = "CapsLock"
$script:horizontalDirection = "Left"
$script:horizontalStrength = 0
$script:horizontalDelay = 0

# Create preset directory if it doesn't exist
$presetDirectory = "C:\RecoilControl"
if (-not (Test-Path -Path $presetDirectory)) {
    New-Item -ItemType Directory -Path $presetDirectory | Out-Null
}

# Window control handlers
$closeButton.Add_Click({ $window.Close() })
$minimizeButton.Add_Click({ 
    $window.WindowState = "Minimized" 
    $statusText.Text = "Status: Active"
    $statusText.Foreground = "#00FF00"
})

# Enable RCS checkbox handler
# RCS
$enableRCSCheckBox.Add_Checked({
    $script:enableRCS = $true
    $statusText.Text = "Status: ready"
    $statusText.Foreground = "#00FF00"
})
$enableRCSCheckBox.Add_Unchecked({
    $script:enableRCS = $false
    $statusText.Text = "Status: Disabled"
    $statusText.Foreground = "#FF0000"
})

# Add mouse movement functionality
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseMover {
    [DllImport("user32.dll")]
    public static extern bool GetAsyncKeyState(int vKey);
    
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetKeyState(int nVirtKey);
}
"@

# Function to check if toggle key is active
function IsKeyLockOn($key) {
    switch ($key) {
        "CapsLock" { return [Console]::CapsLock }
        "NumLock" { return [Console]::NumberLock }
        "ScrollLock" { 
            $scrollLockState = [MouseMover]::GetKeyState(0x91)
            return ($scrollLockState -band 1) -eq 1
        }
        default { return $false }
    }
}

# Function to get random horizontal direction
function GetRandomHorizontalMovement($strength) {
    $direction = Get-Random -Minimum 0 -Maximum 2
    if ($direction -eq 0) {
        return -$strength  # Left
    } else {
        return $strength   # Right
    }
}

# Initialize timers for mouse movement
$verticalTimer = New-Object System.Windows.Forms.Timer
$horizontalTimer = New-Object System.Windows.Forms.Timer

$baseInterval = 10
$randomVariance = Get-Random -Minimum -3 -Maximum 4
$verticalTimer.Interval = $baseInterval + $randomVariance
$horizontalTimer.Interval = $baseInterval + $randomVariance

# Vertical timer tick event handler
$verticalTimer.Add_Tick({
    if ($script:enableRCS) {
        $toggleActive = if ($script:requireToggle) { IsKeyLockOn($script:toggleKey) } else { $true }
        
        if ($toggleActive) {
            if ([MouseMover]::GetAsyncKeyState(0x02)) {
                if ([MouseMover]::GetAsyncKeyState(0x01)) {
                    [MouseMover]::mouse_event(0x0001, 0, $script:verticalRecoilStrength, 0, 0)
                }
            }
        }
    }
})

# Horizontal timer tick event handler
$horizontalTimer.Add_Tick({
    if ($script:enableRCS) {
        $toggleActive = if ($script:requireToggle) { IsKeyLockOn($script:toggleKey) } else { $true }
        
        if ($toggleActive) {
            if ([MouseMover]::GetAsyncKeyState(0x02)) {
                if ([MouseMover]::GetAsyncKeyState(0x01)) {
                    if ($script:horizontalStrength -gt 0) {
                        $horizontalMove = 0
                        switch ($script:horizontalDirection) {
                            "Left" { $horizontalMove = -$script:horizontalStrength }
                            "Right" { $horizontalMove = $script:horizontalStrength }
                            "Random" { $horizontalMove = GetRandomHorizontalMovement($script:horizontalStrength) }
                        }
                        
                        [MouseMover]::mouse_event(0x0001, $horizontalMove, 0, 0, 0)
                    }
                }
            }
        }
    }
})

# Control event handlers
$requireToggleCheckBox.Add_Checked({ $script:requireToggle = $true })
$requireToggleCheckBox.Add_Unchecked({ $script:requireToggle = $false })

$toggleKeyComboBox.Add_SelectionChanged({
    $script:toggleKey = $toggleKeyComboBox.SelectedItem.Content
})

# Vertical recoil mode selection handler
$verticalRecoilModeComboBox.Add_SelectionChanged({
    $selectedMode = $verticalRecoilModeComboBox.SelectedItem.Content
    $script:verticalRecoilMode = $selectedMode
    
    switch ($selectedMode) {
        "Low (5)" { 
            $script:verticalRecoilStrength = 5
            $verticalCustomStrengthTextBox.Text = "5"
            $verticalCustomStrengthSlider.Value = 5
        }
        "Medium (10)" { 
            $script:verticalRecoilStrength = 10
            $verticalCustomStrengthTextBox.Text = "10"
            $verticalCustomStrengthSlider.Value = 10
        }
        "High (15)" { 
            $script:verticalRecoilStrength = 15
            $verticalCustomStrengthTextBox.Text = "15"
            $verticalCustomStrengthSlider.Value = 15
        }
        "Ultra (20)" { 
            $script:verticalRecoilStrength = 20
            $verticalCustomStrengthTextBox.Text = "20"
            $verticalCustomStrengthSlider.Value = 20
        }
        "Insanity (30)" { 
            $script:verticalRecoilStrength = 30 
            $verticalCustomStrengthTextBox.Text = "30"
            $verticalCustomStrengthSlider.Value = 30
        }
        "Custom" { 
            $script:verticalRecoilStrength = [int]$verticalCustomStrengthTextBox.Text 
        }
    }
})

# Vertical strength controls
$verticalCustomStrengthSlider.Add_ValueChanged({
    $value = [Math]::Round($verticalCustomStrengthSlider.Value, 1)
    $verticalCustomStrengthTextBox.Text = $value
    if ($verticalRecoilModeComboBox.SelectedItem.Content -eq "Custom") {
        $script:verticalRecoilStrength = $value
    }
})

$verticalCustomStrengthTextBox.Add_TextChanged({
    if ($verticalCustomStrengthTextBox.Text -match '^\d*\.?\d*$') {
        $value = [double]$verticalCustomStrengthTextBox.Text
        if ($value -ge 0 -and $value -le 50) {
            $verticalCustomStrengthSlider.Value = $value
            if ($verticalRecoilModeComboBox.SelectedItem.Content -eq "Custom") {
                $script:verticalRecoilStrength = $value
            }
        }
    }
})

# Vertical delay controls
$verticalDelaySlider.Add_ValueChanged({
    $value = [Math]::Max(1, [Math]::Round($verticalDelaySlider.Value))
    $verticalDelayTextBox.Text = $value
    $script:verticalDelay = $value
    $verticalTimer.Interval = $value
})

$verticalDelayTextBox.Add_TextChanged({
    if ($verticalDelayTextBox.Text -match '^\d+$') {
        $value = [Math]::Max(1, [int]$verticalDelayTextBox.Text)
        if ($value -ge 0 -and $value -le 50) {
            $verticalDelaySlider.Value = $value
            $script:verticalDelay = $value
            $verticalTimer.Interval = $value
        }
    }
})

# Horizontal direction handler
$horizontalDirectionComboBox.Add_SelectionChanged({
    $script:horizontalDirection = $horizontalDirectionComboBox.SelectedItem.Content
})

# Horizontal strength controls
$horizontalStrengthSlider.Add_ValueChanged({
    $value = [Math]::Round($horizontalStrengthSlider.Value, 1)
    $horizontalStrengthTextBox.Text = $value
    $script:horizontalStrength = $value
})

$horizontalStrengthTextBox.Add_TextChanged({
    if ($horizontalStrengthTextBox.Text -match '^\d*\.?\d*$') {
        $value = [double]$horizontalStrengthTextBox.Text
        if ($value -ge 0 -and $value -le 20) {
            $horizontalStrengthSlider.Value = $value
            $script:horizontalStrength = $value
        }
    }
})

$horizontalDelaySlider.Add_ValueChanged({
    $value = [Math]::Max(1, [Math]::Round($horizontalDelaySlider.Value))
    $horizontalDelayTextBox.Text = $value
    $script:horizontalDelay = $value
    
    # Randomize timing on each change
    $randomVariance = Get-Random -Minimum -3 -Maximum 4
    $horizontalTimer.Interval = $value + $randomVariance
})

$horizontalDelayTextBox.Add_TextChanged({
    if ($horizontalDelayTextBox.Text -match '^\d+$') {
        $value = [Math]::Max(1, [int]$horizontalDelayTextBox.Text)
        if ($value -ge 0 -and $value -le 50) {
            $horizontalDelaySlider.Value = $value
            $script:horizontalDelay = $value
            
            # Apply random variance when text changes
            $randomVariance = Get-Random -Minimum -3 -Maximum 3
            $horizontalTimer.Interval = $value + $randomVariance
        }
    }
})

# Save Preset GUI and functionality
$savePresetButton.Add_Click({
    $saveWindow = [Windows.Markup.XamlReader]::Parse(@"
    <Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Save Preset"
            Height="180"
            Width="300"
            WindowStyle="None"
            AllowsTransparency="True"
            Background="Transparent"
            WindowStartupLocation="CenterOwner">
        <Border Background="#0A0A0A"
                BorderBrush="#333333"
                BorderThickness="1"
                CornerRadius="10">
            <Grid Margin="15">
                <StackPanel>
                    <TextBlock Text="SAVE PRESET"
                             Foreground="#00BFFF"
                             FontSize="16"
                             FontWeight="Bold"
                             HorizontalAlignment="Center"
                             Margin="0,0,0,15"/>
                    <TextBox x:Name="PresetNameBox"
                            Height="30"
                            Background="#252525"
                            Foreground="White"
                            BorderBrush="#00BFFF"
                            Padding="5"
                            Margin="0,0,0,15"/>
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="SaveButton"
                                Content="Save"
                                Height="30"
                                Background="#252525"
                                Foreground="White"
                                BorderBrush="#00BFFF"
                                Margin="0,0,5,0"/>
                        <Button x:Name="CancelButton"
                                Content="Cancel"
                                Grid.Column="1"
                                Height="30"
                                Background="#252525"
                                Foreground="White"
                                BorderBrush="#00BFFF"
                                Margin="5,0,0,0"/>
                    </Grid>
                </StackPanel>
            </Grid>
        </Border>
    </Window>
"@)

    $saveWindow.Owner = $window
    $presetNameBox = $saveWindow.FindName("PresetNameBox")
    $saveButton = $saveWindow.FindName("SaveButton")
    $cancelButton = $saveWindow.FindName("CancelButton")

    $saveButton.Add_Click({
        if ($presetNameBox.Text -ne "") {
            $preset = @{
                EnableRCS = $script:enableRCS
                RequireToggle = $script:requireToggle
                ToggleKey = $script:toggleKey
                VerticalRecoilMode = $script:verticalRecoilMode
                VerticalRecoilStrength = $script:verticalRecoilStrength
                VerticalDelay = $script:verticalDelay
                HorizontalDirection = $script:horizontalDirection
                HorizontalStrength = $script:horizontalStrength
                HorizontalDelay = $script:horizontalDelay
            }
            $preset | ConvertTo-Json | Set-Content "$presetDirectory\$($presetNameBox.Text).rcpreset"
            $saveWindow.Close()
        }
    })

    $cancelButton.Add_Click({ $saveWindow.Close() })
    $saveWindow.ShowDialog()
})

# Load Preset GUI and functionality
$loadPresetButton.Add_Click({
    $loadWindow = [Windows.Markup.XamlReader]::Parse(@"
    <Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Load Preset"
            Height="500"
            Width="400"
            WindowStyle="None"
            AllowsTransparency="True"
            Background="Transparent"
            WindowStartupLocation="CenterOwner">
        <Border Background="#0A0A0A"
                BorderBrush="#333333"
                BorderThickness="1"
                CornerRadius="10">
            <Grid Margin="15">
                <StackPanel>
                    <TextBlock Text="LOAD PRESET"
                             Foreground="#00BFFF"
                             FontSize="16"
                             FontWeight="Bold"
                             HorizontalAlignment="Center"
                             Margin="0,0,0,15"/>
                    <!-- Search Box -->
                    <TextBox x:Name="SearchBox"
                            Height="30"
                            Background="#252525"
                            Foreground="White"
                            BorderBrush="#00BFFF"
                            Padding="5"
                            Margin="0,0,0,10">
                        <TextBox.Style>
                            <Style TargetType="TextBox">
                                <Style.Triggers>
                                    <Trigger Property="Text" Value="">
                                        <Setter Property="Background" Value="#252525"/>
                                        <Setter Property="Template">
                                            <Setter.Value>
                                                <ControlTemplate TargetType="TextBox">
                                                    <Border Background="{TemplateBinding Background}"
                                                            BorderBrush="{TemplateBinding BorderBrush}"
                                                            BorderThickness="{TemplateBinding BorderThickness}">
                                                        <Grid>
                                                            <TextBlock Text="Search presets..." 
                                                                     Foreground="Gray" 
                                                                     Margin="5,5,0,0" 
                                                                     IsHitTestVisible="False">
                                                                <TextBlock.Style>
                                                                    <Style TargetType="TextBlock">
                                                                        <Style.Triggers>
                                                                            <DataTrigger Binding="{Binding Text, RelativeSource={RelativeSource Mode=FindAncestor, AncestorType=TextBox}}" Value="">
                                                                                <Setter Property="Visibility" Value="Visible"/>
                                                                            </DataTrigger>
                                                                        </Style.Triggers>
                                                                        <Setter Property="Visibility" Value="Hidden"/>
                                                                    </Style>
                                                                </TextBlock.Style>
                                                            </TextBlock>
                                                            <ScrollViewer x:Name="PART_ContentHost"/>
                                                        </Grid>
                                                    </Border>
                                                </ControlTemplate>
                                            </Setter.Value>
                                        </Setter>
                                    </Trigger>
                                </Style.Triggers>
                            </Style>
                        </TextBox.Style>
                    </TextBox>
                    <ListBox x:Name="PresetList"
                            Background="#252525"
                            Foreground="White"
                            BorderBrush="#00BFFF"
                            Height="330"
                            Margin="0,0,0,15"/>
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="LoadButton"
                                Content="Load"
                                Height="30"
                                Background="#252525"
                                Foreground="White"
                                BorderBrush="#00BFFF"
                                Margin="0,0,5,0"/>
                        <Button x:Name="RenameButton"
                                Content="Rename"
                                Grid.Column="1"
                                Height="30"
                                Background="#252525"
                                Foreground="White"
                                BorderBrush="#00BFFF"
                                Margin="5,0,5,0"/>
                        <Button x:Name="DeleteButton"
                                Content="Delete"
                                Grid.Column="2"
                                Height="30"
                                Background="#252525"
                                Foreground="White"
                                BorderBrush="#00BFFF"
                                Margin="5,0,0,0"/>
                       <Button x:Name="CancelButton"
                                Content="Cancel"
                                Grid.Column="3"
                                Height="30"
                                Background="#252525"
                                Foreground="White"
                                BorderBrush="#00BFFF"
                                Margin="5,0,0,0"/>
                    </Grid>
                </StackPanel>
            </Grid>
        </Border>
    </Window>
"@)

    $loadWindow.Owner = $window
    $presetList = $loadWindow.FindName("PresetList")
    $loadButton = $loadWindow.FindName("LoadButton")
    $renameButton = $loadWindow.FindName("RenameButton")
    $deleteButton = $loadWindow.FindName("DeleteButton")
    $cancelButton = $loadWindow.FindName("CancelButton")

    $cancelButton.Add_Click({ $loadWindow.Close() })

    # Store all presets in a variable
    $allPresets = @()
    Get-ChildItem -Path $presetDirectory -Filter "*.rcpreset" | ForEach-Object {
        $allPresets += $_.BaseName
        $presetList.Items.Add($_.BaseName)
    }

    # Add search functionality
    $searchBox = $loadWindow.FindName("SearchBox")
    $searchBox.Add_TextChanged({
        $searchText = $searchBox.Text.ToLower()
        $presetList.Items.Clear()
        
        if ($searchText -eq "") {
            $allPresets | ForEach-Object {
                $presetList.Items.Add($_)
            }
        } else {
            $filteredPresets = $allPresets | Where-Object { $_.ToLower().Contains($searchText) }
            $filteredPresets | ForEach-Object {
                $presetList.Items.Add($_)
            }
        }
    })

    # Double-click to load
    $presetList.Add_MouseDoubleClick({
        if ($presetList.SelectedItem) {
            LoadSelectedPreset
            $loadWindow.Close()
        }
    })

    # Load button click
    $loadButton.Add_Click({
        if ($presetList.SelectedItem) {
            LoadSelectedPreset
            $loadWindow.Close()
        }
    })

    # Delete button click
    $deleteButton.Add_Click({
        if ($presetList.SelectedItem) {
            $confirmWindow = [Windows.Markup.XamlReader]::Parse(@"
            <Window 
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                    Title="Confirm Delete"
                    Height="150"
                    Width="300"
                    WindowStyle="None"
                    AllowsTransparency="True"
                    Background="Transparent"
                    WindowStartupLocation="CenterOwner">
                <Border Background="#0A0A0A"
                        BorderBrush="#333333"
                        BorderThickness="1"
                        CornerRadius="10">
                    <Grid Margin="15">
                        <StackPanel>
                            <TextBlock Text="Delete Preset?"
                                     Foreground="#00BFFF"
                                     FontSize="16"
                                     FontWeight="Bold"
                                     HorizontalAlignment="Center"
                                     Margin="0,0,0,15"/>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Button x:Name="YesButton"
                                        Content="Yes"
                                        Height="30"
                                        Background="#252525"
                                        Foreground="White"
                                        BorderBrush="#00BFFF"
                                        Margin="0,0,5,0"/>
                                <Button x:Name="NoButton"
                                        Content="No"
                                        Grid.Column="1"
                                        Height="30"
                                        Background="#252525"
                                        Foreground="White"
                                        BorderBrush="#00BFFF"
                                        Margin="5,0,0,0"/>
                            </Grid>
                        </StackPanel>
                    </Grid>
                </Border>
            </Window>
"@)

        $confirmWindow.Owner = $loadWindow
        $yesButton = $confirmWindow.FindName("YesButton")
        $noButton = $confirmWindow.FindName("NoButton")
        
        $yesButton.Add_Click({
            $itemToDelete = $presetList.SelectedItem
            Remove-Item "$presetDirectory\$itemToDelete.rcpreset"
            $presetList.Items.Remove($itemToDelete)
            $script:allPresets = $allPresets | Where-Object { $_ -ne $itemToDelete }
            $confirmWindow.Close()
        })
        
        $noButton.Add_Click({ $confirmWindow.Close() })
        $confirmWindow.ShowDialog()
    }
})

# Rename button click handler
$renameButton.Add_Click({
    if ($presetList.SelectedItem) {
        $oldName = $presetList.SelectedItem
        $renameWindow = [Windows.Markup.XamlReader]::Parse(@"
            <Window 
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                    Title="Rename Preset"
                    Height="180"
                    Width="300"
                    WindowStyle="None"
                    AllowsTransparency="True"
                    Background="Transparent"
                    WindowStartupLocation="CenterOwner">
                <Border Background="#0A0A0A"
                        BorderBrush="#333333"
                        BorderThickness="1"
                        CornerRadius="10">
                    <Grid Margin="15">
                        <StackPanel>
                            <TextBlock Text="RENAME PRESET"
                                     Foreground="#00BFFF"
                                     FontSize="16"
                                     FontWeight="Bold"
                                     HorizontalAlignment="Center"
                                     Margin="0,0,0,15"/>
                            <TextBox x:Name="NewNameBox"
                                    Height="30"
                                    Background="#252525"
                                    Foreground="White"
                                    BorderBrush="#00BFFF"
                                    Padding="5"
                                    Margin="0,0,0,15"/>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Button x:Name="RenameConfirmButton"
                                        Content="Rename"
                                        Height="30"
                                        Background="#252525"
                                        Foreground="White"
                                        BorderBrush="#00BFFF"
                                        Margin="0,0,5,0"/>
                                <Button x:Name="CancelButton"
                                        Content="Cancel"
                                        Grid.Column="1"
                                        Height="30"
                                        Background="#252525"
                                        Foreground="White"
                                        BorderBrush="#00BFFF"
                                        Margin="5,0,0,0"/>
                            </Grid>
                        </StackPanel>
                    </Grid>
                </Border>
            </Window>
"@)

        $renameWindow.Owner = $loadWindow
        $newNameBox = $renameWindow.FindName("NewNameBox")
        $renameConfirmButton = $renameWindow.FindName("RenameConfirmButton")
        $cancelButton = $renameWindow.FindName("CancelButton")
        $newNameBox.Text = $oldName

        $renameConfirmButton.Add_Click({
            if ($newNameBox.Text -ne "") {
                Rename-Item "$presetDirectory\$oldName.rcpreset" "$presetDirectory\$($newNameBox.Text).rcpreset"
                $selectedIndex = $presetList.SelectedIndex
                $presetList.Items.RemoveAt($selectedIndex)
                $presetList.Items.Insert($selectedIndex, $newNameBox.Text)
                
                # Updated array handling
                $index = [array]::IndexOf($allPresets, $oldName)
                if ($index -ne -1) {
                    $allPresets[$index] = $newNameBox.Text
                }
                
                $presetList.SelectedIndex = $selectedIndex
                $renameWindow.Close()
            }
        })

        $cancelButton.Add_Click({ $renameWindow.Close() })
        $renameWindow.ShowDialog()
    }
})

$loadWindow.ShowDialog()
})

    # Function to load selected preset
    function LoadSelectedPreset {
        $preset = Get-Content "$presetDirectory\$($presetList.SelectedItem).rcpreset" | ConvertFrom-Json
        
        # Current Preset
        $currentPresetText = $window.FindName("CurrentPresetText")
        $currentPresetText.Text = "Preset: $($presetList.SelectedItem)"

        $enableRCSCheckBox.IsChecked = $preset.EnableRCS
        $requireToggleCheckBox.IsChecked = $preset.RequireToggle
        $toggleKeyComboBox.SelectedItem = $toggleKeyComboBox.Items | 
            Where-Object { $_.Content -eq $preset.ToggleKey }
        
        $verticalRecoilModeComboBox.SelectedItem = $verticalRecoilModeComboBox.Items | 
            Where-Object { $_.Content -eq $preset.VerticalRecoilMode }
        
        $verticalCustomStrengthTextBox.Text = $preset.VerticalRecoilStrength
        $verticalCustomStrengthSlider.Value = $preset.VerticalRecoilStrength
        $verticalDelayTextBox.Text = $preset.VerticalDelay
        $verticalDelaySlider.Value = $preset.VerticalDelay
        
        $horizontalDirectionComboBox.SelectedItem = $horizontalDirectionComboBox.Items | 
            Where-Object { $_.Content -eq $preset.HorizontalDirection }
        
        $horizontalStrengthTextBox.Text = $preset.HorizontalStrength
        $horizontalStrengthSlider.Value = $preset.HorizontalStrength
        $horizontalDelayTextBox.Text = $preset.HorizontalDelay
        $horizontalDelaySlider.Value = $preset.HorizontalDelay
    }

# Window drag functionality
$window.Add_MouseLeftButtonDown({
    $window.DragMove()
})

# Start timers
$verticalTimer.Start()
$horizontalTimer.Start()

# Show window
$window.ShowDialog()

function Clear-Traces {
    # Overwrite sensitive variables
    $script:enableRCS = $null
    $script:verticalRecoilStrength = $null
    $script:toggleKey = $null
    
    # Force garbage collection
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
}

# Cleanup
$window.Add_Closed({
    $verticalTimer.Stop()
    $horizontalTimer.Stop()
    $spoofTimer.Stop()
    $verticalTimer.Dispose()
    $horizontalTimer.Dispose()
    $spoofTimer.Dispose()
    Clear-Traces  # Call the cleanup function
})
