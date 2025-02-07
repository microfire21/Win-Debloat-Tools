Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"Get-HardwareInfo.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"Grant-RegistryPermission.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"Manage-Software.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"New-Shortcut.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"Title-Templates.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\debloat-helper\"Remove-ItemVerified.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\debloat-helper\"Set-CapabilityState.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\debloat-helper\"Set-ItemPropertyVerified.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\debloat-helper\"Set-OptionalFeatureState.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\debloat-helper\"Set-ServiceStartup.psm1"

$DesktopPath = [Environment]::GetFolderPath("Desktop");
$PathToLMPoliciesCloudContent = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$PathToLMPoliciesAppGameDVR = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR"
$PathToLMPoliciesCortana = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
$PathToLMPoliciesGameDVR = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
$PathToLMPoliciesSystem = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
$PathToLMPoliciesWindowsUpdate = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$PathToCUClipboard = "HKCU:\Software\Microsoft\Clipboard"
$PathToCUOnlineSpeech = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
$PathToCUThemes = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$PathToCUXboxGameBar = "HKCU:\Software\Microsoft\GameBar"

function Disable-ActivityHistory() {
    Write-Status -Types "-", "Privacy" -Status "Disabling Activity History..."
    Set-ItemPropertyVerified -Path $PathToLMPoliciesSystem -Name "EnableActivityFeed" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path $PathToLMPoliciesSystem -Name "PublishUserActivities" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path $PathToLMPoliciesSystem -Name "UploadUserActivities" -Type DWord -Value 0
}

function Enable-ActivityHistory() {
    Write-Status -Types "*", "Privacy" -Status "Enabling Activity History..."
    Remove-ItemProperty -Path $PathToLMPoliciesSystem -Name "EnableActivityFeed"
    Remove-ItemProperty -Path $PathToLMPoliciesSystem -Name "PublishUserActivities"
    Remove-ItemProperty -Path $PathToLMPoliciesSystem -Name "UploadUserActivities"
}

function Disable-AutomaticWindowsUpdate() {
    Write-Status -Types "-", "WU" -Status "Disabling Automatic Download and Installation of Windows Updates..."
    # [@] (2 = Notify before download, 3 = Automatically download and notify of installation)
    # [@] (4 = Automatically download and schedule installation, 5 = Automatic Updates is required and users can configure it)
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesWindowsUpdate" -Name "AUOptions" -Type DWord -Value 2
}

function Enable-AutomaticWindowsUpdate() {
    Write-Status -Types "*", "WU" -Status "Enabling Automatic Download and Installation of Windows Updates..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesWindowsUpdate" -Name "AUOptions" -Type DWord -Value 5
}

function Disable-BackgroundAppsToogle() {
    Write-Status -Types "-", "Misc" -Status "Disabling Background Apps..."
    Set-ItemPropertyVerified -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BackgroundAppGlobalToggle" -Type DWord -Value 0
}

function Enable-BackgroundAppsToogle() {
    Write-Status -Types "*", "Misc" -Status "Enabling Background Apps..."
    Set-ItemPropertyVerified -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BackgroundAppGlobalToggle" -Type DWord -Value 1
}

function Disable-ClipboardHistory() {
    Write-Status -Types "-", "Privacy" -Status "Disabling Clipboard History (requires reboot!)..."
    Remove-ItemProperty -Path "$PathToLMPoliciesSystem" -Name "AllowClipboardHistory"
    Remove-ItemProperty -Path "$PathToCUClipboard" -Name "EnableClipboardHistory"
}

function Enable-ClipboardHistory() {
    Write-Status -Types "*", "Privacy" -Status "Enabling Clipboard History (requires reboot!)..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesSystem" -Name "AllowClipboardHistory" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToCUClipboard" -Name "EnableClipboardHistory" -Type DWord -Value 1
}

function Disable-ClipboardSyncAcrossDevice() {
    Write-Status -Types "-", "Privacy" -Status "Disabling Clipboard across devices (must be using MS account)..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesSystem" -Name "AllowCrossDeviceClipboard" -Type DWord -Value 0
    If ((Get-Item "$PathToCUClipboard").Property -contains "CloudClipboardAutomaticUpload") {
        Remove-ItemProperty -Path "$PathToCUClipboard" -Name "CloudClipboardAutomaticUpload"
    }

    If ((Get-Item "$PathToCUClipboard").Property -contains "EnableCloudClipboard") {
        Remove-ItemProperty -Path "$PathToCUClipboard" -Name "EnableCloudClipboard"
    }

}

