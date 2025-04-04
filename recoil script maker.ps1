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
        <Style TargetType="ScrollViewer">
            <Setter Property="Background" Value="#413e3e"/>
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
            <Setter Property="Maximum" Value="50"/>
            <Setter Property="TickFrequency" Value="1"/>
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
                                <TextBlock x:Name="StatusText"
                                            Text="Status: Ready"
                                            Foreground="#00FF00"
                                           HorizontalAlignment="Center"
                                           FontWeight="Bold"
                                           FontSize="14"/>
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
                                    Maximum="20"
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
                                   
                           <!-- Save Preset -->
                        <Grid Margin="0,5,0,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="120"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="PresetNameTextBox"
                                     Style="{StaticResource TextBoxStyle}"
                                     Text="MyPreset"
                                     TextAlignment="Left"
                                     Padding="5,0,0,0"/>
                            <Button x:Name="SavePresetButton"
                                    Content="Save Preset"
                                    Grid.Column="1"
                                    Style="{StaticResource ButtonStyle}"
                                    Margin="10,0,0,0"/>
                        </Grid>
                        
                        <!-- Load Preset -->
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="120"/>
                            </Grid.ColumnDefinitions>
                            <ComboBox x:Name="LoadPresetComboBox"
                                      Style="{StaticResource ComboBoxStyle}"/>
                            <Button x:Name="LoadPresetButton"
                                    Content="Load Preset"
                                    Grid.Column="1"
                                    Style="{StaticResource ButtonStyle}"
                                    Margin="10,0,0,0"/>
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
$presetNameTextBox = $window.FindName("PresetNameTextBox")
$savePresetButton = $window.FindName("SavePresetButton")
$loadPresetComboBox = $window.FindName("LoadPresetComboBox")
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

# Function to refresh preset list
function RefreshPresetList {
    $loadPresetComboBox.Items.Clear()
    
    $presetFiles = Get-ChildItem -Path $presetDirectory -Filter "*.rcpreset" | Select-Object -ExpandProperty Name
    
    foreach ($presetFile in $presetFiles) {
        $presetName = [System.IO.Path]::GetFileNameWithoutExtension($presetFile)
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $presetName
        $item.Foreground = "White"
        $item.Background = "#252525"
        $loadPresetComboBox.Items.Add($item)
    }
    
    if ($loadPresetComboBox.Items.Count -gt 0) {
        $loadPresetComboBox.SelectedIndex = 0
    }
}

# Call RefreshPresetList on startup
RefreshPresetList

# Window control handlers
$closeButton.Add_Click({ $window.Close() })
$minimizeButton.Add_Click({ 
    $window.WindowState = "Minimized" 
    $statusText.Text = "Status: Active"
    $statusText.Foreground = "#00FF00"
})

# Enable RCS checkbox handler
$enableRCSCheckBox.Add_Checked({
    $script:enableRCS = $true
    $statusText.Text = "Status: Ready"
    $statusText.Foreground = "#00FF00"
})
$enableRCSCheckBox.Add_Unchecked({
    $script:enableRCS = $false
    $statusText.Text = "Status: Disabled"
    $statusText.Foreground = "#FF0000"
})

# Require toggle checkbox handler
$requireToggleCheckBox.Add_Checked({
    $script:requireToggle = $true
})
$requireToggleCheckBox.Add_Unchecked({
    $script:requireToggle = $false
})

# Toggle key combobox handler
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

# Vertical custom strength textbox handler
$verticalCustomStrengthTextBox.Add_TextChanged({
    if ($verticalCustomStrengthTextBox.Text -match '^\d+$') {
        $script:verticalCustomStrength = [int]$verticalCustomStrengthTextBox.Text
        $verticalCustomStrengthSlider.Value = $script:verticalCustomStrength
        
        # Only update recoil strength if in custom mode
        if ($verticalRecoilModeComboBox.SelectedItem.Content -eq "Custom") {
            $script:verticalRecoilStrength = $script:verticalCustomStrength
        }
    }
})

# Vertical custom strength slider handler
$verticalCustomStrengthSlider.Add_ValueChanged({
    $value = [Math]::Round($verticalCustomStrengthSlider.Value)
    $verticalCustomStrengthTextBox.Text = $value.ToString()
})

