# Define the GitHub raw file URL
$githubScriptUrl = "https://raw.githubusercontent.com/RitzySixx/MouseScript111/refs/heads/main/recoil%20script%20maker.ps1"

# Get the current script path
$currentScript = $MyInvocation.MyCommand.Path

# Check for updates
try {
    $latestVersion = ((Invoke-WebRequest -Uri $githubScriptUrl).Content).Trim()
    $currentVersion = (Get-Content -Path $currentScript -Raw).Trim()

    if ($latestVersion -ne $currentVersion) {
        Write-Host "Update found! Grabbing latest version..." -ForegroundColor Green
        $latestVersion | Out-File -FilePath $currentScript -Force -Encoding UTF8
        Write-Host "Script will restart once Update is Complete..." -ForegroundColor Green
        Start-Sleep -Seconds 10
        Start-Process powershell.exe -ArgumentList "-NoExit -File `"$currentScript`""
        exit
    }
} catch {
    Write-Host "Unable to check for updates. Continuing with current version..." -ForegroundColor Yellow
}

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Then load the rest of the assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

function Test-MouseOverWindow {
    $point = [System.Windows.Forms.Cursor]::Position
    $windowRect = New-Object System.Drawing.Rectangle(
        [int]$window.Left, 
        [int]$window.Top, 
        [int]$window.Width, 
        [int]$window.Height
    )
    return $windowRect.Contains($point)
}

# Conversion functions
function Convert-RecoilValue {
    param (
        [double]$recoilValue,
        [double]$sourceDPI,
        [double]$sourceSens,
        [double]$sourceMultiplier,
        [double]$targetDPI,
        [double]$targetSens,
        [double]$targetMultiplier
    )
    
    $sourceTotal = $sourceDPI * $sourceSens * $sourceMultiplier
    $targetTotal = $targetDPI * $targetSens * $targetMultiplier
    
    return $recoilValue * ($sourceTotal / $targetTotal)
}

function Save-Settings {
    param (
        [string]$dpi,
        [string]$sens,
        [string]$multiplier
    )
    
    $settingsXml = [xml]"<Settings><DPI>$dpi</DPI><Sensitivity>$sens</Sensitivity><Multiplier>$multiplier</Multiplier></Settings>"
    $settingsPath = Join-Path "C:\Recoil Presets" "settings.xaml"
    $settingsXml.Save($settingsPath)
}

function Load-Settings {
    $settingsPath = Join-Path "C:\Recoil Presets" "settings.xaml"
    if (Test-Path $settingsPath) {
        [xml]$settings = Get-Content $settingsPath
        return @{
            DPI = $settings.Settings.DPI
            Sensitivity = $settings.Settings.Sensitivity
            Multiplier = $settings.Settings.Multiplier
        }
    }
    return $null
}

# Add mouse button codes
$mouseButtonCodes = @{
    "Left" = 0x01
    "Right" = 0x02
    "Middle" = 0x04
    "XButton1" = 0x05  # First side button
    "XButton2" = 0x06  # Second side button
    "XButton3" = 0x07  # Third side button (if available)
    "XButton4" = 0x08  # Fourth side button (if available)
}

# Create and verify preset directory with full permissions
$presetPath = "C:\Recoil Presets"
if (-not (Test-Path $presetPath)) {
    New-Item -ItemType Directory -Path $presetPath -Force
    $acl = Get-Acl $presetPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl $presetPath $acl
}

# Initialize paths
$presetPath = "C:\Recoil Presets"
$defaultPresetFile = Join-Path $presetPath "default.json"

# Smart directory and file creation with enhanced error handling
try {
    if (Test-Path $presetPath) {
        if (-not (Test-Path $defaultPresetFile)) {
            $defaultPreset = @{
                XLeft = 0
                XRight = 0
                YDown = 0
                YUp = 0
                Keybind = $null
                IsMouseBind = $false
            }
            $defaultPreset | ConvertTo-Json | Set-Content $defaultPresetFile -Force -ErrorAction Stop
            Write-Host "Default preset created successfully" -ForegroundColor Green
        }
    } else {
        New-Item -ItemType Directory -Path $presetPath -Force | Out-Null
        $defaultPreset = @{
            XLeft = 0
            XRight = 0
            YDown = 0
            YUp = 0
            Keybind = $null
            IsMouseBind = $false
        }
        $defaultPreset | ConvertTo-Json | Set-Content $defaultPresetFile -Force -ErrorAction Stop
        Write-Host "Preset directory and default preset created successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "Creating preset directory with elevated permissions..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-Command New-Item -ItemType Directory -Path '$presetPath' -Force; Set-Content -Path '$defaultPresetFile' -Value '$($defaultPreset | ConvertTo-Json)' -Force"
}

# Verify preset directory is ready
if (Test-Path $presetPath) {
    Write-Host "Preset directory is ready for use" -ForegroundColor Green
} else {
    Write-Host "Please run the script with administrator privileges to create the preset directory" -ForegroundColor Red
}

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Ritzy"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    Width="675"
    Height="600"
    ResizeMode="NoResize"
    WindowStartupLocation="CenterScreen"
    Topmost="True">

    <Window.Resources>
        <ResourceDictionary>
            <!-- Ultra Modern Colors -->
            <SolidColorBrush x:Key="AccentColor" Color="#FF0066"/>
            <SolidColorBrush x:Key="BackgroundPrimary" Color="#0A0A0A"/>
            <SolidColorBrush x:Key="BackgroundSecondary" Color="#141414"/>
            <SolidColorBrush x:Key="TextPrimary" Color="#FFFFFF"/>
            <SolidColorBrush x:Key="TextSecondary" Color="#B0B0B0"/>
            <SolidColorBrush x:Key="BorderBrush" Color="#1E1E1E"/>

            <!-- Modern Text Styles -->
            <Style x:Key="HeaderTextStyle" TargetType="TextBlock">
                <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                <Setter Property="FontSize" Value="22"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="FontFamily" Value="Segoe UI"/>
            </Style>

            <Style x:Key="LabelTextStyle" TargetType="TextBlock">
                <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="FontWeight" Value="Medium"/>
                <Setter Property="FontFamily" Value="Segoe UI"/>
            </Style>

            <!-- Ultra Modern Button Style -->
            <Style x:Key="ModernButtonStyle" TargetType="Button">
                <Setter Property="Background" Value="{StaticResource BackgroundSecondary}"/>
                <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Height" Value="38"/>
                <Setter Property="Width" Value="140"/>
                <Setter Property="FontSize" Value="12"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}"
                                    CornerRadius="6">
                                <ContentPresenter HorizontalAlignment="Center" 
                                                VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="{StaticResource AccentColor}"/>
                                </Trigger>
                                <Trigger Property="IsPressed" Value="True">
                                    <Setter TargetName="border" Property="Opacity" Value="0.8"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- Enhanced Slider Style -->
            <Style x:Key="ModernSliderStyle" TargetType="Slider">
                <Setter Property="Margin" Value="5,8,15,8"/>
                <Setter Property="Width" Value="350"/>
                <Setter Property="Height" Value="24"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Slider">
                            <Grid>
                                <Border x:Name="TrackBackground" 
                                        Background="{StaticResource BorderBrush}"
                                        Height="6"
                                        CornerRadius="3"/>
                                <Track x:Name="PART_Track">
                                    <Track.DecreaseRepeatButton>
                                        <RepeatButton Command="{x:Static Slider.DecreaseLarge}">
                                            <RepeatButton.Template>
                                                <ControlTemplate TargetType="RepeatButton">
                                                    <Border Height="6" CornerRadius="3">
                                                        <Border.Background>
                                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                                <GradientStop Color="#FF0000" Offset="0"/>
                                                                <GradientStop Color="#FF69B4" Offset="1"/>
                                                            </LinearGradientBrush>
                                                        </Border.Background>
                                                    </Border>
                                                </ControlTemplate>
                                            </RepeatButton.Template>
                                        </RepeatButton>
                                    </Track.DecreaseRepeatButton>
                                    <Track.IncreaseRepeatButton>
                                        <RepeatButton Command="{x:Static Slider.IncreaseLarge}">
                                            <RepeatButton.Template>
                                                <ControlTemplate TargetType="RepeatButton">
                                                    <Border Background="{StaticResource BorderBrush}" Height="6" CornerRadius="3"/>
                                                </ControlTemplate>
                                            </RepeatButton.Template>
                                        </RepeatButton>
                                    </Track.IncreaseRepeatButton>
                                    <Track.Thumb>
                                        <Thumb>
                                            <Thumb.Template>
                                                <ControlTemplate TargetType="Thumb">
                                                    <Ellipse Width="16" Height="16">
                                                        <Ellipse.Fill>
                                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                                                <GradientStop Color="#FF0000" Offset="0"/>
                                                                <GradientStop Color="#FF69B4" Offset="1"/>
                                                            </LinearGradientBrush>
                                                        </Ellipse.Fill>
                                                    </Ellipse>
                                                </ControlTemplate>
                                            </Thumb.Template>
                                        </Thumb>
                                    </Track.Thumb>
                                </Track>
                            </Grid>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- Modern TextBox Style -->
            <Style x:Key="ModernTextBoxStyle" TargetType="TextBox">
                <Setter Property="Background" Value="{StaticResource BackgroundSecondary}"/>
                <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Width" Value="70"/>
                <Setter Property="Height" Value="32"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="FontWeight" Value="Medium"/>
                <Setter Property="TextAlignment" Value="Center"/>
                <Setter Property="VerticalContentAlignment" Value="Center"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="TextBox">
                            <Border Background="{TemplateBinding Background}"
                                    CornerRadius="6">
                                <ScrollViewer x:Name="PART_ContentHost" Margin="5,2"/>
                            </Border>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </ResourceDictionary>
    </Window.Resources>

    <Border CornerRadius="10" Background="{StaticResource BackgroundPrimary}">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="45"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Title Bar -->
            <Border Grid.Row="0" 
                    Background="{StaticResource BackgroundSecondary}" 
                    CornerRadius="10,10,0,0">
                <Grid>
                    <StackPanel Orientation="Horizontal" 
                               Margin="15,0,0,0"
                               VerticalAlignment="Center">
                        <TextBlock Text="RITZY" 
                                 Style="{StaticResource HeaderTextStyle}"/>
                        <TextBlock Text="PRO" 
                                 Foreground="{StaticResource AccentColor}"
                                 Style="{StaticResource HeaderTextStyle}"
                                 Margin="5,0,0,0"/>
                    </StackPanel>
                    
                    <StackPanel Orientation="Horizontal" 
                              HorizontalAlignment="Right" 
                              Margin="0,0,10,0">
                        <Button x:Name="MinimizeButton" 
                                Content="─" 
                                Width="35" 
                                Height="28"
                                Style="{StaticResource ModernButtonStyle}" 
                                Margin="0,0,5,0"/>
                        <Button x:Name="CloseButton" 
                                Content="×" 
                                Width="35" 
                                Height="28"
                                Style="{StaticResource ModernButtonStyle}" 
                                Margin="0"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Main Content -->
            <Border Grid.Row="1" Margin="12">
                <Grid>
                    <StackPanel>
                        <TextBlock x:Name="ActivePreset" 
                                  Text="SELECT YOUR PRESET" 
                                  Style="{StaticResource HeaderTextStyle}"
                                  HorizontalAlignment="Center"
                                  Margin="0,0,0,20"/>

                <!-- Settings Section -->
                <Border Background="{StaticResource BackgroundSecondary}" 
                        CornerRadius="8" 
                        Padding="20" 
                        Margin="0,0,0,15">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        
                        <StackPanel Grid.Column="0" Margin="5">
                            <TextBlock Text="DPI" 
                                    Style="{StaticResource LabelTextStyle}"
                                    Margin="0,0,0,5"/>
                            <TextBox x:Name="DPIInput"
                                    Style="{StaticResource ModernTextBoxStyle}"
                                    Text="800"/>
                        </StackPanel>
                        
                        <StackPanel Grid.Column="1" Margin="5">
                            <TextBlock Text="In-Game Sens" 
                                    Style="{StaticResource LabelTextStyle}"
                                    Margin="0,0,0,5"/>
                            <TextBox x:Name="SensInput"
                                    Style="{StaticResource ModernTextBoxStyle}"
                                    Text="50"/>
                        </StackPanel>
                        
                        <StackPanel Grid.Column="2" Margin="5">
                            <TextBlock Text="Multiplier" 
                                    Style="{StaticResource LabelTextStyle}"
                                    Margin="0,0,0,5"/>
                            <TextBox x:Name="MultiplierInput"
                                    Style="{StaticResource ModernTextBoxStyle}"
                                    Text="0.02"/>
                        </StackPanel>
                    </Grid>
                </Border>         

                        <!-- Sliders Section -->
                        <Border Background="{StaticResource BackgroundSecondary}" 
                                CornerRadius="8" 
                                Padding="20" 
                                Margin="0,0,0,15">
                            <StackPanel>
                                <!-- X Axis Left -->
                                <DockPanel Margin="0,8">
                                    <TextBlock Text="X Axis Left" 
                                             Style="{StaticResource LabelTextStyle}"
                                             Width="100"
                                             VerticalAlignment="Center"/>
                                    <TextBox Text="{Binding Value, ElementName=XLeftSlider, StringFormat=N2}"
                                            Style="{StaticResource ModernTextBoxStyle}"
                                            Margin="0,0,15,0"/>
                                    <Slider x:Name="XLeftSlider" 
                                            Style="{StaticResource ModernSliderStyle}" 
                                            Minimum="0" Maximum="1500" Value="0"
                                            TickFrequency="0.01"
                                            IsSnapToTickEnabled="True"/>
                                </DockPanel>

                                <!-- X Axis Right -->
                                <DockPanel Margin="0,8">
                                    <TextBlock Text="X Axis Right" 
                                             Style="{StaticResource LabelTextStyle}"
                                             Width="100"
                                             VerticalAlignment="Center"/>
                                    <TextBox Text="{Binding Value, ElementName=XRightSlider, StringFormat=N2}"
                                            Style="{StaticResource ModernTextBoxStyle}"
                                            Margin="0,0,15,0"/>
                                    <Slider x:Name="XRightSlider" 
                                            Style="{StaticResource ModernSliderStyle}" 
                                            Minimum="0" Maximum="1500" Value="0"
                                            TickFrequency="0.01"
                                            IsSnapToTickEnabled="True"/>
                                </DockPanel>

                                <!-- Y Axis Down -->
                                <DockPanel Margin="0,8">
                                    <TextBlock Text="Y Axis Down" 
                                             Style="{StaticResource LabelTextStyle}"
                                             Width="100"
                                             VerticalAlignment="Center"/>
                                    <TextBox Text="{Binding Value, ElementName=YDownSlider, StringFormat=N2}"
                                            Style="{StaticResource ModernTextBoxStyle}"
                                            Margin="0,0,15,0"/>
                                    <Slider x:Name="YDownSlider" 
                                            Style="{StaticResource ModernSliderStyle}" 
                                            Minimum="0" Maximum="1500" Value="0"
                                            TickFrequency="0.01"
                                            IsSnapToTickEnabled="True"/>
                                </DockPanel>

                                <!-- Y Axis Up -->
                                <DockPanel Margin="0,8">
                                    <TextBlock Text="Y Axis Up" 
                                             Style="{StaticResource LabelTextStyle}"
                                             Width="100"
                                             VerticalAlignment="Center"/>
                                    <TextBox Text="{Binding Value, ElementName=YUpSlider, StringFormat=N2}"
                                            Style="{StaticResource ModernTextBoxStyle}"
                                            Margin="0,0,15,0"/>
                                    <Slider x:Name="YUpSlider" 
                                            Style="{StaticResource ModernSliderStyle}" 
                                            Minimum="0" Maximum="1500" Value="0"
                                            TickFrequency="0.01"
                                            IsSnapToTickEnabled="True"/>
                                </DockPanel>
                            </StackPanel>
                        </Border>

                        <!-- Control Buttons -->
                        <Border Background="{StaticResource BackgroundSecondary}" 
                                CornerRadius="8" 
                                Padding="20">
                            <StackPanel Orientation="Horizontal" 
                                      HorizontalAlignment="Center">
                                <Button x:Name="LoadPreset" 
                                        Content="LOAD PRESET" 
                                        Style="{StaticResource ModernButtonStyle}"
                                        Margin="8,0"/>
                                <Button x:Name="MasterKeybind" 
                                        Content="SET KEYBIND" 
                                        Style="{StaticResource ModernButtonStyle}"
                                        Margin="8,0"/>
                                <Button x:Name="SavePreset" 
                                        Content="SAVE PRESET" 
                                        Style="{StaticResource ModernButtonStyle}"
                                        Margin="8,0"/>
                                <Button x:Name="RightLeftBind"
                                        Content="SET R+L CLICK"
                                        Style="{StaticResource ModernButtonStyle}"
                                        Margin="8,0"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

# Create window
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$closeButton = $window.FindName("CloseButton")
$minimizeButton = $window.FindName("MinimizeButton")
$masterKeybind = $window.FindName("MasterKeybind")
$loadPreset = $window.FindName("LoadPreset")
$savePreset = $window.FindName("SavePreset")
$activePreset = $window.FindName("ActivePreset")
$XLeftSlider = $window.FindName("XLeftSlider")
$XRightSlider = $window.FindName("XRightSlider")
$YDownSlider = $window.FindName("YDownSlider")
$YUpSlider = $window.FindName("YUpSlider")
$DPIInput = $window.FindName("DPIInput")
$SensInput = $window.FindName("SensInput")
$MultiplierInput = $window.FindName("MultiplierInput")

$DPIInput.Text = "800"
$SensInput.Text = "50"
$MultiplierInput.Text = "0.02"

# Initialize variables
$script:masterKey = $null
$script:isKeyActive = $false
$script:isMouseBind = $false

# Window control handlers
$closeButton.Add_Click({ $window.Close() })
$minimizeButton.Add_Click({ $window.WindowState = "Minimized" })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Load saved settings
$savedSettings = Load-Settings
if ($savedSettings) {
    $DPIInput.Text = $savedSettings.DPI
    $SensInput.Text = $savedSettings.Sensitivity  
    $MultiplierInput.Text = $savedSettings.Multiplier
}

# Add TextChanged handlers
$DPIInput.Add_TextChanged({
    if ([double]::TryParse($DPIInput.Text, [ref]$null)) {
        $value = [double]$DPIInput.Text
        if ($value -gt 0) {
            Save-Settings -dpi $DPIInput.Text -sens $SensInput.Text -multiplier $MultiplierInput.Text
        }
    }
})

$SensInput.Add_TextChanged({
    if ([double]::TryParse($SensInput.Text, [ref]$null)) {
        Save-Settings -dpi $DPIInput.Text -sens $SensInput.Text -multiplier $MultiplierInput.Text
    }
})

$MultiplierInput.Add_TextChanged({
    if ([double]::TryParse($MultiplierInput.Text, [ref]$null)) {
        Save-Settings -dpi $DPIInput.Text -sens $SensInput.Text -multiplier $MultiplierInput.Text
    }
})

# Keybind handler with left-click support
$masterKeybind.Add_Click({
    $masterKeybind.Content = "Press Key..."
    $script:waitingForInput = $true
    
    # Keyboard handler
    $window.Add_KeyDown({
        param($sender, $e)
        if ($script:waitingForInput) {
            if ($e.Key -eq "Escape") {
                $masterKeybind.Content = "Set Keybind"
                $script:masterKey = $null
                $script:isMouseBind = $false
            } else {
                $masterKeybind.Content = "Active Key: $($e.Key)"
                $script:masterKey = $e.Key
                $script:isMouseBind = $false
            }
            $script:waitingForInput = $false
        }
    })

    # Mouse handler (including left click)
    $window.Add_MouseDown({
        param($sender, $e)
        if ($script:waitingForInput) {
            $buttonName = $e.ChangedButton.ToString()
            $masterKeybind.Content = "Active: Mouse $buttonName"
            $script:masterKey = $buttonName
            $script:isMouseBind = $true
            $script:waitingForInput = $false
        }
    })
})

$rightLeftBind = $window.FindName("RightLeftBind")
$rightLeftBind.Add_Click({
    $script:masterKey = "RightLeft"
    $script:isMouseBind = $true
    $masterKeybind.Content = "Active: R+L Click"
})

# Save Preset Handler
$savePreset.Add_Click({
    $saveXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Save Preset"
    Width="300"
    Height="150"
    WindowStartupLocation="CenterOwner"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent">
    <Border Background="#0A0A0A" 
            CornerRadius="10">
        <Border.BorderBrush>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#FF0000" Offset="0"/>
                <GradientStop Color="#FF69B4" Offset="1"/>
            </LinearGradientBrush>
        </Border.BorderBrush>
        <Border.BorderThickness>
            <Thickness>1</Thickness>
        </Border.BorderThickness>
        <StackPanel Margin="20">
            <TextBlock Text="Enter Preset Name:" 
                      Foreground="#B0B0B0" 
                      FontSize="13"
                      FontWeight="Medium"
                      Margin="0,0,0,10"/>
            <TextBox x:Name="PresetName" 
                    Height="34"
                    Background="#141414"
                    Foreground="#FFFFFF"
                    BorderThickness="0"
                    FontSize="13"
                    Padding="10,0"
                    VerticalContentAlignment="Center"
                    Margin="0,0,0,20"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="SaveButton" 
                        Content="SAVE" 
                        Width="70" 
                        Height="32" 
                        Margin="0,0,10,0"
                        Background="#141414" 
                        Foreground="#FFFFFF"
                        BorderThickness="0"
                        FontSize="11"
                        FontWeight="SemiBold">
                    <Button.Style>
                        <Style TargetType="Button">
                            <Style.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter Property="Background">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                <GradientStop Color="#FF0000" Offset="0"/>
                                                <GradientStop Color="#FF69B4" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                            </Style.Triggers>
                        </Style>
                    </Button.Style>
                </Button>
                <Button x:Name="CancelButton" 
                        Content="CANCEL" 
                        Width="70" 
                        Height="32"
                        Background="#141414" 
                        Foreground="#FFFFFF"
                        BorderThickness="0"
                        FontSize="11"
                        FontWeight="SemiBold">
                    <Button.Style>
                        <Style TargetType="Button">
                            <Style.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter Property="Background">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                <GradientStop Color="#FF0000" Offset="0"/>
                                                <GradientStop Color="#FF69B4" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                            </Style.Triggers>
                        </Style>
                    </Button.Style>
                </Button>
            </StackPanel>
        </StackPanel>
    </Border>
</Window>
"@

    $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($saveXaml)))
    $saveWindow = [Windows.Markup.XamlReader]::Load($reader)
    $saveWindow.Owner = $window
    
    $saveButton = $saveWindow.FindName("SaveButton")
    $cancelButton = $saveWindow.FindName("CancelButton")
    $presetNameBox = $saveWindow.FindName("PresetName")
    
$saveButton.Add_Click({
    $presetName = $presetNameBox.Text
    if ($presetName) {
        # Only save slider values
        $preset = @{
            XLeft = $XLeftSlider.Value
            XRight = $XRightSlider.Value
            YDown = $YDownSlider.Value
            YUp = $YUpSlider.Value
        }
        $presetFile = Join-Path $presetPath "$presetName.json"
        $preset | ConvertTo-Json | Set-Content $presetFile -Force
        $activePreset.Text = "Active Preset: $presetName"
        $saveWindow.Close()
    }
})
    
    $cancelButton.Add_Click({ $saveWindow.Close() })
    $saveWindow.ShowDialog()
})

# Load Preset Handler
$loadPreset.Add_Click({
    # Get presets only from C:\Recoil Presets
    $presets = Get-ChildItem -Path "C:\Recoil Presets" -Filter "*.json"
    if ($presets.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No presets found!", "Load Preset")
        return
    }
    
$loadXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Load Preset"
    Width="500"
    Height="400"
    WindowStartupLocation="CenterOwner"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent">
    <Border Background="#0A0A0A" 
            CornerRadius="10">
        <Border.BorderBrush>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#FF0000" Offset="0"/>
                <GradientStop Color="#FF69B4" Offset="1"/>
            </LinearGradientBrush>
        </Border.BorderBrush>
        <Border.BorderThickness>
            <Thickness>1</Thickness>
        </Border.BorderThickness>
        <DockPanel Margin="20">
            <TextBlock Text="SELECT PRESET:" 
                      Foreground="#B0B0B0" 
                      FontSize="13"
                      FontWeight="Medium"
                      DockPanel.Dock="Top" 
                      Margin="0,0,0,10"/>
            <TextBox x:Name="SearchBox" 
                    DockPanel.Dock="Top" 
                    Height="25" 
                    Margin="0,0,0,10"
                    Background="#141414"
                    Foreground="White"
                    BorderBrush="#FF1493"
                    BorderThickness="1"
                    Padding="5,0"/>
            <StackPanel DockPanel.Dock="Bottom" 
                      Orientation="Horizontal" 
                      HorizontalAlignment="Right" 
                      Margin="0,10,0,0">
                <Button x:Name="RenameButton" Content="RENAME" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#141414" Foreground="White" BorderThickness="1">
                    <Button.BorderBrush>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                            <GradientStop Color="#FF0000" Offset="0"/>
                            <GradientStop Color="#FF69B4" Offset="1"/>
                        </LinearGradientBrush>
                    </Button.BorderBrush>
                </Button>
                <Button x:Name="DuplicateButton" Content="DUPLICATE" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#141414" Foreground="White" BorderThickness="1">
                    <Button.BorderBrush>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                            <GradientStop Color="#FF0000" Offset="0"/>
                            <GradientStop Color="#FF69B4" Offset="1"/>
                        </LinearGradientBrush>
                    </Button.BorderBrush>
                </Button>
                <Button x:Name="DeleteButton" Content="DELETE" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#141414" Foreground="White" BorderThickness="1">
                    <Button.BorderBrush>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                            <GradientStop Color="#FF0000" Offset="0"/>
                            <GradientStop Color="#FF69B4" Offset="1"/>
                        </LinearGradientBrush>
                    </Button.BorderBrush>
                </Button>
                <Button x:Name="LoadButton" Content="LOAD" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#141414" Foreground="White" BorderThickness="1">
                    <Button.BorderBrush>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                            <GradientStop Color="#FF0000" Offset="0"/>
                            <GradientStop Color="#FF69B4" Offset="1"/>
                        </LinearGradientBrush>
                    </Button.BorderBrush>
                </Button>
                <Button x:Name="CancelButton" Content="CANCEL" Width="70" Height="25"
                        Background="#141414" Foreground="White" BorderThickness="1">
                    <Button.BorderBrush>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                            <GradientStop Color="#FF0000" Offset="0"/>
                            <GradientStop Color="#FF69B4" Offset="1"/>
                        </LinearGradientBrush>
                    </Button.BorderBrush>
                </Button>
            </StackPanel>
            <ListBox x:Name="PresetList" 
                     Background="#141414" 
                     BorderBrush="#FF1493"
                     Foreground="White">
                <ListBox.ItemContainerStyle>
                    <Style TargetType="ListBoxItem">
                        <Setter Property="Foreground" Value="White"/>
                        <Setter Property="Background" Value="Transparent"/>
                        <Setter Property="Padding" Value="5"/>
                        <Setter Property="Template">
                            <Setter.Value>
                                <ControlTemplate TargetType="ListBoxItem">
                                    <Border Background="{TemplateBinding Background}"
                                            BorderThickness="0">
                                        <ContentPresenter/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsSelected" Value="True">
                                            <Setter Property="Background" Value="#2F2F2F"/>
                                        </Trigger>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#1F1F1F"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </Setter.Value>
                        </Setter>
                    </Style>
                </ListBox.ItemContainerStyle>
            </ListBox>
        </DockPanel>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($loadXaml)))
$loadWindow = [Windows.Markup.XamlReader]::Load($reader)
$loadWindow.Owner = $window

# Get all window controls
$loadButton = $loadWindow.FindName("LoadButton")
$cancelButton = $loadWindow.FindName("CancelButton")
$deleteButton = $loadWindow.FindName("DeleteButton")
$duplicateButton = $loadWindow.FindName("DuplicateButton")
$presetList = $loadWindow.FindName("PresetList")
$renameButton = $loadWindow.FindName("RenameButton")
$searchBox = $loadWindow.FindName("SearchBox")

# Store original items for filtering
$script:originalItems = $presets | ForEach-Object { $_.BaseName }

# Add items to list
$script:originalItems | ForEach-Object {
    $presetList.Items.Add($_)
}

# Add search functionality
$searchBox.Add_TextChanged({
    $searchText = $searchBox.Text.ToLower()
    $presetList.Items.Clear()
    
    $script:originalItems | Where-Object {
        $_.ToLower() -match [regex]::Escape($searchText)
    } | ForEach-Object {
        $presetList.Items.Add($_)
    }
})

        # Delete button handler

        $deleteButton.Add_Click({
            $selectedPreset = $presetList.SelectedItem
            if ($selectedPreset) {
                $result = [System.Windows.MessageBox]::Show(
                    "Are you sure you want to delete this preset?",
                    "Confirm Delete",
                    [System.Windows.MessageBoxButton]::YesNo
                )
                if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                    Remove-Item (Join-Path "C:\Recoil Presets" "$selectedPreset.json")
                    $presetList.Items.Remove($selectedPreset)
                }
            }
        })
    
        $duplicateButton.Add_Click({
            $selectedPreset = $presetList.SelectedItem
            if ($selectedPreset) {
                $newName = "${selectedPreset}_copy"
                $counter = 1
                while (Test-Path (Join-Path "C:\Recoil Presets" "$newName.json")) {
                    $newName = "${selectedPreset}_copy$counter"
                    $counter++
                }
                
                Copy-Item (Join-Path "C:\Recoil Presets" "$selectedPreset.json") (Join-Path "C:\Recoil Presets" "$newName.json")
                $presetList.Items.Add($newName)
            }
        })
    
    $renameButton.Add_Click({
    $selectedPreset = $presetList.SelectedItem
    if ($selectedPreset) {
        # Create rename dialog
        $renameXaml = @"
        <Window 
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Rename Preset"
            Width="300"
            Height="150"
            WindowStartupLocation="CenterOwner"
            WindowStyle="None"
            AllowsTransparency="True"
            Background="Transparent">
            <Border Background="#1E1E1E" 
                    BorderBrush="#FF1493" 
                    BorderThickness="1" 
                    CornerRadius="5">
                <StackPanel Margin="20">
                    <TextBlock Text="Enter New Name:" 
                              Foreground="White" 
                              Margin="0,0,0,10"/>
                    <TextBox x:Name="NewName" Height="25" Margin="0,0,0,20"/>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="ConfirmButton" Content="Rename" Width="70" Height="25" Margin="0,0,10,0"
                                Background="#333333" Foreground="White"/>
                        <Button x:Name="CancelRenameButton" Content="Cancel" Width="70" Height="25"
                                Background="#333333" Foreground="White"/>
                    </StackPanel>
                </StackPanel>
            </Border>
        </Window>
"@

        $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($renameXaml)))
        $renameWindow = [Windows.Markup.XamlReader]::Load($reader)
        $renameWindow.Owner = $loadWindow

        $newNameBox = $renameWindow.FindName("NewName")
        $confirmButton = $renameWindow.FindName("ConfirmButton")
        $cancelRenameButton = $renameWindow.FindName("CancelRenameButton")

        $newNameBox.Text = $selectedPreset

        $confirmButton.Add_Click({
            $newName = $newNameBox.Text
            if ($newName -and ($newName -ne $selectedPreset)) {
                $oldPath = Join-Path $presetPath "$selectedPreset.json"
                $newPath = Join-Path $presetPath "$newName.json"
                
                if (Test-Path $newPath) {
                    [System.Windows.MessageBox]::Show("A preset with this name already exists!", "Error")
                    return
                }

                Rename-Item -Path $oldPath -NewName "$newName.json"
                $index = $presetList.Items.IndexOf($selectedPreset)
                $presetList.Items[$index] = $newName
                $renameWindow.Close()
            }
        })

        $cancelRenameButton.Add_Click({ $renameWindow.Close() })
        $renameWindow.ShowDialog()
    }
})

    # Load button handler
    $loadButton.Add_Click({
        $selectedPreset = $presetList.SelectedItem
        if ($selectedPreset) {
            $presetFile = Join-Path "C:\Recoil Presets" "$selectedPreset.json"
            $preset = Get-Content $presetFile | ConvertFrom-Json
            
            $XLeftSlider.Value = $preset.XLeft
            $XRightSlider.Value = $preset.XRight
            $YDownSlider.Value = $preset.YDown
            $YUpSlider.Value = $preset.YUp
            
            $activePreset.Text = "Active Preset: $selectedPreset"
            $loadWindow.Close()
        }
    })
    
    $cancelButton.Add_Click({ $loadWindow.Close() })
    $loadWindow.ShowDialog()
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
}
"@

# Initialize timer for mouse movement
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000/144  # For 144Hz polling rate

# Add window state changed event handler
$window.Add_StateChanged({
    if ($window.WindowState -eq "Minimized") {
        $timer.Start()
    } else {
        $timer.Stop()
    }
})

$timer.Add_Tick({
    if (-not (Test-MouseOverWindow)) {
        $moveX = 0
        $moveY = 0
        
        $currentDPI = [double]$DPIInput.Text
        $currentSens = [double]$SensInput.Text
        $currentMultiplier = [double]$MultiplierInput.Text

        $sensitivityRatio = ($currentDPI * $currentSens * $currentMultiplier) / (1600 * 42 * 0.002)
        $horizontalScale = 0.4021340977862856
        $verticalScale = 0.8293650767        

        if ($script:masterKey -eq "RightLeft") {
            $isPressed = [MouseMover]::GetAsyncKeyState(0x02) -and [MouseMover]::GetAsyncKeyState(0x01)
        } elseif ($script:isMouseBind) {
            $mouseButton = switch ($script:masterKey) {
                "Left" { 0x01 }
                "Right" { 0x02 }
                "Middle" { 0x04 }
                "XButton1" { 0x05 }
                "XButton2" { 0x06 }
                "XButton3" { 0x07 }
                "XButton4" { 0x08 }
            }
            $isPressed = [MouseMover]::GetAsyncKeyState($mouseButton)
        } else {
            $virtualKey = [System.Windows.Forms.Keys]::$script:masterKey
            $isPressed = [MouseMover]::GetAsyncKeyState($virtualKey)
        }
        
        if ($isPressed) {
            $baseX = $XRightSlider.Value - $XLeftSlider.Value
            $baseY = $YDownSlider.Value - $YUpSlider.Value
            
            # High-precision movement calculation
            $moveX = [Math]::Round(($baseX / $sensitivityRatio) * $horizontalScale, 2)
            $moveY = [Math]::Round(($baseY / $sensitivityRatio) * $verticalScale, 2)

            [MouseMover]::mouse_event(0x0001, [int]$moveX, [int]$moveY, 0, 0)
        }
    }
})

$timer.Start()
$window.ShowDialog()
