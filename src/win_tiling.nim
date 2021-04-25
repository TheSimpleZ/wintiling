import winim/com
import win_automation
import window
import std/exitprocs
import sequtils
import layout
import sugar
import strutils
import logging
import tables
import sets
import tree

var logger = newConsoleLogger()
addHandler(logger)
let winAuto = newWinAutomation()


var windows = getAllVisibleWindows().filterIt(not it.title.contains("WinTiling"))

debug "Windows detected: ", $windows.mapIt(it.title)

# for win in windows:
#   win.isResizeable = false



let (desktopWidth, desktopHeight) = getWorkAreaSize()
let windowLayouts = collect(newSeq):
  for i, win in windows:
    newWindowLayout(win,i == 0)
var topLevelLayout = newContainerLayout(
  windowLayouts,
  Row,
  desktopWidth,
  desktopHeight
)

topLevelLayout.render()


proc windowStateChanged(newWindow: Window, eventType: WindowStateChangeEvent) =
  case eventType:
    of Opened:
      if newWindow.isVisible:
        debug("Windows opened: ", newWindow.title)
        # newWindow.isResizeable = false
        var focusedContainer = topLevelLayout.first do (layout: DesktopLayout)->bool:
           layout.value.kind == Container and isFocused(layout)

        focusedContainer.add(newWindow)
        # topLevelLayout.children = topLevelLayout.children & newWindowLayout(newWindow)
    of Closed:
      topLevelLayout.all do (layout: DesktopLayout)->bool:
        layout.children.keepItIf((it.value.kind == LayoutKind.Window and
                                  it.value.window.nativeHandle.IsWindow.bool) or
                                  it.value.kind == LayoutKind.Container
                                )
        result = true
  topLevelLayout.render()

winAuto.onWindowStateChanged(windowStateChanged)


proc resetAllStyles() {.noconv.} =
  for windowLayout in topLevelLayout.allWindows:
    let window = windowLayout.value.window
    echo window.title
    window.resetStyles()
  quit()

addExitProc(resetAllStyles)
setControlCHook(resetAllStyles)



const
  keys = {'A'..'Z'}.toSeq
  codes = {0x41..0x5A}.toSeq

  virtualCodes = block:
    var codeTable = initTable[char, int]()
    for pairs in zip(keys, codes):
      let (key, code) = pairs
      codeTable[key] = code
    codeTable

var keysPressed: OrderedSet[int]


proc HookCallback(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
    if nCode == HC_ACTION:
      var kbdstruct: PKBDLLHOOKSTRUCT = cast[ptr KBDLLHOOKSTRUCT](lparam)
      case wParam:
        of WM_KEYDOWN, WM_SYSKEYDOWN:
          # if byte(kbdstruct.vkCode) == VK_LWIN:
          keysPressed.incl(kbdstruct.vkCode)
          if keysPressed == [VK_LWIN, virtualCodes['E']].toOrderedSet:
            topLevelLayout.value.growDirection = if topLevelLayout.value.growDirection == Column:
                                            Row
                                           else: Column
            topLevelLayout.render()
            return 1

        of WM_KEYUP, WM_SYSKEYUP:
          keysPressed.excl(kbdstruct.vkCode)
        else: discard

    return CallNextHookEx(0, nCode, wParam, lParam)

SetWindowsHookEx(WH_KEYBOARD_LL, (HOOKPROC) HookCallback, 0,  0)
PostMessage(0, 0, 0, 0) # activating process message queue (without any window)
# But if we want to stop we need to terminate process in Task Manager!




var msg: MSG
while GetMessage(msg.addr, 0, 0, 0):
     if msg.message == WM_HOTKEY:
        info "Hotkey!"

echo "running"
# discard getch()
# while true:
#   discard