function Enable-ClipboardSyncAcrossDevice() {
    Write-Status -Types "*", "Privacy" -Status "Enabling Clipboard across devices (must be using MS account)..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesSystem" -Name "AllowCrossDeviceClipboard" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToCUClipboard" -Name "CloudClipboardAutomaticUpload" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToCUClipboard" -Name "EnableCloudClipboard " -Type DWord -Value 1
}

function Disable-Cortana() {
    Write-Status -Types "-", "Privacy" -Status "Disabling Cortana..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "AllowCortana" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "AllowCloudSearch" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "ConnectedSearchUseWeb" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "DisableWebSearch" -Type DWord -Value 1
}

function Enable-Cortana() {
    Write-Status -Types "*", "Privacy" -Status "Enabling Cortana..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "AllowCortana" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "AllowCloudSearch" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "ConnectedSearchUseWeb" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCortana" -Name "DisableWebSearch" -Type DWord -Value 0
}

function Disable-DarkTheme() {
    Write-Status -Types "*", "Personal" -Status "Disabling Dark Theme..."
    Set-ItemPropertyVerified -Path "$PathToCUThemes" -Name "AppsUseLightTheme" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToCUThemes" -Name "SystemUsesLightTheme" -Type DWord -Value 1
}

function Enable-DarkTheme() {
    Write-Status -Types "+", "Personal" -Status "Enabling Dark Theme..."
    Set-ItemPropertyVerified -Path "$PathToCUThemes" -Name "AppsUseLightTheme" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "$PathToCUThemes" -Name "SystemUsesLightTheme" -Type DWord -Value 0
}

function Disable-EncryptedDNS() {
    # I'm still not sure how to disable DNS over HTTPS, so this'll need to wait
    # Adapted from: https://stackoverflow.com/questions/64465089/powershell-cmdlet-to-remove-a-statically-configured-dns-addresses-from-a-network
    Write-Status -Types "*" -Status "Resetting DNS server configs..."
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet*" -ResetServerAddresses
    Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi*" -ResetServerAddresses
}

function Enable-EncryptedDNS() {
    # Adapted from: https://techcommunity.microsoft.com/t5/networking-blog/windows-insiders-gain-new-dns-over-https-controls/ba-p/2494644
    Write-Status -Types "+" -Status "Setting up the DNS over HTTPS for Google and Cloudflare (ipv4 and ipv6)..."
    Set-DnsClientDohServerAddress -ServerAddress ("8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844") -AutoUpgrade $true -AllowFallbackToUdp $true
    Set-DnsClientDohServerAddress -ServerAddress ("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001") -AutoUpgrade $true -AllowFallbackToUdp $true

    Write-Status -Types "+" -Status "Setting up the DNS from Cloudflare and Google (ipv4 and ipv6)..."
    #Get-DnsClientServerAddress # To look up the current config.           # Cloudflare, Google,         Cloudflare,              Google
    Set-DNSClientServerAddress -InterfaceAlias "Ethernet*" -ServerAddresses ("1.1.1.1", "8.8.8.8", "2606:4700:4700::1111", "2001:4860:4860::8888")
    Set-DNSClientServerAddress -InterfaceAlias    "Wi-Fi*" -ServerAddresses ("1.1.1.1", "8.8.8.8", "2606:4700:4700::1111", "2001:4860:4860::8888")
}

function Disable-FastShutdownShortcut() {
    Write-Status -Types "*" -Status "Removing the shortcut to shutdown the computer on the Desktop..." -Warning
    Remove-ItemVerified -Path "$DesktopPath\Fast Shutdown.lnk"
}