# Vertical delay textbox handler
$verticalDelayTextBox.Add_TextChanged({
    if ($verticalDelayTextBox.Text -match '^\d+$') {
        $script:verticalDelay = [int]$verticalDelayTextBox.Text
        $verticalDelaySlider.Value = $script:verticalDelay
    }
})

# Vertical delay slider handler
$verticalDelaySlider.Add_ValueChanged({
    $value = [Math]::Round($verticalDelaySlider.Value)
    $verticalDelayTextBox.Text = $value.ToString()
})

# Horizontal direction combobox handler
$horizontalDirectionComboBox.Add_SelectionChanged({
    $script:horizontalDirection = $horizontalDirectionComboBox.SelectedItem.Content
})

# Horizontal strength textbox handler
$horizontalStrengthTextBox.Add_TextChanged({
    if ($horizontalStrengthTextBox.Text -match '^\d+$') {
        $script:horizontalStrength = [int]$horizontalStrengthTextBox.Text
        $horizontalStrengthSlider.Value = $script:horizontalStrength
    }
})

# Horizontal strength slider handler
$horizontalStrengthSlider.Add_ValueChanged({
    $value = [Math]::Round($horizontalStrengthSlider.Value)
    $horizontalStrengthTextBox.Text = $value.ToString()
})

# Horizontal delay textbox handler
$horizontalDelayTextBox.Add_TextChanged({
    if ($horizontalDelayTextBox.Text -match '^\d+$') {
        $script:horizontalDelay = [int]$horizontalDelayTextBox.Text
        $horizontalDelaySlider.Value = $script:horizontalDelay
    }
})

# Horizontal delay slider handler
$horizontalDelaySlider.Add_ValueChanged({
    $value = [Math]::Round($horizontalDelaySlider.Value)
    $horizontalDelayTextBox.Text = $value.ToString()
})
# Function to show save preset dialog
function ShowSavePresetDialog {
    [xml]$saveDialogXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Save Preset" 
    Height="200" 
    Width="400"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    ResizeMode="NoResize"
    WindowStartupLocation="CenterOwner">
    
    <Border Background="#0A0A0A" 
            CornerRadius="10"
            BorderBrush="#333333"
            BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <!-- Header -->
            <TextBlock Text="SAVE PRESET" 
                       Foreground="#00BFFF"
                       FontSize="18"
                       FontWeight="Bold"
                       HorizontalAlignment="Center"
                       Margin="0,15,0,15"/>
                       
            <!-- Content -->
            <StackPanel Grid.Row="1" Margin="20,0,20,0">
                <TextBlock Text="Preset Name:" 
                           Foreground="White"
                           Margin="0,0,0,5"/>
                <TextBox x:Name="SavePresetNameTextBox" 
                         Background="#252525"
                         Foreground="White"
                         BorderBrush="#00BFFF"
                         Padding="5"
                         Height="30"/>
            </StackPanel>
            
            <!-- Buttons -->
            <StackPanel Grid.Row="2" 
                        Orientation="Horizontal" 
                        HorizontalAlignment="Right"
                        Margin="0,0,20,15">
                <Button x:Name="SaveDialogCancelButton" 
                        Content="Cancel"
                        Width="80"
                        Height="30"
                        Background="#252525"
                        Foreground="White"
                        BorderBrush="#00BFFF"
                        BorderThickness="1"
                        Margin="0,0,10,0"/>
                <Button x:Name="SaveDialogSaveButton" 
                        Content="Save"
                        Width="80"
                        Height="30"
                        Background="#252525"
                        Foreground="White"
                        BorderBrush="#00BFFF"
                        BorderThickness="1"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

    $saveDialogReader = New-Object System.Xml.XmlNodeReader $saveDialogXaml
    $saveDialog = [Windows.Markup.XamlReader]::Load($saveDialogReader)
    
    $savePresetNameTextBox = $saveDialog.FindName("SavePresetNameTextBox")
    $saveDialogCancelButton = $saveDialog.FindName("SaveDialogCancelButton")
    $saveDialogSaveButton = $saveDialog.FindName("SaveDialogSaveButton")
    
    $savePresetNameTextBox.Text = $presetNameTextBox.Text
    
    $saveDialogCancelButton.Add_Click({ $saveDialog.DialogResult = $false })
    $saveDialogSaveButton.Add_Click({ $saveDialog.DialogResult = $true })
    
    $saveDialog.Owner = $window
    
    if ($saveDialog.ShowDialog()) {
        return $savePresetNameTextBox.Text
    } else {
        return $null
    }
}

