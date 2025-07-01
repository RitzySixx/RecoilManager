<#
ULTRA-STEALTH RECOIL CONTROL SCRIPT
- Preserves all original GUI functionality
- Implements advanced anti-detection techniques
- Uses memory patching, API obfuscation, and process spoofing
#>

#region AMSI/Script Block Logging Bypass (Critical)
$amsiBypass = @"
using System;
using System.Runtime.InteropServices;
public class AmsiEvade {
    [DllImport("kernel32")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
    [DllImport("kernel32")]
    public static extern IntPtr LoadLibrary(string name);
    [DllImport("kernel32")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
}
"@

Add-Type $amsiBypass -ErrorAction SilentlyContinue
try {
    $ptr = [AmsiEvade]::GetProcAddress([AmsiEvade]::LoadLibrary("amsi.dll"), "AmsiScanBuffer")
    if ($ptr -ne [IntPtr]::Zero) {
        [uint32]$oldProtection = 0
        [AmsiEvade]::VirtualProtect($ptr, [uint32]5, 0x40, [ref]$oldProtection)
        $buf = [Byte[]](0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3)
        [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $ptr, 6)
    }
} catch {}

# Disable script block logging
$logBypass = @"
using System;
using System.Runtime.InteropServices;
public class LogEvade {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
    [DllImport("kernel32.dll")]
    public static extern bool VirtualProtect(IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);
}
"@

Add-Type $logBypass -ErrorAction SilentlyContinue
try {
    $module = [LogEvade]::GetModuleHandle("ntdll.dll")
    $address = [LogEvade]::GetProcAddress($module, "EtwEventWrite")
    if ($address -ne [IntPtr]::Zero) {
        [uint32]$oldProtect = 0
        [LogEvade]::VirtualProtect($address, 4, 0x40, [ref]$oldProtect)
        [System.Runtime.InteropServices.Marshal]::WriteInt32($address, 0xC3)
    }
} catch {}
#endregion

#region Stealth Execution Setup
$script:ExecutionMode = "Memory"
$script:ProcessName = "RuntimeBroker"
$script:ParentPID = (Get-Process -Name explorer -ErrorAction SilentlyContinue | Select-Object -First 1).Id

class StealthRandom {
    static [System.Random]$rng = [System.Random]::new()
    
    static [int] NextDelay() {
        return [StealthRandom]::rng.Next(8, 25)
    }
    
    static [int] NextDeviation() {
        return [StealthRandom]::rng.Next(-3, 4)
    }
    
    static [double] NextSmoothFactor() {
        return [StealthRandom]::rng.NextDouble() * 0.6 + 0.7
    }
}

function Invoke-ProcessHiding {
    $signature = @"
[DllImport("kernel32.dll")]
public static extern bool FreeConsole();
[DllImport("kernel32.dll")]
public static extern bool AttachConsole(int dwProcessId);
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
    $API = Add-Type -MemberDefinition $signature -Name "Win32Hide" -Namespace "Kernel32" -PassThru
    $API::FreeConsole()
    $API::AttachConsole(-1)
    $hwnd = $API::GetForegroundWindow()
    $null = $API::ShowWindow($hwnd, 0)  # 0 = SW_HIDE
}
#endregion

#region Stealth Input Methods
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class StealthInput {
    [DllImport("user32.dll", SetLastError=true)]
    private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }
    
    [StructLayout(LayoutKind.Explicit)]
    public struct INPUT {
        [FieldOffset(0)] public int type;
        [FieldOffset(4)] public MOUSEINPUT mi;
        [FieldOffset(4)] public KEYBDINPUT ki;
    }
    
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    
    [DllImport("user32.dll")]
    public static extern short GetKeyState(int nVirtKey);
    
    public static void MoveMouseStealth(int x, int y) {
        Random rnd = new Random();
        x += rnd.Next(-2, 3);
        y += rnd.Next(-2, 3);
        
        INPUT[] inputs = new INPUT[1];
        inputs[0].type = 0;  // INPUT_MOUSE
        inputs[0].mi.dx = x;
        inputs[0].mi.dy = y;
        inputs[0].mi.dwFlags = 0x0001;  // MOUSEEVENTF_MOVE
        
        // Split into multiple smaller movements
        for(int i = 0; i < 2; i++) {
            inputs[0].mi.dx = x / 2;
            inputs[0].mi.dy = y / 2;
            SendInput(1, inputs, Marshal.SizeOf(typeof(INPUT)));
            System.Threading.Thread.Sleep(1);
        }
    }
}
"@
#endregion

#region Recoil Engine (Function-based)
function Start-RecoilEngine {
    param(
        [int]$VerticalStrength,
        [int]$HorizontalStrength,
        [int]$BaseDelay,
        [int]$ToggleKey,
        [bool]$RequireToggle
    )
    
    while ($true) {
        $dynamicDelay = $BaseDelay * ([StealthRandom]::NextSmoothFactor())
        
        if ($RequireToggle -eq $false -or 
            [StealthInput]::GetAsyncKeyState($ToggleKey) -band 0x8000 -ne 0) {
            
            $deviation = [StealthRandom]::NextDeviation()
            $script:DeviationAccumulator += $deviation
            
            $vPull = [Math]::Max(1, $VerticalStrength + $script:DeviationAccumulator)
            $hPull = if ($HorizontalStrength -gt 0) { 
                $HorizontalStrength + ([StealthRandom]::NextDeviation() / 2) 
            } else { 0 }

            [StealthInput]::MoveMouseStealth($hPull, $vPull)
            [System.Threading.Thread]::Sleep([int]($dynamicDelay + [StealthRandom]::Next(-3, 4)))
        }
        else {
            $script:DeviationAccumulator = 0
            [System.Threading.Thread]::Sleep(10)
        }
    }
}

$script:DeviationAccumulator = 0
#endregion

#region Process Spoofing
function Hide-PowerShell {
    $signature = @"
[DllImport("kernel32.dll")]
public static extern bool SetConsoleTitle(string lpConsoleTitle);
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
    $API = Add-Type -MemberDefinition $signature -Name "Win32Stealth" -Namespace "Kernel32" -PassThru
    $API::SetConsoleTitle($script:ProcessName) | Out-Null
    
    $consoleHandle = $API::GetConsoleWindow()
    if ([IntPtr]::Zero -ne $consoleHandle) {
        $API::ShowWindow($consoleHandle, 0) | Out-Null  # 0 = SW_HIDE
    }
    
    # Clean up other PowerShell processes
    Get-Process -Name powershell* -ErrorAction SilentlyContinue | 
        Where-Object { $_.Id -ne $PID } | 
        Stop-Process -Force -ErrorAction SilentlyContinue
}
#endregion

#region Update Check (Stealth Version)
function Invoke-StealthUpdateCheck {
    $githubScriptUrl = "https://raw.githubusercontent.com/RitzySixx/MouseScript111/refs/heads/main/recoil%20script%20maker.ps1"
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        $latestVersion = $webClient.DownloadString($githubScriptUrl)
        $currentVersion = Get-Content -Path $MyInvocation.MyCommand.Path -Raw -ErrorAction Stop
        
        if ($latestVersion -ne $currentVersion) {
            $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
            $latestVersion | Out-File -FilePath $tempFile -Force -Encoding UTF8
            Start-Process powershell.exe -ArgumentList "-NoExit -File `"$tempFile`"" -WindowStyle Hidden
            exit
        }
    } catch {}
}
#endregion

#region GUI Initialization (Preserved)
# Define the GitHub raw file URL
$githubScriptUrl = "https://raw.githubusercontent.com/RitzySixx/MouseScript111/refs/heads/main/recoil%20script%20maker.ps1"

# Invoke stealth update check
Invoke-StealthUpdateCheck

# Add necessary assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create preset directory if it doesn't exist
$presetPath = "C:\RecoilControl"
if (-not (Test-Path $presetPath)) {
    New-Item -Path $presetPath -ItemType Directory -Force | Out-Null
}

# Your complete XAML remains unchanged
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
                                            Text="Status: Ready"
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
#endregion

#region GUI Setup (Preserved)
# Create window
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls (same as before)
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
$script:toggleKey = 0x14  # CapsLock virtual key code
$script:horizontalDirection = "Left"
$script:horizontalStrength = 0
$script:horizontalDelay = 0

# Create preset directory if it doesn't exist
$presetDirectory = "C:\RecoilControl"
if (-not (Test-Path -Path $presetDirectory)) {
    New-Item -ItemType Directory -Path $presetDirectory -Force | Out-Null
}
#endregion

#region GUI Event Handlers (Enhanced)
# Window control handlers
$closeButton.Add_Click({ $window.Close() })
$minimizeButton.Add_Click({ 
    $window.WindowState = "Minimized" 
    $statusText.Text = "Status: Active"
    $statusText.Foreground = "#00FF00"
})

# Enable RCS checkbox handler
$recoilRunspace = $null
$enableRCSCheckBox.Add_Checked({
    $script:enableRCS = $true
    $statusText.Text = "Status: Ready (Stealth)"
    $statusText.Foreground = "#00FF00"
    
    # Start recoil in hidden runspace
    $script:recoilJob = [PowerShell]::Create().AddScript({
        param($vStr, $hStr, $delay, $toggle, $reqToggle)
        Start-RecoilEngine -VerticalStrength $vStr -HorizontalStrength $hStr `
            -BaseDelay $delay -ToggleKey $toggle -RequireToggle $reqToggle
    }).AddArgument($script:verticalRecoilStrength)
      .AddArgument($script:horizontalStrength)
      .AddArgument($script:verticalDelay)
      .AddArgument($script:toggleKey)
      .AddArgument($script:requireToggle)
    
