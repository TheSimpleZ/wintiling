import ../lib/hotkeys as hkMacro
import winim/lean
import ../lib/win32/keyboard
import ../lib/layout
import ../lib/actions


const hotkeys* = initHotkeys:
  [VK_LWIN, VirtualCodes['E']]: transpose

  [VK_LWIN, VK_LEFT]: moveWindowFocusLeft
  [VK_LWIN, VK_RIGHT]: moveWindowFocusRight
  [VK_LWIN, VK_DOWN]: moveWindowFocusDown
  [VK_LWIN, VK_UP]: moveWindowFocusUp


  [VK_LWIN, VK_LSHIFT, VK_LEFT]: moveLeft
  [VK_LWIN, VK_LSHIFT, VK_RIGHT]: moveRight
  [VK_LWIN, VK_LSHIFT, VK_DOWN]: moveDown
  [VK_LWIN, VK_LSHIFT, VK_UP]: moveUp

  [VK_LMENU, VK_LEFT]: groupLeft
  [VK_LMENU, VK_RIGHT]: groupRight
  [VK_LMENU, VK_DOWN]: groupDown
  [VK_LMENU, VK_UP]: groupUp