function Enable-FastShutdownShortcut() {
    $SourcePath = "$env:SystemRoot\System32\shutdown.exe"
    $ShortcutPath = "$DesktopPath\Fast Shutdown.lnk"
    $Description = "Turns off the computer without any prompt"
    $IconLocation = "$env:SystemRoot\System32\shell32.dll, 27"
    $Arguments = "-s -f -t 0"
    $Hotkey = "CTRL+ALT+F12"

    Write-Status -Types "+" -Status "Creating a shortcut to shutdown the computer on the Desktop..."
    New-Shortcut -SourcePath $SourcePath -ShortcutPath $ShortcutPath -Description $Description -IconLocation $IconLocation -Arguments $Arguments -Hotkey $Hotkey
}

function Disable-GodMode() {
    Write-Status -Types "*" -Status "Disabling God Mode hidden folder..." -Warning
    Write-Host @"
###############################################################################
#       _______  _______  ______     __   __  _______  ______   _______       #
#      |       ||       ||      |   |  |_|  ||       ||      | |       |      #
#      |    ___||   _   ||  _    |  |       ||   _   ||  _    ||    ___|      #
#      |   | __ |  | |  || | |   |  |       ||  | |  || | |   ||   |___       #
#      |   ||  ||  |_|  || |_|   |  |       ||  |_|  || |_|   ||    ___|      #
#      |   |_| ||       ||       |  | ||_|| ||       ||       ||   |___       #
#      |_______||_______||______|   |_|   |_||_______||______| |_______|      #
#                                                                             #
#         God Mode has been disabled, link removed from your Desktop          #
#                                                                             #
###############################################################################
"@ -ForegroundColor Cyan

    $DesktopPath = [Environment]::GetFolderPath("Desktop");
    Remove-ItemVerified -Path "$DesktopPath\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
}

function Enable-GodMode() {
    Write-Status -Types "+" -Status "Enabling God Mode hidden folder on Desktop..."
    Write-Host @"
###############################################################################
#       _______  _______  ______     __   __  _______  ______   _______       #
#      |       ||       ||      |   |  |_|  ||       ||      | |       |      #
#      |    ___||   _   ||  _    |  |       ||   _   ||  _    ||    ___|      #
#      |   | __ |  | |  || | |   |  |       ||  | |  || | |   ||   |___       #
#      |   ||  ||  |_|  || |_|   |  |       ||  |_|  || |_|   ||    ___|      #
#      |   |_| ||       ||       |  | ||_|| ||       ||       ||   |___       #
#      |_______||_______||______|   |_|   |_||_______||______| |_______|      #
#                                                                             #
#      God Mode has been enabled, check out the new link on your Desktop      #
#                                                                             #
###############################################################################
"@ -ForegroundColor Blue

    $DesktopPath = [Environment]::GetFolderPath("Desktop");
    New-Item -Path "$DesktopPath\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ItemType Directory -Force
}

function Disable-Hibernate() {
    Write-Status -Types "-", "Performance" -Status "Disabling Hibernate (Slows boot time and deletes '$env:SystemDrive\hiberfil.sys' file)..."
    powercfg -Hibernate off | Out-Host # On my PC booted up in 20s 32ms
}

function Enable-Hibernate() {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateSet('Full', 'Reduced')]
        [String] $Type = 'Full'
    )

    Write-Status -Types "+", "Performance" -Status "Enabling Hibernate (Boots faster and generates '$env:SystemDrive\hiberfil.sys' file)..."
    powercfg -Hibernate on | Out-Host # On my PC booted up in 12s 56ms Full/Reduced

    # Full = Enables Hibernate power button and Fast Startup | Reduced = Enable Fast Startup only
    Write-Status -Types "+", "Performance" -Status "Setting Hibernate size to $Type..."
    powercfg -Hibernate -Type $Type | Out-Host
}

function Disable-InternetExplorer() {
    Set-OptionalFeatureState -State 'Disabled' -OptionalFeatures @("Internet-Explorer-Optional-*")
}

function Enable-InternetExplorer() {
    Set-OptionalFeatureState -State 'Enabled' -OptionalFeatures @("Internet-Explorer-Optional-*")
}

# Code from: https://answers.microsoft.com/en-us/windows/forum/all/set-the-mouse-scroll-direction-to-reverse-natural/ede4ccc4-3846-4184-a86d-a028515040c0
function Disable-MouseNaturalScroll() {
    Get-PnpDevice -Class Mouse -PresentOnly -Status OK | ForEach-Object {
        Write-Status -Types "*" -Status "Disabling mouse natural mode on $($_.Name): $($_.DeviceID) (requires reboot!)"
        Set-ItemPropertyVerified -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.DeviceID)\Device Parameters" -Name "FlipFlopWheel" -Type DWord -Value 0
    }
}

