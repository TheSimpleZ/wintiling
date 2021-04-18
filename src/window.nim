import winim/com

type Window* = object
  nativeHandle*: HWND

converter hwndToWindow*(windowHandle: HWND): Window =
  Window(nativeHandle: windowHandle)

proc title*(window: Window): string =
  let length = window.nativeHandle.GetWindowTextLength;
  var name = newWString(length + 1)
  window.nativeHandle.GetWindowText(name, length + 1)
  result = $name
