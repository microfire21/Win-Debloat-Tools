Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"Open-File.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\"Title-Templates.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\debloat-helper\"Remove-ItemVerified.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\debloat-helper\"Set-ItemPropertyVerified.psm1"
Import-Module -DisableNameChecking $PSScriptRoot\..\utils\"Individual-Tweaks.psm1"

# Adapted from: https://github.com/ChrisTitusTech/win10script
# Adapted from: https://github.com/Sycnex/Windows10Debloater
# Adapted from: https://github.com/kalaspuffar/windows-debloat

function Register-PersonalTweaksList() {
    [CmdletBinding()]
    param (
        [Switch] $Revert,
        [Int]    $Zero = 0,
        [Int]    $One = 1,
        [Array]  $EnableStatus = @(
            @{ Symbol = "-"; Status = "Disabling"; }
            @{ Symbol = "+"; Status = "Enabling"; }
        )
    )
    $TweakType = "Personal"

    If ($Revert) {
        Write-Status -Types "*", $TweakType -Status "Reverting the tweaks is set to '$Revert'." -Warning
        $Zero = 1
        $One = 0
        $EnableStatus = @(
            @{ Symbol = "*"; Status = "Restoring"; }
            @{ Symbol = "*"; Status = "Re-Disabling"; }
        )
    }

    # Initialize all Path variables used to Registry Tweaks
    $PathToCUAccessibility = "HKCU:\Control Panel\Accessibility"
    $PathToCUPoliciesEdge = "HKCU:\SOFTWARE\Policies\Microsoft\Edge"
    $PathToCUExplorer = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    $PathToCUExplorerAdvanced = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $PathToCUPoliciesExplorer = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    $PathToCUPoliciesLiveTiles = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    $PathToCUNewsAndInterest = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds"
    $PathToCUWindowsSearch = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    $PathToLMPoliciesEdge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    $PathToLMPoliciesExplorer = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $PathToLMPoliciesNewsAndInterest = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
    $PathToLMPoliciesWindowsSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

    Write-Title "My Personal Tweaks"
    If (!$Revert) {
        $Scripts = @("enable-photo-viewer.reg")
        Enable-DarkTheme
    } Else {
        $Scripts = @("disable-photo-viewer.reg")
        Disable-DarkTheme
    }
    Open-RegFilesCollection -RelativeLocation "src\utils" -Scripts $Scripts -NoDialog

    # Show Task Manager details - Applicable to 1607 and later - Although this functionality exist even in earlier versions, the Task Manager's behavior is different there and is not compatible with this tweak
    If ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild -lt 22557) {
        Write-Status -Types "+", $TweakType -Status "Showing task manager details..."
        $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
        Do {
            Start-Sleep -Milliseconds 100
            $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
        } Until ($preferences)
        Stop-Process $taskmgr
        $preferences.Preferences[28] = 0
        Set-ItemPropertyVerified -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences
    } Else {
        Write-Status -Types "?", $TweakType -Status "Task Manager patch not run in builds 22557+ due to bug" -Warning
    }

    Write-Section "Windows Explorer Tweaks"
    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) Quick Access from Windows Explorer..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorer" -Name "ShowFrequent" -Type DWord -Value $Zero
    Set-ItemPropertyVerified -Path "$PathToCUExplorer" -Name "ShowRecent" -Type DWord -Value $Zero
    Set-ItemPropertyVerified -Path "$PathToCUExplorer" -Name "HubMode" -Type DWord -Value $One

    Write-Status -Types "-", $TweakType -Status "Removing 3D Objects from This PC..."
    Remove-ItemVerified -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse
    Remove-ItemVerified -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse

    Write-Status -Types "-", $TweakType -Status "Removing 'Edit with Paint 3D' from the Context Menu..."
    $Paint3DFileTypes = @(".3mf", ".bmp", ".fbx", ".gif", ".jfif", ".jpe", ".jpeg", ".jpg", ".png", ".tif", ".tiff")
    ForEach ($FileType in $Paint3DFileTypes) {
        Write-Status -Types "-", $TweakType -Status "Removing Paint 3D from file type: $FileType"
        Remove-ItemVerified -Path "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\$FileType\Shell\3D Edit" -Recurse
    }

    Write-Status -Types $EnableStatus[1].Symbol, $TweakType -Status "$($EnableStatus[1].Status) Show Drives without Media..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "HideDrivesWithNoMedia" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) MRU lists (jump lists) of XAML apps in Start Menu..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "Start_TrackDocs" -Type DWord -Value $Zero
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "Start_TrackProgs" -Type DWord -Value $Zero

    Write-Status -Types "*", $TweakType -Status "Restoring Aero-Shake Minimize feature..."
    Remove-ItemProperty -Path "$PathToCUExplorerAdvanced" -Name "DisallowShaking" -Force -ErrorAction SilentlyContinue

    Write-Status -Types "+", $TweakType -Status "Setting Windows Explorer to start on This PC instead of Quick Access..."
    # [@] (1 = This PC, 2 = Quick access) # DO NOT REVERT, BREAKS EXPLORER.EXE
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "LaunchTo" -Type DWord -Value 1

    Write-Status -Types $EnableStatus[1].Symbol, $TweakType -Status "$($EnableStatus[1].Status) Show hidden files in Explorer..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "Hidden" -Type DWord -Value $One

    Write-Status -Types $EnableStatus[1].Symbol, $TweakType -Status "$($EnableStatus[1].Status) Showing file transfer details..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value $One

    Write-Status -Types "-", $TweakType -Status "Disabling '- Shortcut' name after creating a shortcut..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorer" -Name "link" -Type Binary -Value ([byte[]](0x00, 0x00, 0x00, 0x00))

    Write-Section "Task Bar Tweaks"
    Write-Caption "Task Bar - Windows 10 Compatible"
    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) the 'Search Box' from taskbar..."
    # [@] (0 = Hide completely, 1 = Show icon only, 2 = Show long Search Box)
    Set-ItemPropertyVerified -Path "$PathToCUWindowsSearch" -Name "SearchboxTaskbarMode" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) Windows search highlights from taskbar..."
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesWindowsSearch" -Name "EnableDynamicContentInWSB" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) the 'Task View' icon from taskbar..."
    # [@] (0 = Hide Task view, 1 = Show Task view)
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "ShowTaskViewButton" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) Open on Hover from 'News and Interest' from taskbar..."
    # [@] (0 = Disable, 1 = Enable)
    Set-ItemPropertyVerified -Path "$PathToCUNewsAndInterest" -Name "ShellFeedsTaskbarOpenOnHover" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) 'News and Interest' from taskbar..."
    # [@] (0 = Disable, 1 = Enable)
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesNewsAndInterest" -Name "EnableFeeds" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) 'People' icon from taskbar..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced\People" -Name "PeopleBand" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) Live Tiles..."
    Set-ItemPropertyVerified -Path $PathToCUPoliciesLiveTiles -Name "NoTileApplicationNotification" -Type DWord -Value $One

    Write-Status -Types "*", $TweakType -Status "Enabling Auto tray icons..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorer" -Name "EnableAutoTray" -Type DWord -Value 1

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) 'Meet now' icon on taskbar..."
    # [@] (0 = Show Meet Now, 1 = Hide Meet Now)
    Set-ItemPropertyVerified -Path "$PathToLMPoliciesExplorer" -Name "HideSCAMeetNow" -Type DWord -Value $One

    Write-Caption "Task Bar - Windows 11 Compatible"
    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) 'Widgets' icon from taskbar..."
    # [@] (0 = Hide Widgets, 1 = Show Widgets)
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "TaskbarDa" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) 'Chat' icon from taskbar..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "TaskbarMn" -Type DWord -Value $Zero

    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) creation of Thumbs.db thumbnail cache files..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "DisableThumbnailCache" -Type DWord -Value $One
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "DisableThumbsDBOnNetworkFolders" -Type DWord -Value $One

    Write-Caption "Colors"
    Write-Status -Types "*", $TweakType -Status "Restoring taskbar transparency..."
    Set-ItemPropertyVerified -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Type DWord -Value 1

    Write-Section "System"
    Write-Caption "Multitasking"
    Write-Status -Types "-", $TweakType -Status "Disabling Edge multi tabs showing on Alt + Tab..."
    Set-ItemPropertyVerified -Path "$PathToCUExplorerAdvanced" -Name "MultiTaskingAltTabFilter" -Type DWord -Value 3

    Write-Section "Devices"
    Write-Caption "Bluetooth & other devices"
    Write-Status -Types $EnableStatus[1].Symbol, $TweakType -Status "$($EnableStatus[1].Status) driver download over metered connections..."
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceSetup" -Name "CostedNetworkPolicy" -Type DWord -Value $One

    Write-Section "Cortana Tweaks"
    Write-Status -Types $EnableStatus[0].Symbol, $TweakType -Status "$($EnableStatus[0].Status) Bing Search in Start Menu..."
    Set-ItemPropertyVerified -Path "$PathToCUWindowsSearch" -Name "BingSearchEnabled" -Type DWord -Value $Zero
    Set-ItemPropertyVerified -Path "$PathToCUWindowsSearch" -Name "CortanaConsent" -Type DWord -Value $Zero
    Set-ItemPropertyVerified -Path "$PathToCUPoliciesExplorer" -Name "DisableSearchBoxSuggestions" -Type DWord -Value $One

    Write-Section "Ease of Access"
    Write-Caption "Keyboard"
    Write-Status -Types "-", $TweakType -Status "Disabling Sticky Keys..."
    Set-ItemPropertyVerified -Path "$PathToCUAccessibility\StickyKeys" -Name "Flags" -Value "506"
    Set-ItemPropertyVerified -Path "$PathToCUAccessibility\Keyboard Response" -Name "Flags" -Value "122"
    Set-ItemPropertyVerified -Path "$PathToCUAccessibility\ToggleKeys" -Name "Flags" -Value "58"

    Write-Section "Microsoft Edge Policies"
    Write-Caption "Privacy, search and services -> Address bar and search"
    Write-Status -Types "*", $TweakType -Status "Show me search and site suggestions using my typed characters..."
    Remove-ItemProperty -Path "$PathToCUPoliciesEdge", "$PathToLMPoliciesEdge" -Name "SearchSuggestEnabled" -Force -ErrorAction SilentlyContinue

    Write-Status -Types "*", $TweakType -Status "Show me history and favorite suggestions and other data using my typed characters..."
    Remove-ItemProperty -Path "$PathToCUPoliciesEdge", "$PathToLMPoliciesEdge" -Name "LocalProvidersEnabled" -Force -ErrorAction SilentlyContinue

    Write-Status -Types "*", $TweakType -Status "Restoring Error reporting..."
    Set-ItemPropertyVerified -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 0

    Write-Status -Types "+", $TweakType -Status "Bringing back F8 alternative Boot Modes..."
    bcdedit /set `{current`} bootmenupolicy Legacy

    Write-Section "Power Plan Tweaks"
    $TimeoutScreenBattery = 5
    $TimeoutScreenPluggedIn = 10

    $TimeoutStandByBattery = 15
    $TimeoutStandByPluggedIn = 180

    $TimeoutDiskBattery = 20
    $TimeoutDiskPluggedIn = 30

    $TimeoutHibernateBattery = 15
    $TimeoutHibernatePluggedIn = 15

    Write-Status -Types "+", $TweakType -Status "Setting the Monitor Timeout to AC: $TimeoutScreenPluggedIn and DC: $TimeoutScreenBattery..."
    powercfg -Change Monitor-Timeout-AC $TimeoutScreenPluggedIn
    powercfg -Change Monitor-Timeout-DC $TimeoutScreenBattery

    Write-Status -Types "+", $TweakType -Status "Setting the Standby Timeout to AC: $TimeoutStandByPluggedIn and DC: $TimeoutStandByBattery..."
    powercfg -Change Standby-Timeout-AC $TimeoutStandByPluggedIn
    powercfg -Change Standby-Timeout-DC $TimeoutStandByBattery

    Write-Status -Types "+", $TweakType -Status "Setting the Disk Timeout to AC: $TimeoutDiskPluggedIn and DC: $TimeoutDiskBattery..."
    powercfg -Change Disk-Timeout-AC $TimeoutDiskPluggedIn
    powercfg -Change Disk-Timeout-DC $TimeoutDiskBattery

    Write-Status -Types "+", $TweakType -Status "Setting the Hibernate Timeout to AC: $TimeoutHibernatePluggedIn and DC: $TimeoutHibernateBattery..."
    powercfg -Change Hibernate-Timeout-AC $TimeoutHibernatePluggedIn
    powercfg -Change Hibernate-Timeout-DC $TimeoutHibernateBattery
}

If (!$Revert) {
    Register-PersonalTweaksList # Personal UI, Network, Energy and Accessibility Optimizations
} Else {
    Register-PersonalTweaksList -Revert
}
