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
import treenode
import options

var logger = newConsoleLogger()
addHandler(logger)
let winAuto = newWinAutomation()


var windows = getAllVisibleWindows().filterIt(not it.title.contains("WinTiling"))

debug "Windows detected: ", $windows.mapIt(it.title)

# for win in windows:
#   win.isResizeable = false



let (desktopWidth, desktopHeight) = getWorkAreaSize()

var topLevelLayout = newDesktop(
  Row,
  desktopWidth,
  desktopHeight
)

topLevelLayout.add windows.map(toWindowLayout)

topLevelLayout.walkIt:
  if it.value.kind == LayoutKind.Window:
    SetForegroundWindow(it.value.window.nativeHandle)
    it.value.isFocused = true
    return true

topLevelLayout.render()


proc windowStateChanged(newWindow: Window, eventType: WindowStateChangeEvent) =
  case eventType:
    of Opened:
      if newWindow.isVisible:
        debug("Windows opened: ", newWindow.title)
        # newWindow.isResizeable = false
        let containerOpt = topLevelLayout.firstIt:
          it.value.kind == Container and isFocused(it)
        if containerOpt.isSome:
          let container = containerOpt.get()
          topLevelLayout.walkIt:
            if it.value.kind == LayoutKind.Window and isFocused(it):
              it.value.isFocused = false
          let newNode = container.add toWindowLayout newWindow
          if newNode.value.kind == LayoutKind.Window:
            newNode.value.isFocused = true
          render container

    of Closed:
      let nodeOpts = topLevelLayout.firstIt:
        it.value.kind == LayoutKind.Window and
        not it.value.window.nativeHandle.IsWindow.bool
      if nodeOpts.isSome:
        let node = nodeOpts.get()
        node.dropDesktop()
        if not node.isRootNode:
          render node.parent





winAuto.onWindowStateChanged(windowStateChanged)


proc resetAllStyles() {.noconv.} =
  for windowLayout in topLevelLayout.allIt(it.value.kind == LayoutKind.Window):
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
          if keysPressed == [VK_LWIN, VK_LEFT].toOrderedSet:
            let containerOpt = topLevelLayout.firstIt:
              it.value.kind == Container and isFocused(it)
            if containerOpt.isSome:
              let container = containerOpt.get()
              


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
