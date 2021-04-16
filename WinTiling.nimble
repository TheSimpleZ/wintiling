# Package

version       = "0.1.0"
author        = "Zrean Tofiq"
description   = "Windows 10 TWM"
license       = "MIT"
srcDir        = "src"
bin           = @["WinTiling"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.4.4"
requires "winim >= 3.6.0"

# before build:
#   exec "nim c --outDir:bin/ -d:useNimRtl --app:lib src/WinTilingHooks.nim"
