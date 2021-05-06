import ../lib/hotkeys as hkMacro
import winim/lean
import ../lib/win32/keyboard
import ../lib/actions


const hotkeys* = initHotkeys:
  [VK_LWIN]: supressKey

  [VK_LWIN, VirtualCodes['P']]: printTree
  [VK_LWIN, VK_SPACE]: transpose

  [VK_LWIN, VK_LEFT]: move_window_focus_left
  [VK_LWIN, VK_RIGHT]: move_window_focus_right
  [VK_LWIN, VK_DOWN]: move_window_focus_down
  [VK_LWIN, VK_UP]: move_window_focus_up


  [VK_LWIN, VK_LSHIFT, VK_LEFT]: move_window_left
  [VK_LWIN, VK_LSHIFT, VK_RIGHT]: move_window_right
  [VK_LWIN, VK_LSHIFT, VK_DOWN]: move_window_down
  [VK_LWIN, VK_LSHIFT, VK_UP]: move_window_up

  [VK_LWIN, VK_LMENU, VK_LEFT]: group_with_left_window
  [VK_LWIN, VK_LMENU, VK_RIGHT]: group_with_right_window
  [VK_LWIN, VK_LMENU, VK_DOWN]: group_with_window_below
  [VK_LWIN, VK_LMENU, VK_UP]: group_with_window_above
