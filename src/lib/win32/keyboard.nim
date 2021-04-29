import winim/com
import sugar
import sequtils
import tables

type
  KeyEvent* = enum
    KeyUp, KeyDown

const VirtualCodes* = block:
    let
      keys = {'A'..'Z'}.toSeq
      codes = {0x41..0x5A}.toSeq

    var codeTable = initTable[char, int]()
    for pairs in zip(keys, codes):
      let (key, code) = pairs
      codeTable[key] = code

    codeTable

const specialKeys = [VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN, VK_RCONTROL, VK_RMENU, VK_LWIN, VK_RWIN, VK_APPS, VK_PRIOR, VK_NEXT, VK_END, VK_HOME, VK_INSERT, VK_DELETE, VK_DIVIDE, VK_NUMLOCK]

# proc keyName(virtualKeycode: int, scanCode: clong): string =
#   var sc = scanCode
#   var keyname = newWString(256)
#   if virtualKeycode in specialKeys:
#     sc = scanCode or KF_EXTENDED
#   GetKeyNameText(sc shl 16, keyname, cint keyname.len)
#   $keyname

template setGlobalKeyboardHook*(eventHandler: (key: int, eventType: KeyEvent)->bool) =
  proc HookCallback(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
      if nCode == HC_ACTION:
        var kbdstruct: PKBDLLHOOKSTRUCT = cast[ptr KBDLLHOOKSTRUCT](lparam)
        case wParam:
          of WM_KEYDOWN, WM_SYSKEYDOWN:
            # debug "Key code: 0x", kbdstruct.vkCode.toHex(2)
            if eventHandler(kbdstruct.vkCode, KeyDown):
              return 1
          of WM_KEYUP, WM_SYSKEYUP:
            if eventHandler(kbdstruct.vkCode, KeyUp):
              return 1
          else: discard

      return CallNextHookEx(0, nCode, wParam, lParam)

  SetWindowsHookEx(WH_KEYBOARD_LL, (HOOKPROC) HookCallback, 0,  0)


proc runMessageQueueForever*() =
  var msg: MSG
  while GetMessage(msg.addr, 0, 0, 0):
    TranslateMessage(&msg)
    DispatchMessage(&msg)