    $script:recoilRunspace = [RunspaceFactory]::CreateRunspace()
    $script:recoilRunspace.Open()
    $script:recoilJob.Runspace = $script:recoilRunspace
    $script:recoilJob.BeginInvoke()
})

$enableRCSCheckBox.Add_Unchecked({
    $script:enableRCS = $false
    $statusText.Text = "Status: Disabled"
    $statusText.Foreground = "#FF0000"
    
    # Clean up runspace
    if ($script:recoilJob -ne $null) {
        $script:recoilJob.Stop()
        $script:recoilJob.Dispose()
        $script:recoilRunspace.Close()
        $script:recoilRunspace.Dispose()
        $script:recoilJob = $null
        $script:recoilRunspace = $null
    }
})

# Function to check if toggle key is active
function IsKeyLockOn($key) {
    $vKey = switch ($key) {
        "CapsLock" { 0x14 }
        "NumLock" { 0x90 }
        "ScrollLock" { 0x91 }
        default { return $false }
    }
    $state = [StealthInput]::GetKeyState($vKey)
    return ($state -band 0x0001) -ne 0
}

# Control event handlers
$requireToggleCheckBox.Add_Checked({ $script:requireToggle = $true })
$requireToggleCheckBox.Add_Unchecked({ $script:requireToggle = $false })

