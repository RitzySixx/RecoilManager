# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Then load the rest of the assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

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
    Width="600"
    Height="450"
    ResizeMode="NoResize"
    WindowStartupLocation="CenterScreen"
    Topmost="True">
    
    <Window.Resources>
        <ResourceDictionary>
            <LinearGradientBrush x:Key="LogoGradient" StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#FF0000" Offset="0"/>
                <GradientStop Color="#FF4500" Offset="0.5"/>
                <GradientStop Color="#FF1493" Offset="1"/>
            </LinearGradientBrush>
            
            <SolidColorBrush x:Key="WindowBackground" Color="#1E1E1E"/>
            <SolidColorBrush x:Key="TextColor" Color="#FFFFFF"/>
            <SolidColorBrush x:Key="ButtonBackground" Color="#2D2D2D"/>

            <Style x:Key="PresetNameStyle" TargetType="TextBlock">
                <Setter Property="Foreground" Value="White"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="Margin" Value="0,0,0,20"/>
                <Setter Property="HorizontalAlignment" Value="Center"/>
            </Style>

            <Style x:Key="PresetButtonStyle" TargetType="Button">
                <Setter Property="Background" Value="#333333"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
                <Setter Property="BorderThickness" Value="1"/>
                <Setter Property="BorderBrush" Value="{StaticResource LogoGradient}"/>
                <Setter Property="Width" Value="120"/>
                <Setter Property="Height" Value="30"/>
                <Setter Property="Margin" Value="10,20,10,0"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}"
                                    CornerRadius="4">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter Property="Background" Value="#444444"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

                        <Style x:Key="SliderStyle" TargetType="Slider">
                <Setter Property="Margin" Value="5,8,15,8"/>
                <Setter Property="Width" Value="250"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Slider">
                            <Grid>
                                <Border x:Name="PART_Border" 
                                        BorderBrush="{StaticResource LogoGradient}" 
                                        BorderThickness="1" 
                                        CornerRadius="4"
                                        Background="#333333"
                                        Height="2"/>
                                <Track x:Name="PART_Track">
                                    <Track.DecreaseRepeatButton>
                                        <RepeatButton Command="Slider.DecreaseLarge">
                                            <RepeatButton.Template>
                                                <ControlTemplate TargetType="RepeatButton">
                                                    <Border Background="{StaticResource LogoGradient}" 
                                                            CornerRadius="4 0 0 4"/>
                                                </ControlTemplate>
                                            </RepeatButton.Template>
                                        </RepeatButton>
                                    </Track.DecreaseRepeatButton>
                                    <Track.Thumb>
                                        <Thumb>
                                            <Thumb.Template>
                                                <ControlTemplate TargetType="Thumb">
                                                    <Grid>
                                                        <Ellipse Width="12" Height="12" Fill="#FFFFFF"/>
                                                        <Ellipse Width="10" Height="10" Fill="{StaticResource LogoGradient}">
                                                            <Ellipse.Effect>
                                                                <DropShadowEffect Color="#FF1493" BlurRadius="5" ShadowDepth="0"/>
                                                            </Ellipse.Effect>
                                                        </Ellipse>
                                                    </Grid>
                                                </ControlTemplate>
                                            </Thumb.Template>
                                        </Thumb>
                                    </Track.Thumb>
                                    <Track.IncreaseRepeatButton>
                                        <RepeatButton Command="Slider.IncreaseLarge">
                                            <RepeatButton.Template>
                                                <ControlTemplate TargetType="RepeatButton">
                                                    <Border Background="#333333" 
                                                            CornerRadius="0 4 4 0"/>
                                                </ControlTemplate>
                                            </RepeatButton.Template>
                                        </RepeatButton>
                                    </Track.IncreaseRepeatButton>
                                </Track>
                            </Grid>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <Style x:Key="ValueTextStyle" TargetType="TextBlock">
                <Setter Property="Foreground" Value="{StaticResource LogoGradient}"/>
                <Setter Property="FontWeight" Value="Bold"/>
                <Setter Property="Width" Value="35"/>
                <Setter Property="TextAlignment" Value="Right"/>
                <Setter Property="VerticalAlignment" Value="Center"/>
            </Style>

            <Style x:Key="LabelTextStyle" TargetType="TextBlock">
                <Setter Property="Foreground" Value="{StaticResource TextColor}"/>
                <Setter Property="Width" Value="85"/>
                <Setter Property="VerticalAlignment" Value="Center"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
            </Style>

            <Style x:Key="WindowButtonStyle" TargetType="Button">
                <Setter Property="Background" Value="Transparent"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Foreground" Value="{StaticResource TextColor}"/>
                <Setter Property="FontSize" Value="16"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="3">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="{StaticResource LogoGradient}"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </ResourceDictionary>
    </Window.Resources>

        <Border CornerRadius="5" Background="{StaticResource WindowBackground}" BorderBrush="{StaticResource LogoGradient}" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="30"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Title Bar -->
            <Grid Grid.Row="0" Background="Transparent">
                <Canvas HorizontalAlignment="Left" Margin="10,5,0,0">
                    <Ellipse Width="20" Height="20" StrokeThickness="2">
                        <Ellipse.Stroke>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                <GradientStop Color="#FF0000" Offset="0"/>
                                <GradientStop Color="#FF1493" Offset="1"/>
                            </LinearGradientBrush>
                        </Ellipse.Stroke>
                    </Ellipse>
                    
                    <TextBlock Text="R" 
                             FontFamily="Bahnschrift"
                             FontWeight="ExtraBold"
                             FontSize="14"
                             Canvas.Left="6"
                             Canvas.Top="1">
                        <TextBlock.Foreground>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                <GradientStop Color="#FF0000" Offset="0"/>
                                <GradientStop Color="#FF4500" Offset="0.5"/>
                                <GradientStop Color="#FF1493" Offset="1"/>
                            </LinearGradientBrush>
                        </TextBlock.Foreground>
                        <TextBlock.Effect>
                            <DropShadowEffect Color="#FF1493" Direction="320" ShadowDepth="1" BlurRadius="2" Opacity="0.5"/>
                        </TextBlock.Effect>
                    </TextBlock>
                </Canvas>

                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,5,0">
                    <Button x:Name="MinimizeButton" Content="−" Width="25" Height="20" Margin="0,0,5,0"
                            Style="{StaticResource WindowButtonStyle}"/>
                    <Button x:Name="CloseButton" Content="×" Width="25" Height="20"
                            Style="{StaticResource WindowButtonStyle}"/>
                </StackPanel>
            </Grid>

            <!-- Main Content -->
            <Grid Grid.Row="1">
                <StackPanel Margin="20,10,20,20">
                    <TextBlock x:Name="ActivePreset" 
                              Text="No Preset Selected" 
                              Style="{StaticResource PresetNameStyle}"/>

                    <!-- X Axis Left -->
                    <DockPanel>
                        <TextBlock Text="X Axis Left" Style="{StaticResource LabelTextStyle}"/>
                        <TextBlock Text="{Binding Value, ElementName=XLeftSlider, StringFormat=N0}" Style="{StaticResource ValueTextStyle}"/>
                        <Slider x:Name="XLeftSlider" Style="{StaticResource SliderStyle}" Minimum="0" Maximum="50000" Value="0"/>
                    </DockPanel>

                    <!-- X Axis Right -->
                    <DockPanel>
                        <TextBlock Text="X Axis Right" Style="{StaticResource LabelTextStyle}"/>
                        <TextBlock Text="{Binding Value, ElementName=XRightSlider, StringFormat=N0}" Style="{StaticResource ValueTextStyle}"/>
                        <Slider x:Name="XRightSlider" Style="{StaticResource SliderStyle}" Minimum="0" Maximum="50000" Value="0"/>
                    </DockPanel>

                    <!-- Y Axis Down -->
                    <DockPanel>
                        <TextBlock Text="Y Axis Down" Style="{StaticResource LabelTextStyle}"/>
                        <TextBlock Text="{Binding Value, ElementName=YDownSlider, StringFormat=N0}" Style="{StaticResource ValueTextStyle}"/>
                        <Slider x:Name="YDownSlider" Style="{StaticResource SliderStyle}" Minimum="0" Maximum="50000" Value="0"/>
                    </DockPanel>

                    <!-- Y Axis Up -->
                    <DockPanel>
                        <TextBlock Text="Y Axis Up" Style="{StaticResource LabelTextStyle}"/>
                        <TextBlock Text="{Binding Value, ElementName=YUpSlider, StringFormat=N0}" Style="{StaticResource ValueTextStyle}"/>
                        <Slider x:Name="YUpSlider" Style="{StaticResource SliderStyle}" Minimum="0" Maximum="50000" Value="0"/>
                    </DockPanel>

                    <!-- Control Buttons -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button x:Name="LoadPreset" 
                                Content="Load Preset" 
                                Style="{StaticResource PresetButtonStyle}"/>
                        <Button x:Name="MasterKeybind" 
                                Content="Set Keybind" 
                                Style="{StaticResource PresetButtonStyle}"/>
                        <Button x:Name="SavePreset" 
                                Content="Save Preset" 
                                Style="{StaticResource PresetButtonStyle}"/>
                        <Button x:Name="RightLeftBind"
                                Content="Set Right + Left Click"
                                Style="{StaticResource PresetButtonStyle}"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
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