function Enable-MouseNaturalScroll() {
    Get-PnpDevice -Class Mouse -PresentOnly -Status OK | ForEach-Object {
        Write-Status -Types "+" -Status "Enabling mouse natural mode on $($_.Name): $($_.DeviceID) (requires reboot!)"
        Set-ItemPropertyVerified -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.DeviceID)\Device Parameters" -Name "FlipFlopWheel" -Type DWord -Value 1
    }
}

function Disable-OldVolumeControl() {
    Write-Status -Types "*", "Misc" -Status "Disabling Old Volume Control..."
    Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\MTCUVC" -Name "EnableMtcUvc"
}

function Enable-OldVolumeControl() {
    Write-Status -Types "+", "Misc" -Status "Enabling Old Volume Control..."
    Set-ItemPropertyVerified -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\MTCUVC" -Name "EnableMtcUvc" -Type DWord -Value 0
}

function Disable-OnlineSpeechRecognition() {
    Write-Status -Types "-", "Privacy" -Status "Disabling Online Speech Recognition..."
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization" -Type DWord -Value 0
    # [@] (0 = Decline, 1 = Accept)
    Set-ItemPropertyVerified -Path "$PathToCUOnlineSpeech" -Name "HasAccepted" -Type DWord -Value 0
}

function Enable-OnlineSpeechRecognition() {
    Write-Status -Types "+", "Privacy" -Status "Enabling Online Speech Recognition..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization"
    # [@] (0 = Decline, 1 = Accept)
    Set-ItemPropertyVerified -Path "$PathToCUOnlineSpeech" -Name "HasAccepted" -Type DWord -Value 1
}

function Disable-PhoneLink() {
    Write-Status -Types "-", "Privacy" -Status "Disabling Phone Link (Your Phone)..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesSystem" -Name "EnableMmx" -Type DWord -Value 0
}

function Enable-PhoneLink() {
    Write-Status -Types "*", "Privacy" -Status "Enabling Phone Link (Your Phone)..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesCloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesSystem" -Name "EnableMmx" -Type DWord -Value 1
}

function Disable-PowerShellISE() {
    Set-CapabilityState -State Disabled -Capabilities @("Microsoft.Windows.PowerShell.ISE*")
}

function Enable-PowerShellISE() {
    Set-CapabilityState -State Enabled -Capabilities @("Microsoft.Windows.PowerShell.ISE*")
}

function Disable-PrintToPDFServicesToogle() {
    Set-OptionalFeatureState -State 'Disabled' -OptionalFeatures @("Printing-PrintToPDFServices-Features")
}

function Enable-PrintToPDFServicesToogle() {
    Set-OptionalFeatureState -State 'Enabled' -OptionalFeatures @("Printing-PrintToPDFServices-Features")
}

function Disable-PrintingXPSServicesToogle() {
    Set-OptionalFeatureState -State 'Disabled' -OptionalFeatures @("Printing-XPSServices-Features")
}

function Enable-PrintingXPSServicesToogle() {
    Set-OptionalFeatureState -State 'Enabled' -OptionalFeatures @("Printing-XPSServices-Features")
}

function Disable-SearchAppForUnknownExt() {
    Write-Status -Types "-", "Misc" -Status "Disabling Search for App in Store for Unknown Extensions..."
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith" -Type DWord -Value 1
}

function Enable-SearchAppForUnknownExt() {
    Write-Status -Types "*", "Misc" -Status "Enabling Search for App in Store for Unknown Extensions..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith"
}

function Disable-Telemetry() {
    Write-Status -Types "-", "Privacy" -Status "Disabling Telemetry..."
    # [@] (0 = Security (Enterprise only), 1 = Basic Telemetry, 2 = Enhanced Telemetry, 3 = Full Telemetry)
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowDeviceNameInTelemetry" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0

    Stop-Service "DiagTrack" -NoWait -Force
    Set-ServiceStartup -State 'Disabled' -Services "DiagTrack"
}

