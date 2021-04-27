import winim/com
import strformat
import is_actually_visible

type Window* = object
  nativeHandle*: HWND
  originalStyle: LONG_PTR

template raiseOsError(msg: string) =
  raise newException(OSError, msg & ": " & GetLastError().toHex)


proc `nativeStyle=`(self: Window, styleVar: LONG_PTR) =
  if self.nativeHandle.SetWindowLongPtr(GWL_STYLE, styleVar).FAILED:
    raiseOsError "Could not set style"
  if self.nativeHandle.SetWindowPos(nil, 0, 0, 0, 0, SWP_FRAMECHANGED or
                                      SWP_NOSIZE or SWP_NOZORDER or
                                      SWP_NOMOVE or SWP_NOOWNERZORDER).FAILED:
    raiseOsError "Could not set position"

proc nativeStyle(self: Window): LONG_PTR =
  self.nativeHandle.GetWindowLongPtr(GWL_STYLE)

proc initWindow*(selfHandle: HWND): Window =
  let style = selfHandle.GetWindowLongPtr(GWL_STYLE)
  Window(nativeHandle: selfHandle, originalStyle: style)

proc resetStyles*(self: Window) =
  self.nativeStyle = self.originalStyle

proc title*(self: Window): string =
  let length = self.nativeHandle.GetWindowTextLength + 1
  var name = newWString(length)
  self.nativeHandle.GetWindowText(name, length)
  result = $name.nullTerminated

proc `isResizeable=`*(self: Window, value: bool) =
  let style = self.nativeStyle
  var newStyle = if value: style and WS_THICKFRAME
                 else: style xor WS_THICKFRAME
  self.nativeStyle = newStyle

proc isResizeable*(self: Window): bool =
  (self.nativeStyle and WS_THICKFRAME) > 0

proc isVisible*(self: Window): bool =
  self.nativeHandle.isActuallyVisible

proc initKeyboardInput(virtualKeyCode: uint16, flags: int32 = 0): INPUT =
  result.`type` = INPUT_KEYBOARD
  result.ki.wVk = virtualKeyCode
  result.ki.dwFlags = flags


proc send(self: INPUT) =
  SendInput(UINT 1, cast[LPINPUT](&self), int32 sizeof INPUT)

proc sendKey(virtualKeyCode: uint16, flags: int32 = 0) =
  var altDown = initKeyboardInput(VK_MENU, flags)
  altDown.send()

proc setForegroundWindow*(self: Window) =
  sendKey(VK_MENU)
  sendKey(VK_MENU, KEYEVENTF_KEYUP)
  SetForegroundWindow(self.nativeHandle)
