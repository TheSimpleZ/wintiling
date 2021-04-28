import winim/com
import libs/win32/win_automation
import libs/win32/window
import std/exitprocs
import sequtils
import libs/layout
import strutils
import logging
import tables
import sets
import libs/treenode
import options

var logger = newConsoleLogger()
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
      let invisibleWindows = topLevelLayout.findInvisibleWindows()
      for desktop in invisibleWindows:
        debug("Windows closed: ", desktop.value.window.originalTitle)
        desktop.dropDesktop()
      if invisibleWindows.len > 0:
        render topLevelLayout




winAuto.onWindowStateChanged(windowStateChanged)


proc resetAllStyles() {.noconv.} =
  topLevelLayout.walkIt:
    if it.value.kind == LayoutKind.Window:
      it.value.window.resetStyles()
  quit()

addExitProc(resetAllStyles)
setControlCHook(resetAllStyles)



const VirtualCodes = block:
    let
      keys = {'A'..'Z'}.toSeq
      codes = {0x41..0x5A}.toSeq

    var codeTable = initTable[char, int]()
    for pairs in zip(keys, codes):
      let (key, code) = pairs
      codeTable[key] = code

    codeTable



const hotkeys = {
  [VK_LWIN, VirtualCodes['E']].toOrderedSet: proc () =
    echo "hello"
    topLevelLayout.transpose(),
  [VK_LWIN, VK_LEFT].toOrderedSet: proc () = discard,
  [VK_LWIN, VK_RIGHT].toOrderedSet: proc () = discard
}.toTable

var keysPressed: OrderedSet[int]

proc HookCallback(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    if nCode == HC_ACTION:
      var kbdstruct: PKBDLLHOOKSTRUCT = cast[ptr KBDLLHOOKSTRUCT](lparam)
      case wParam:
        of WM_KEYDOWN, WM_SYSKEYDOWN:
          # if byte(kbdstruct.vkCode) == VK_LWIN:
          keysPressed.incl(kbdstruct.vkCode)
          if keysPressed in hotkeys:
            hotkeys[keysPressed]()
            topLevelLayout.render()
            return 1
          if keysPressed == [VK_LWIN, VK_LEFT].toOrderedSet or keysPressed == [VK_LWIN, VK_RIGHT].toOrderedSet:
            let activeWindow = getForegroundWindow()
            # This will be refactored. Moves focus left and right
            let allWindows = topLevelLayout.allIt(it.value.kind == LayoutKind.Window).mapIt(it.value.window)
            let currentFocus = allWindows.find(activeWindow)
            let newFocus = if VK_RIGHT in keysPressed: min(currentFocus+1, allWindows.len-1)
                          else: max(currentFocus-1, 0)
            let targetHwnd = allWindows[newFocus]

            targetHwnd.setForegroundWindow()

            return 1

        of WM_KEYUP, WM_SYSKEYUP:
          keysPressed.excl(kbdstruct.vkCode)
        else: discard

    return CallNextHookEx(0, nCode, wParam, lParam)

SetWindowsHookEx(WH_KEYBOARD_LL, (HOOKPROC) HookCallback, 0,  0)
PostMessage(0, 0, 0, 0) # activating process message queue (without any window)
# But if we want to stop we need to terminate process in Task Manager!



var msg: MSG
while GetMessage(msg.addr, 0, 0, 0): discard