function Enable-Telemetry() {
    Write-Status -Types "*", "Privacy" -Status "Enabling Telemetry..."
    # [@] (0 = Security (Enterprise only), 1 = Basic Telemetry, 2 = Enhanced Telemetry, 3 = Full Telemetry)
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowDeviceNameInTelemetry"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry"

    Set-ServiceStartup -State 'Manual' -Services "DiagTrack"
    Start-Service "DiagTrack"
}

function Disable-WindowsMediaPlayer() {
    Set-OptionalFeatureState -State 'Disabled' -OptionalFeatures @("MediaPlayback")
}

function Enable-WindowsMediaPlayer() {
    Set-OptionalFeatureState -State 'Enabled' -OptionalFeatures @("MediaPlayback")
}

function Disable-WSearchService() {
    Write-Status -Types "-", "Service" -Status "Disabling Search Indexing (Recommended for HDDs)..."
    Get-Service -Name "WSearch" -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
    Stop-Service "WSearch" -Force -NoWait
}

function Enable-WSearchService() {
    Write-Status -Types "*", "Service" -Status "Enabling Search Indexing (Recommended for SSDs)..."
    Get-Service -Name "WSearch" -ErrorAction SilentlyContinue | Set-Service -StartupType Automatic
    Start-Service "WSearch"
}

function Disable-XboxGameBarDVRandMode() {
    # Adapted from: https://docs.microsoft.com/en-us/answers/questions/241800/completely-disable-and-remove-xbox-apps-and-relate.html
    Write-Status -Types "-", "Performance" -Status "Disabling Xbox Game Bar DVR..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesAppGameDVR" -Name "value" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesGameDVR" -Name "AllowGameDVR" -Type DWord -Value 0
    Set-ServiceStartup -State 'Disabled' -Services "BcastDVRUserService*"

    Write-Status -Types "-", "Performance" -Status "Enabling Game mode..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "AutoGameModeEnabled" -Type DWord -Value 0
    Write-Status -Types "-", "Performance" -Status "Enabling Game Mode Notifications..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "ShowGameModeNotifications" -Type DWord -Value 0
    Write-Status -Types "-", "Performance" -Status "Enabling Game Bar tips..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "ShowStartupPanel" -Type DWord -Value 0
    Write-Status -Types "-", "Performance" -Status "Enabling Open Xbox Game Bar using Xbox button on Game Controller..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "UseNexusForGameBarEnabled" -Type DWord -Value 0

    Grant-RegistryPermission -Key "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter"
    Write-Status -Types "-", "Performance" -Status "Disabling GameBar Presence Writer..."
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" -Name "ActivationType" -Type DWord -Value 0
}

function Enable-XboxGameBarDVRandMode() {
    Write-Status -Types "*", "Performance" -Status "Enabling Xbox Game Bar DVR..."
    Write-Status -Types "*", "Performance" -Status "Removing GameDVR policies..."
    Remove-ItemVerified -Path "$PathToLMPoliciesAppGameDVR" -Recurse
    Set-ItemPropertyVerified -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 1
    Set-ItemPropertyVerified -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 1
    Remove-ItemProperty -Path "$PathToLMPoliciesGameDVR" -Name "AllowGameDVR"

    Set-ServiceStartup -State 'Manual' -Services "BcastDVRUserService*"

    Write-Status -Types "*", "Performance" -Status "Enabling Game mode..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "AutoGameModeEnabled" -Type DWord -Value 1
    Write-Status -Types "*", "Performance" -Status "Enabling Game Mode Notifications..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "ShowGameModeNotifications" -Type DWord -Value 1
    Write-Status -Types "*", "Performance" -Status "Enabling Game Bar tips..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "ShowStartupPanel" -Type DWord -Value 1
    Write-Status -Types "*", "Performance" -Status "Enabling Open Xbox Game Bar using Xbox button on Game Controller..."
    Set-ItemPropertyVerified -Path "$PathToCUXboxGameBar" -Name "UseNexusForGameBarEnabled" -Type DWord -Value 1

    Grant-RegistryPermission -Key "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter"
    Write-Status -Types "*", "Performance" -Status "Enabling GameBar Presence Writer..."
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" -Name "ActivationType" -Type DWord -Value 1
}