# Save preset button handler
$savePresetButton.Add_Click({
    $presetName = $presetNameTextBox.Text.Trim()
    
    if ([string]::IsNullOrEmpty($presetName)) {
        $statusText.Text = "Error: Enter preset name"
        $statusText.Foreground = "#FF0000"
        return
    }
    
    $presetFilePath = Join-Path -Path $presetDirectory -ChildPath "$presetName.rcpreset"
    
    # Check if preset already exists
    if (Test-Path -Path $presetFilePath) {
        $confirmSave = ShowSavePresetDialog
        if ($null -eq $confirmSave) {
            return
        }
        $presetName = $confirmSave
        $presetFilePath = Join-Path -Path $presetDirectory -ChildPath "$presetName.rcpreset"
    }
    
    # Create preset object
    $preset = @{
        EnableRCS = $script:enableRCS
        RequireToggle = $script:requireToggle
        ToggleKey = $script:toggleKey
        VerticalRecoilMode = $script:verticalRecoilMode
        VerticalRecoilStrength = $script:verticalRecoilStrength
        VerticalCustomStrength = $script:verticalCustomStrength
        VerticalDelay = $script:verticalDelay
        HorizontalDirection = $script:horizontalDirection
        HorizontalStrength = $script:horizontalStrength
        HorizontalDelay = $script:horizontalDelay
    }
    
    # Save preset to file
    $preset | ConvertTo-Json | Set-Content -Path $presetFilePath
    
    $statusText.Text = "Preset saved successfully"
    $statusText.Foreground = "#00FF00"
    
    # Refresh preset list
    RefreshPresetList
})

