﻿# Chocolatey MSYS2
#
# Copyright (C) 2015 Stefan Zimmermann <zimmermann.code@gmail.com>
#
# Licensed under the Apache License, Version 2.0

$ErrorActionPreference = 'Stop';

$packageName = 'msys2'

$url = 'http://repo.msys2.org/distrib/i686/msys2-base-i686-20160921.tar.xz'
$checksum = '7DA041072DC2F8A346803AFE4FF1E1977DD1E905'
$checksumType = 'SHA1'

$url64 = 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20160921.tar.xz'
$checksum64 = '78B1738EB6049EFB693E3D1AA4502BCBE03B2964'
$checksumType64 = 'SHA1'

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition

$packageDir = Split-Path -parent $toolsDir
Write-Host "Adding '$packageDir' to PATH..."
Install-ChocolateyPath $packageDir

$osBitness = Get-ProcessorBits

$binRoot = Get-ToolsLocation
# MSYS2 zips contain a root dir named msys32 or msys64
$msysName = 'msys' + $osBitness
$msysRoot = Join-Path $binRoot $msysName

if (Test-Path $msysRoot) {
    Write-Host "'$msysRoot' already exists and will only be updated."
}
else {
    Write-Host "Installing to '$msysRoot'"
    Install-ChocolateyZipPackage $packageName $url $binRoot $url64 `
      -checksum $checksum -checksumType $checksumType `
      -checksum64 $checksum64 -checksumType64 $checksumType64
    # check if .tar.xz was only unzipped to tar file
    # (shall work better with newer choco versions)
    $tarFile = (Get-ChildItem -path $binRoot "msys2*.tar").FullName
    Write-Host "Tar: $tarFile"
    if (Test-Path $tarFile) {
        Get-ChocolateyUnzip $tarFile $binRoot
        Remove-Item $tarFile
    } else {
        Write-Error "No tarball found in $binRoot"
    }
}

Write-Host "Adding '$msysRoot' to PATH..."
Install-ChocolateyPath $msysRoot

# Finally initialize and upgrade MSYS2 according to https://msys2.github.io
# and https://sourceforge.net/p/msys2/wiki/MSYS2%20installation/
Write-Host "Initializing MSYS2..."

$msysExe = Join-Path $msysRoot msys2.exe
if (-not (Test-Path $msysExe)) {
    throw @"
No '$msysShell' found.
You probably have an outdated MSYS2 installation in '$msysRoot'.
Please delete '$msysRoot' and reinstall.
"@
}

Write-Host "Starting '$msysExe'..."
Start-Process -Wait $msysExe -ArgumentList 'bash', '-c', exit

$command = 'pacman --noconfirm -Syuu'
Write-Host "Upgrading core system packages with '$command'..."
Start-Process -Wait $msysExe -ArgumentList 'bash', '-c', "'$command'"

Write-Host "Upgrading full system with '$command'..."
Start-Process -Wait $msysExe -ArgumentList 'bash', '-c', "'$command'"