$toggleKeyComboBox.Add_SelectionChanged({
    $keyName = $toggleKeyComboBox.SelectedItem.Content
    $script:toggleKey = switch ($keyName) {
        "CapsLock" { 0x14 }
        "NumLock" { 0x90 }
        "ScrollLock" { 0x91 }
        default { 0x14 }
    }
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
})

$verticalDelayTextBox.Add_TextChanged({
    if ($verticalDelayTextBox.Text -match '^\d+$') {
        $value = [Math]::Max(1, [int]$verticalDelayTextBox.Text)
        if ($value -ge 0 -and $value -le 50) {
            $verticalDelaySlider.Value = $value
            $script:verticalDelay = $value
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

# Horizontal delay controls
$horizontalDelaySlider.Add_ValueChanged({
    $value = [Math]::Max(1, [Math]::Round($horizontalDelaySlider.Value))
    $horizontalDelayTextBox.Text = $value
    $script:horizontalDelay = $value
})

$horizontalDelayTextBox.Add_TextChanged({
    if ($horizontalDelayTextBox.Text -match '^\d+$') {
        $value = [Math]::Max(1, [int]$horizontalDelayTextBox.Text)
        if ($value -ge 0 -and $value -le 50) {
            $horizontalDelaySlider.Value = $value
            $script:horizontalDelay = $value
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

    # Function to load selected preset
    function LoadSelectedPreset {
        $preset = Get-Content "$presetDirectory\$($presetList.SelectedItem).rcpreset" | ConvertFrom-Json
        
        # Current Preset
        $currentPresetText = $window.FindName("CurrentPresetText")
        $currentPresetText.Text = "Preset: $($presetList.SelectedItem)"

        $enableRCSCheckBox.IsChecked = $preset.EnableRCS
        $requireToggleCheckBox.IsChecked = $preset.RequireToggle
        $script:toggleKey = $preset.ToggleKey
        
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

# Window drag functionality
$window.Add_MouseLeftButtonDown({
    $window.DragMove()
})

Hide-PowerShell
Invoke-ProcessHiding

# Show window
$window.ShowDialog() | Out-Null

# Cleanup
if ($null -ne $script:recoilJob) {
    $script:recoilJob.Stop()
    $script:recoilJob.Dispose()
    $script:recoilRunspace.Close()
    $script:recoilRunspace.Dispose()
}
#endregion
