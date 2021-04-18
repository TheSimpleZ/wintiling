import winim/com
import ui_automation_event_handler
import is_actually_visible
import sequtils
import window

converter pointerConverter(x: ptr): ptr PVOID = cast[ptr PVOID](x)
converter UIA_HWNDToHWND*(x: UIA_HWND): HWND = cast[HWND](x)

type
  WinAutomation = ref object
    automation: ptr IUIAutomation
    desktop: ptr IUIAutomationElement


proc cleanup(wa: WinAutomation) =
  if wa.automation != nil:
    if wa.automation.RemoveAllEventHandlers.FAILED:
      raise newException(OSError, "Could not remove all event handlers")
    CoUninitialize()

proc newWinAutomation*(): WinAutomation =
  var wa: WinAutomation
  new wa, cleanup
  result = wa
  CoInitializeEx(nil, COINIT_MULTITHREADED)
  var hResult = CoCreateInstance(&CLSID_CUIAutomation,
                                 NULL, CLSCTX_INPROC_SERVER,
                                 &IID_IUIAutomation, &result.automation)

  if hResult.FAILED or result.isNil:
    raise newException(OSError, "Could not initialize automation lib")


  hResult = result.automation.GetRootElement(&result.desktop)
  if hResult.FAILED or result.desktop.isNil:
    raise newException(OSError, "Could not get root element")

proc enumerateVisibleWindows(windowHandle: HWND, lParam: LPARAM):
                            WINBOOL {.stdcall.} =
  var returnList = cast[ptr seq[HWND]](lParam)
  if isActuallyVisible(windowHandle):
    returnList[].add(windowHandle)

  return true

proc getAllVisibleWindows*(): seq[Window] =
  var openWindowHandles = newSeqOfCap[HWND](100)
  EnumWindows(enumerateVisibleWindows, cast[LPARAM](&openWindowHandles))
  result = openWindowHandles.mapIt(Window(nativeHandle: it))

template onWindowOpened*(wa: WinAutomation, handler: proc(newWindow: Window)) =
  proc handlerWrapper(self: ptr IUIAutomationEventHandler,
                         sender: ptr IUIAutomationElement,
                         eventId: EVENTID): HRESULT {.stdcall.} =
    var handle: UIA_HWND
    sender.get_CurrentNativeWindowHandle(&handle)
    if isActuallyVisible(handle):
      handler(Window(nativeHandle: handle))
    return S_OK

  var eventHandler = newUiAutomationEventHandler(handlerWrapper)
  if wa.automation.AddAutomationEventHandler(
      UIA_Window_WindowOpenedEventId,
      wa.desktop,
      TreeScope_Subtree,
      NULL,
      toIUIAutomationEventHandler(eventHandler)
    ).FAILED: raise
