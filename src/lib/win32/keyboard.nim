import winim/com
import sugar
import sequtils
import tables

type
  KeyEvent* = enum
    KeyUp, KeyDown

const VirtualCodes* = block:
    let
      keys = {'0'..'9', 'A'..'Z'}.toSeq
      codes =  {0x30..0x39, 0x41..0x5A}.toSeq

    var codeTable = initTable[char, int]()
    for pairs in zip(keys, codes):
      let (key, code) = pairs
      codeTable[key] = code

    codeTable

const keyEvents = [WM_KEYDOWN, WM_SYSKEYDOWN, WM_KEYUP, WM_SYSKEYUP]
# const specialKeys = [VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN, VK_RCONTROL, VK_RMENU, VK_LWIN, VK_RWIN, VK_APPS, VK_PRIOR, VK_NEXT, VK_END, VK_HOME, VK_INSERT, VK_DELETE, VK_DIVIDE, VK_NUMLOCK]

# proc keyName(virtualKeycode: DWORD, scanCode: DWORD): string =
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
        let isNotInjectedKey = (kbdstruct.flags and LLKHF_INJECTED) == 0
        if isNotInjectedKey and wParam.int in keyEvents:
          let keyEvent = if wParam.int in [WM_KEYDOWN, WM_SYSKEYDOWN]: KeyDown
                         else: KeyUp
          # debug "Key code: 0x", kbdstruct.vkCode.toHex(2), " name: ", keyName(kbdstruct.vkCode, kbdstruct.scanCode)

          if eventHandler(kbdstruct.vkCode, keyEvent):
            return 1

      return CallNextHookEx(0, nCode, wParam, lParam)

  SetWindowsHookEx(WH_KEYBOARD_LL, (HOOKPROC) HookCallback, 0,  0)

proc initKeyboardInput(virtualKeyCode: uint16, flags: int32 = 0): INPUT =
  result.`type` = INPUT_KEYBOARD
  result.ki.wVk = virtualKeyCode
  result.ki.dwFlags = flags


proc send(self: INPUT) =
  SendInput(UINT 1, cast[LPINPUT](&self), int32 sizeof INPUT)

proc sendKey*(virtualKeyCode: int, flags: int32 = 0) =
  send initKeyboardInput(uint16 virtualKeyCode, flags)


proc runMessageQueueForever*() =
  var msg: MSG
  while GetMessage(msg.addr, 0, 0, 0):
    TranslateMessage(&msg)
    DispatchMessage(&msg)
