import ../lib/hotkeys as hkMacro
import winim/lean
import ../lib/win32/keyboard
import ../lib/layout
import ../lib/actions


const hotkeys* = initHotkeys:
  [VK_LWIN]: supressKey

  [VK_LWIN, VirtualCodes['P']]: printTree
  [VK_LWIN, VirtualCodes['E']]: transpose

  [VK_LWIN, VK_LEFT]: moveWindowFocusLeft
  [VK_LWIN, VK_RIGHT]: moveWindowFocusRight
  [VK_LWIN, VK_DOWN]: moveWindowFocusDown
  [VK_LWIN, VK_UP]: moveWindowFocusUp


  [VK_LWIN, VK_LSHIFT, VK_LEFT]: moveLeft
  [VK_LWIN, VK_LSHIFT, VK_RIGHT]: moveRight
  [VK_LWIN, VK_LSHIFT, VK_DOWN]: moveDown
  [VK_LWIN, VK_LSHIFT, VK_UP]: actions.moveUp

  [VK_LWIN, VK_LMENU, VK_LEFT]: groupLeft
  [VK_LWIN, VK_LMENU, VK_RIGHT]: groupRight
  [VK_LWIN, VK_LMENU, VK_DOWN]: groupDown
  [VK_LWIN, VK_LMENU, VK_UP]: groupUp
