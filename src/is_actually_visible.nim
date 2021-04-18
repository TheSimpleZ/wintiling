import winim/com


proc isCloaked(windowHandle: HWND): bool =
  # https://stackoverflow.com/questions/43927156/enumwindows-returns-closed-windows-store-applications
  var isCloaked: int
  let hResult = windowHandle.DwmGetWindowAttribute(DWMWA_CLOAKED, &isCloaked,
                                                  cast[DWORD](sizeof int))
  if hResult.FAILED:
    raise newException(OSError, "Could not get cloaked")

  result = isCloaked > 0

proc isAltTabWindow(windowHandle: HWND): bool =
  # https://devblogs.microsoft.com/oldnewthing/20071008-00/?p=24863
  var
    ancestor = GetAncestor(windowHandle, GA_ROOTOWNER)
    nextPopup: HWND

  while true:
    nextPopup = GetLastActivePopup(ancestor)
    if IsWindowVisible(nextPopup).bool or ancestor == nextPopup:
      break
    ancestor = nextPopup

  result = nextPopup == windowHandle

proc isTaskTrayProgram(windowHandle: HWND): bool =
  var titlebarInfo: TITLEBARINFO

  titlebarInfo.cbSize = cast[DWORD](sizeof titlebarInfo)
  GetTitleBarInfo(windowHandle, &titlebarInfo);
  result = titlebarInfo.rgstate[0] and STATE_SYSTEM_INVISIBLE

proc isToolWindow(windowHandle: HWND): bool =
  result = GetWindowLong(windowHandle, GWL_EXSTYLE) and WS_EX_TOOLWINDOW


proc isActuallyVisible*(windowHandle: HWND): bool =
  # https://stackoverflow.com/questions/7277366/why-does-enumwindows-return-more-windows-than-i-expected
  result = windowHandle.IsWindowVisible.bool and
     windowHandle.isAltTabWindow and
     not windowHandle.isCloaked and
     not windowHandle.isTaskTrayProgram and
     not windowHandle.isToolWindow
