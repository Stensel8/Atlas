#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# Atlas.Registry domain functions: UserPaths

function Get-RegUserPaths {
    param (
        [switch]$DontCheckEnv,
        [switch]$NoDefault
    )

    $regPattern = 'Volatile Environment|AME_UserHive_'
    if ($NoDefault) {$regPattern = "$regPattern[1-9].*"}
    $initPaths = Get-ChildItem -Path "Registry::HKU" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "S-[0-9-]+(?!.*_)|$regPattern" }

    # If the 'Volatile Environment' key exists, that means it is a proper user. Built in accounts/SIDs don't have this key
    $paths = @()
    if (!$DontCheckEnv) {
        foreach ($userKey in $initPaths) {
            if ((Get-ChildItem -Path $userKey.PsPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $regPattern }).Count -ne 0) {
                $paths += $userKey
            }
        }
    } else {
        $paths = $initPaths
    }

    return $paths
}

function Get-UserPath {
    param (
        # https://learn.microsoft.com/windows/win32/shell/knownfolderid
        [string]$FolderID = 'B4BFCC3A-DB2C-424C-B029-7FE99A87C641',
        # Default user
        # 0 is the current user
        [System.IntPtr]$Token = -1,
        # Create folder if it doesn't exist
        [int]$Flags = 0x00008000
    )

    $guid = [guid]::new($FolderID)
    if ($null -eq $guid) {
        throw "Failed to convert provided FolderID!"
    }

    # https://learn.microsoft.com/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public class KnownFolder
{
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SHGetKnownFolderPath(
        [MarshalAs(UnmanagedType.LPStruct)] Guid rfid,
        uint dwFlags,
        IntPtr hToken,
        out IntPtr pszPath
    );
}
'@

    $pszPath = [IntPtr]::Zero
    $result = [KnownFolder]::SHGetKnownFolderPath($guid, $Flags, $Token, [ref]$pszPath)

    if ($result -eq 0 -and $pszPath -ne [IntPtr]::Zero) {
        $desktopPath = [Runtime.InteropServices.Marshal]::PtrToStringUni($pszPath)
        [Runtime.InteropServices.Marshal]::FreeCoTaskMem($pszPath)
        return $desktopPath
    } else {
        throw "Failed to retrieve $guid. Error code: $result"
    }
}

function Get-SystemDrive {
    $drive = $null
    foreach ($letter in @(
        $env:SystemDrive,
        (Get-CimInstance -ClassName Win32_OperatingSystem).SystemDrive,
        "C:"
    )) {
        if ($letter -and ($letter.Length -eq 2) -and (Test-Path $letter -PathType Container)) {
            $drive = $letter
            break
        }
    }

    if ($drive) {
        return $drive
    } else {
        throw "Failed to find the system drive!"
    }
}
