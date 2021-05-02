import winim/com
import strformat
import is_actually_visible
import keyboard

type Window* = object
  nativeHandle*: HWND
  originalStyle: LONG_PTR
  originalTitle*: string

template raiseOsError(msg: string) =
  raise newException(OSError, msg & ": " & GetLastError().toHex)

proc `==`*(a,b: Window): bool = a.nativeHandle == b.nativeHandle

proc `nativeStyle=`(self: Window, styleVar: LONG_PTR) =
  if self.nativeHandle.SetWindowLongPtr(GWL_STYLE, styleVar).FAILED:
    raiseOsError "Could not set style"
  if self.nativeHandle.SetWindowPos(nil, 0, 0, 0, 0, SWP_FRAMECHANGED or
                                      SWP_NOSIZE or SWP_NOZORDER or
                                      SWP_NOMOVE or SWP_NOOWNERZORDER).FAILED:
    raiseOsError "Could not set position"

proc nativeStyle(self: Window): LONG_PTR =
  self.nativeHandle.GetWindowLongPtr(GWL_STYLE)

proc title*(self: Window): string =
  let length = self.nativeHandle.GetWindowTextLength + 1
  var name = newWString(length)
  self.nativeHandle.GetWindowText(name, length)
  result = $name.nullTerminated

proc initWindow*(selfHandle: HWND): Window =
  result = Window(nativeHandle: selfHandle)
  result.originalStyle = result.nativeStyle
  result.originalTitle = result.title



proc resetStyles*(self: Window) =
  self.nativeStyle = self.originalStyle



# proc `isResizeable=`*(self: Window, value: bool) =
#   let style = self.nativeStyle
#   var newStyle = if value: style and WS_THICKFRAME
#                  else: style xor WS_THICKFRAME
#   self.nativeStyle = newStyle

# proc isResizeable*(self: Window): bool =
#   (self.nativeStyle and WS_THICKFRAME) > 0

proc isVisible*(self: Window): bool =
  self.nativeHandle.isActuallyVisible


proc setForegroundWindow*(self: Window) =
  sendKey(VK_RMENU)
  sendKey(VK_RMENU, KEYEVENTF_KEYUP)
  SetForegroundWindow(self.nativeHandle)

proc getForegroundWindow*(): Window =
  initWindow GetForegroundWindow()
