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
    DesktopLayout(
      kind: LayoutKind.Window,
      window: win,
      isFocused: i == 0
    )
let topLevelLayout = DesktopLayout(kind: Container,
                            children: windowLayouts,
                            growDirection: Row)

topLevelLayout.setDimensions(desktopWidth, desktopHeight, 0, 0)

topLevelLayout.render()

proc isFocusedContainer(it: DesktopLayout): bool =
  it.kind == Container and isFocused(it)


proc windowStateChanged(newWindow: Window, eventType: WindowStateChangeEvent) =
  case eventType:
    of Opened:
      if newWindow.isVisible:
        debug("Windows opened: ", newWindow.title)
        # newWindow.isResizeable = false
        topLevelLayout.walk(Container) do (layout: DesktopLayout)->bool:
          result = true
          if layout.isFocusedContainer:
            layout.children.add(DesktopLayout(
              kind: LayoutKind.Window,
              window: newWindow,
            ))
            result = false
    of Closed:
      topLevelLayout.walk(Container) do (layout: DesktopLayout)->bool:
        layout.children.keepItIf(it.kind == LayoutKind.Window and it.window.nativeHandle.IsWindow.bool)
        result = true
  topLevelLayout.setDimensions(desktopWidth, desktopHeight, 0, 0)
  topLevelLayout.render()

winAuto.onWindowStateChanged(windowStateChanged)


proc resetAllStyles() {.noconv.} =
  for windowLayout in topLevelLayout.allWindows:
    let window = windowLayout.window
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
            topLevelLayout.growDirection = if topLevelLayout.growDirection == Column:
                                            Row
                                           else: Column
            topLevelLayout.setDimensions(desktopWidth, desktopHeight, 0, 0)

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
