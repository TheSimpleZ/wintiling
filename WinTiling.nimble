# Package

version       = "0.1.0"
author        = "Zrean Tofiq"
description   = "Windows 10 TWM"
license       = "MIT"
srcDir        = "src"
bin           = @["win_tiling"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.4.4"
requires "winim >= 3.6.0"
requires "macroutils >= 1.2.0"
requires "questionable >= 0.8.0 & < 1.0.0"
requires "windows_virtual_desktops >= 0.1.0"

before build:
  cpFile "VirtualDesktopAccessor.dll", "bin/VirtualDesktopAccessor.dll"

task test, "Runs the test suite":
  exec "testament --megatest:off all"