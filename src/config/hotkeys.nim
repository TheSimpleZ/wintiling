import ../lib/hotkeys as hkMacro
import winim/lean
import ../lib/win32/keyboard
import ../lib/layout
import ../lib/actions


const hotkeys* = initHotkeys:
  [VK_LWIN, VirtualCodes['E']]: transpose
  [VK_LWIN, VK_LEFT]: moveWindowFocusBack
  [VK_LWIN, VK_LEFT, VK_LSHIFT]: moveBack
  [VK_LWIN, VK_RIGHT, VK_LSHIFT]: moveForward
  [VK_LWIN, VK_RIGHT]: moveWindowFocusForward
  [VK_LWIN, VK_DOWN]: nothing
  [VK_LWIN, VK_DOWN, VK_LSHIFT]: nothing