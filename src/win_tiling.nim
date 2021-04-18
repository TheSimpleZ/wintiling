import winim/com
import win_automation
import terminal
import sequtils
import window

let winAuto = newWinAutomation()


var windows = getAllVisibleWindows()

for window in windows:
  echo window.title

winAuto.onWindowOpened(proc (win: Window) = echo win.title)

discard getch()