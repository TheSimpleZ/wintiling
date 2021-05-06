import winim/com
import lib/win32/win_automation
import lib/win32/window
import lib/win32/keyboard
import std/exitprocs
import sequtils
import lib/layout
import strutils
import logging
import tables
import sets
import lib/treenode
import options
import lib/hotkeys as hkMacro
import config/hotkeys as hkConfig

var logger = newConsoleLogger(fmtStr="[$time] - $levelname: ")

addHandler(logger)
let winAuto = newWinAutomation()


var allOpenWindows = getAllVisibleWindows().filterIt(not it.title.contains("WinTiling"))

debug "Windows detected: ", $allOpenWindows.mapIt(it.title)

let (desktopWidth, desktopHeight) = getWorkAreaSize()

var topLevelLayout = newDesktop(
  Row,
  desktopWidth,
  desktopHeight
)

topLevelLayout.add allOpenWindows.map(toWindowLayout)

topLevelLayout.render()


proc windowStateChanged(newWindow: Window, eventType: WindowStateChangeEvent) =
  case eventType:
    of Opened:
      if newWindow.isVisible:
        debug("Windows opened: ", newWindow.title)
        let focusedWindowOpts = topLevelLayout.findFocusedWindow()

        let container = if focusedWindowOpts.isSome:
                          focusedWindowOpts.get().parent
                        else: topLevelLayout
        container.add newWindow.toWindowLayout
        render container
    of Closed:
      let invisibleWindows = topLevelLayout.findWindows(visible = false)
      for desktop in invisibleWindows:
        if desktop.isWindow:
          debug("Windows closed: ", desktop.value.window.originalTitle)
        desktop.dropDesktop()
      if invisibleWindows.len > 0:
        # echo invisibleWindows
        render topLevelLayout




winAuto.onWindowStateChanged(windowStateChanged)


# proc resetAllStyles() {.noconv.} =
#   topLevelLayout.walkIt:
#     if it.value.kind == LayoutKind.Window:
#       it.value.window.resetStyles()
#   quit()

# addExitProc(resetAllStyles)
# setControlCHook(resetAllStyles)


var keysPressed: HashSet[int]


proc onKeyStateChanged(key: int, eventType: KeyEvent): bool =
  case eventType:
    of KeyUp:
      keysPressed.excl(key)
    of KeyDown:
      keysPressed.incl(key)
      if keysPressed in hotkeys:
        let opts = topLevelLayout.findFocusedWindow()
        if opts.isSome():
          let win = opts.get()
          if hotkeys[keysPressed](topLevelLayout, win):
            topLevelLayout.render()
        return true

setGlobalKeyboardHook(onKeyStateChanged)
runMessageQueueForever()