# Initialize variables
$script:masterKey = $null
$script:isKeyActive = $false
$script:isMouseBind = $false

# Window control handlers
$closeButton.Add_Click({ $window.Close() })
$minimizeButton.Add_Click({ $window.WindowState = "Minimized" })
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Keybind handler with left-click support
$masterKeybind.Add_Click({
    $masterKeybind.Content = "Press Key or Mouse Button..."
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
    $masterKeybind.Content = "Active: Left + Right Click"
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
    <Border Background="#1E1E1E" 
            BorderBrush="#FF1493" 
            BorderThickness="1" 
            CornerRadius="5">
        <StackPanel Margin="20">
            <TextBlock Text="Enter Preset Name:" 
                      Foreground="White" 
                      Margin="0,0,0,10"/>
            <TextBox x:Name="PresetName" Height="25" Margin="0,0,0,20"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="SaveButton" Content="Save" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#333333" Foreground="White"/>
                <Button x:Name="CancelButton" Content="Cancel" Width="70" Height="25"
                        Background="#333333" Foreground="White"/>
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
    $presets = Get-ChildItem -Path $presetPath -Filter "*.json"
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
    <Border Background="#1E1E1E" 
            BorderBrush="#FF1493" 
            BorderThickness="1" 
            CornerRadius="5">
        <DockPanel Margin="20">
            <TextBlock Text="Select Preset:" 
                      Foreground="White" 
                      DockPanel.Dock="Top" 
                      Margin="0,0,0,10"/>
            <StackPanel DockPanel.Dock="Bottom" 
                      Orientation="Horizontal" 
                      HorizontalAlignment="Right" 
                      Margin="0,10,0,0">
                <Button x:Name="RenameButton" Content="Rename" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#333333" Foreground="White"/>
                <Button x:Name="DuplicateButton" Content="Duplicate" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#333333" Foreground="White"/>
                <Button x:Name="DeleteButton" Content="Delete" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#333333" Foreground="White"/>
                <Button x:Name="LoadButton" Content="Load" Width="70" Height="25" Margin="0,0,10,0"
                        Background="#333333" Foreground="White"/>
                <Button x:Name="CancelButton" Content="Cancel" Width="70" Height="25"
                        Background="#333333" Foreground="White"/>
            </StackPanel>
            <ListBox x:Name="PresetList" Background="Transparent" 
                    BorderBrush="#FF1493"/>
        </DockPanel>
    </Border>
</Window>
"@

 $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($loadXaml)))
    $loadWindow = [Windows.Markup.XamlReader]::Load($reader)
    $loadWindow.Owner = $window
    
    $loadButton = $loadWindow.FindName("LoadButton")
    $cancelButton = $loadWindow.FindName("CancelButton")
    $deleteButton = $loadWindow.FindName("DeleteButton")
    $duplicateButton = $loadWindow.FindName("DuplicateButton")
    $presetList = $loadWindow.FindName("PresetList")
    $renameButton = $loadWindow.FindName("RenameButton")
    
    $presets | ForEach-Object {
        $presetList.Items.Add($_.BaseName)
    }

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
                Remove-Item (Join-Path $presetPath "$selectedPreset.json")
                $presetList.Items.Remove($selectedPreset)
            }
        }
    })
    
    # Duplicate button handler
    $duplicateButton.Add_Click({
        $selectedPreset = $presetList.SelectedItem
        if ($selectedPreset) {
            $newName = "${selectedPreset}_copy"
            $counter = 1
            while (Test-Path (Join-Path $presetPath "$newName.json")) {
                $newName = "${selectedPreset}_copy$counter"
                $counter++
            }
            
            Copy-Item (Join-Path $presetPath "$selectedPreset.json") (Join-Path $presetPath "$newName.json")
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
            $presetFile = Join-Path $presetPath "$selectedPreset.json"
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
$timer.Interval = 1  # Adjust for smoothness

# Add window state changed event handler
$window.Add_StateChanged({
    if ($window.WindowState -eq "Minimized") {
        $timer.Start()
    } else {
        $timer.Stop()
    }
})

$timer.Add_Tick({
    $moveX = 0
    $moveY = 0
    
    # Check if keybind is pressed
    if ($script:masterKey -eq "RightLeft") {
        $isPressed = [MouseMover]::GetAsyncKeyState(0x02) -and [MouseMover]::GetAsyncKeyState(0x01)
    } elseif ($script:isMouseBind) {
        $mouseButton = switch ($script:masterKey) {
            "Left" { 0x01 }
            "Right" { 0x02 }
            "Middle" { 0x04 }
            "XButton1" { 0x05 }  # First side button
            "XButton2" { 0x06 }  # Second side button
            "XButton3" { 0x07 }  # Third side button
            "XButton4" { 0x08 }  # Fourth side button
        }
        $isPressed = [MouseMover]::GetAsyncKeyState($mouseButton)
    } else {
        $virtualKey = [System.Windows.Forms.Keys]::$script:masterKey
        $isPressed = [MouseMover]::GetAsyncKeyState($virtualKey)
    }
    
    if ($isPressed) {
        # Calculate movement based on slider values
        $moveX = [int](($XRightSlider.Value - $XLeftSlider.Value) / 10)
        $moveY = [int](($YDownSlider.Value - $YUpSlider.Value) / 10)
        
        if ($moveX -ne 0 -or $moveY -ne 0) {
            [MouseMover]::mouse_event(0x0001, $moveX, $moveY, 0, 0)
        }
    }
})

# Show window
$window.ShowDialog()
