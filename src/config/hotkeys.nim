import ../lib/hotkeys as hkMacro
import winim/lean
import ../lib/win32/keyboard
import ../lib/actions
import ../lib/layout


const hotkeys* = initHotkeys:
  [VK_LWIN]: supressKey

  [VK_LWIN, VirtualCodes['P']]: printTree
  [VK_LWIN, VK_SPACE]: transpose

  [VK_LWIN, VK_LEFT]: move_window_focus(Left)
  [VK_LWIN, VK_RIGHT]: move_window_focus(Right)
  [VK_LWIN, VK_DOWN]: move_window_focus(Down)
  [VK_LWIN, VK_UP]: move_window_focus(Up)


  [VK_LWIN, VK_LSHIFT, VK_LEFT]: move_window(Left)
  [VK_LWIN, VK_LSHIFT, VK_RIGHT]: move_window(Right)
  [VK_LWIN, VK_LSHIFT, VK_DOWN]: move_window(Down)
  [VK_LWIN, VK_LSHIFT, VK_UP]: move_window(Up)

  # [VK_LWIN, VK_LSHIFT, VirtualCodes['1']]: send_to_left_desktop
  # [VK_LWIN, VK_LSHIFT, VirtualCodes['2']]: send_to_left_desktop2


  [VK_LWIN, VK_LMENU, VK_LEFT]: group_with(Left)
  [VK_LWIN, VK_LMENU, VK_RIGHT]: group_with(Right)
  [VK_LWIN, VK_LMENU, VK_DOWN]: group_with(Down)
  [VK_LWIN, VK_LMENU, VK_UP]: group_with(Up)

  [VK_LWIN, VK_LCONTROL, VK_LSHIFT, VK_LEFT]: send_to_desktop(Left)
  [VK_LWIN, VK_LCONTROL, VK_LSHIFT, VK_RIGHT]: send_to_desktop(Right)
  # [VK_LWIN, VK_LCONTROL, VK_DOWN]: group_with_window_below
  # [VK_LWIN, VK_LCONTROL, VK_UP]: group_with_window_above