# Load preset button handler
$loadPresetButton.Add_Click({
    if ($loadPresetComboBox.SelectedItem -eq $null) {
        $statusText.Text = "Error: No preset selected"
        $statusText.Foreground = "#FF0000"
        return
    }
    
    $presetName = $loadPresetComboBox.SelectedItem.Content
    $presetFilePath = Join-Path -Path $presetDirectory -ChildPath "$presetName.rcpreset"
    
    if (-not (Test-Path -Path $presetFilePath)) {
        $statusText.Text = "Error: Preset file not found"
        $statusText.Foreground = "#FF0000"
        return
    }
    
    # Load preset from file
    $preset = Get-Content -Path $presetFilePath | ConvertFrom-Json
    
    # Apply preset settings
    $script:enableRCS = $preset.EnableRCS
    $enableRCSCheckBox.IsChecked = $preset.EnableRCS
    
    $script:requireToggle = $preset.RequireToggle
    $requireToggleCheckBox.IsChecked = $preset.RequireToggle
    
    $script:toggleKey = $preset.ToggleKey
    foreach ($item in $toggleKeyComboBox.Items) {
        if ($item.Content -eq $preset.ToggleKey) {
            $toggleKeyComboBox.SelectedItem = $item
            break
        }
    }
    
    $script:verticalRecoilMode = $preset.VerticalRecoilMode
    foreach ($item in $verticalRecoilModeComboBox.Items) {
        if ($item.Content -eq $preset.VerticalRecoilMode) {
            $verticalRecoilModeComboBox.SelectedItem = $item
            break
        }
    }
    
    $script:verticalRecoilStrength = $preset.VerticalRecoilStrength
    $script:verticalCustomStrength = $preset.VerticalCustomStrength
    $verticalCustomStrengthTextBox.Text = $preset.VerticalCustomStrength.ToString()
    $verticalCustomStrengthSlider.Value = $preset.VerticalCustomStrength
    
    $script:verticalDelay = $preset.VerticalDelay
    $verticalDelayTextBox.Text = $preset.VerticalDelay.ToString()
    $verticalDelaySlider.Value = $preset.VerticalDelay
    
    $script:horizontalDirection = $preset.HorizontalDirection
    foreach ($item in $horizontalDirectionComboBox.Items) {
        if ($item.Content -eq $preset.HorizontalDirection) {
            $horizontalDirectionComboBox.SelectedItem = $item
            break
        }
    }
    
    $script:horizontalStrength = $preset.HorizontalStrength
    $horizontalStrengthTextBox.Text = $preset.HorizontalStrength.ToString()
    $horizontalStrengthSlider.Value = $preset.HorizontalStrength
    
    $script:horizontalDelay = $preset.HorizontalDelay
    $horizontalDelayTextBox.Text = $preset.HorizontalDelay.ToString()
    $horizontalDelaySlider.Value = $preset.HorizontalDelay
    
    $statusText.Text = "Preset loaded successfully"
    $statusText.Foreground = "#00FF00"
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
            # For ScrollLock we need to use GetKeyState since .NET doesn't expose it directly
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
$verticalTimer.Interval = 10  # Fast polling rate
$horizontalTimer = New-Object System.Windows.Forms.Timer
$horizontalTimer.Interval = 10  # Fast polling rate

# Vertical timer tick event handler
$verticalTimer.Add_Tick({
    # Check if recoil control is enabled
    if ($script:enableRCS) {
        # Check if toggle is required and if it's active
        $toggleActive = if ($script:requireToggle) { IsKeyLockOn($script:toggleKey) } else { $true }
        
        if ($toggleActive) {
            # Check if right mouse button is pressed (Mouse2)
            if ([MouseMover]::GetAsyncKeyState(0x02)) {
                # Check if left mouse button is pressed (Mouse1)
                if ([MouseMover]::GetAsyncKeyState(0x01)) {
                    # Apply vertical recoil control by moving mouse
                    [MouseMover]::mouse_event(0x0001, 0, $script:verticalRecoilStrength, 0, 0)
                }
            }
        }
    }
})

# Horizontal timer tick event handler
$horizontalTimer.Add_Tick({
    # Check if recoil control is enabled
    if ($script:enableRCS) {
        # Check if toggle is required and if it's active
        $toggleActive = if ($script:requireToggle) { IsKeyLockOn($script:toggleKey) } else { $true }
        
        if ($toggleActive) {
            # Check if right mouse button is pressed (Mouse2)
            if ([MouseMover]::GetAsyncKeyState(0x02)) {
                # Check if left mouse button is pressed (Mouse1)
                if ([MouseMover]::GetAsyncKeyState(0x01)) {
                    # Only apply horizontal recoil if strength is greater than 0
                    if ($script:horizontalStrength -gt 0) {
                        # Calculate horizontal movement
                        $horizontalMove = 0
                        switch ($script:horizontalDirection) {
                            "Left" { $horizontalMove = -$script:horizontalStrength }
                            "Right" { $horizontalMove = $script:horizontalStrength }
                            "Random" { $horizontalMove = GetRandomHorizontalMovement($script:horizontalStrength) }
                        }
                        
                        # Apply horizontal recoil control by moving mouse
                        [MouseMover]::mouse_event(0x0001, $horizontalMove, 0, 0, 0)
                    }
                }
            }
        }
    }
})
# Window state changed event handler
$window.Add_StateChanged({
    if ($window.WindowState -eq "Minimized") {
        $statusText.Text = "Status: Active (Minimized)"
        $statusText.Foreground = "#00FF00"
    } else {
        if ($script:enableRCS) {
            $statusText.Text = "Status: Active"
            $statusText.Foreground = "#00FF00"
        } else {
            $statusText.Text = "Status: Disabled"
            $statusText.Foreground = "#FF0000"
        }
    }
})

# Add window load event to start timers
$window.Add_Loaded({
    # Set timer intervals based on delay values
    $verticalTimer.Interval = [Math]::Max(1, $script:verticalDelay)
    $horizontalTimer.Interval = [Math]::Max(1, $script:horizontalDelay)
    
    $verticalTimer.Start()
    $horizontalTimer.Start()
    
    if ($script:enableRCS) {
        $statusText.Text = "Status: Active"
        $statusText.Foreground = "#00FF00"
    } else {
        $statusText.Text = "Status: Disabled"
        $statusText.Foreground = "#FF0000"
    }
})

# Make window draggable
$window.Add_MouseLeftButtonDown({
    $window.DragMove()
})

# Update timer intervals when delay values change
$verticalDelayTextBox.Add_TextChanged({
    if ($verticalDelayTextBox.Text -match '^\d+$') {
        $script:verticalDelay = [int]$verticalDelayTextBox.Text
        $verticalTimer.Interval = [Math]::Max(1, $script:verticalDelay)
    }
})

$horizontalDelayTextBox.Add_TextChanged({
    if ($horizontalDelayTextBox.Text -match '^\d+$') {
        $script:horizontalDelay = [int]$horizontalDelayTextBox.Text
        $horizontalTimer.Interval = [Math]::Max(1, $script:horizontalDelay)
    }
})

# Initialize UI with default values
$enableRCSCheckBox.IsChecked = $script:enableRCS
$requireToggleCheckBox.IsChecked = $script:requireToggle

# Initialize toggle key combobox
$toggleKeys = @("CapsLock", "NumLock", "ScrollLock")
foreach ($key in $toggleKeys) {
    $item = New-Object System.Windows.Controls.ComboBoxItem
    $item.Content = $key
    $item.Foreground = "White"
    $item.Background = "#252525"
    $toggleKeyComboBox.Items.Add($item)
    
    if ($key -eq $script:toggleKey) {
        $toggleKeyComboBox.SelectedItem = $item
    }
}

# Initialize vertical recoil mode combobox
$verticalRecoilModes = @("Low (5)", "Medium (10)", "High (15)", "Ultra (20)", "Insanity (30)", "Custom")
foreach ($mode in $verticalRecoilModes) {
    $item = New-Object System.Windows.Controls.ComboBoxItem
    $item.Content = $mode
    $item.Foreground = "White"
    $item.Background = "#252525"
    $verticalRecoilModeComboBox.Items.Add($item)
    
    if ($mode -eq $script:verticalRecoilMode) {
        $verticalRecoilModeComboBox.SelectedItem = $item
    }
}

# Initialize horizontal direction combobox
$horizontalDirections = @("None", "Left", "Right", "Random")
foreach ($direction in $horizontalDirections) {
    $item = New-Object System.Windows.Controls.ComboBoxItem
    $item.Content = $direction
    $item.Foreground = "White"
    $item.Background = "#252525"
    $horizontalDirectionComboBox.Items.Add($item)
    
    if ($direction -eq $script:horizontalDirection) {
        $horizontalDirectionComboBox.SelectedItem = $item
    }
}

# Set initial values for sliders and textboxes
$verticalCustomStrengthTextBox.Text = $script:verticalCustomStrength.ToString()
$verticalCustomStrengthSlider.Value = $script:verticalCustomStrength
$verticalDelayTextBox.Text = $script:verticalDelay.ToString()
$verticalDelaySlider.Value = $script:verticalDelay
$horizontalStrengthTextBox.Text = $script:horizontalStrength.ToString()
$horizontalStrengthSlider.Value = $script:horizontalStrength
$horizontalDelayTextBox.Text = $script:horizontalDelay.ToString()
$horizontalDelaySlider.Value = $script:horizontalDelay

# Add tooltip for status text
$statusTooltip = New-Object System.Windows.Controls.ToolTip
$statusTooltip.Content = "When active, the recoil control will work when you hold both mouse buttons. Toggle with CapsLock."
$statusText.ToolTip = $statusTooltip

# Add tooltip for preset management
$presetTooltip = New-Object System.Windows.Controls.ToolTip
$presetTooltip.Content = "Save and load your recoil control settings as presets."
$presetNameTextBox.ToolTip = $presetTooltip
$savePresetButton.ToolTip = $presetTooltip

# Add tooltip for toggle key
$toggleKeyTooltip = New-Object System.Windows.Controls.ToolTip
$toggleKeyTooltip.Content = "Select which key to use as a toggle for enabling/disabling recoil control."
$toggleKeyComboBox.ToolTip = $toggleKeyTooltip

# Add tooltip for vertical recoil mode
$verticalRecoilModeTooltip = New-Object System.Windows.Controls.ToolTip
$verticalRecoilModeTooltip.Content = "Select the strength of vertical recoil control or use a custom value."
$verticalRecoilModeComboBox.ToolTip = $verticalRecoilModeTooltip

# Add tooltip for horizontal direction
$horizontalDirectionTooltip = New-Object System.Windows.Controls.ToolTip
$horizontalDirectionTooltip.Content = "Select the direction of horizontal recoil control or set to random."
$horizontalDirectionComboBox.ToolTip = $horizontalDirectionTooltip

# Show the window
$window.ShowDialog() | Out-Null
