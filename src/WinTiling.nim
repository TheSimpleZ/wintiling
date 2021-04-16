import winim/com
import rdstdin

type
  EventHandler {.pure.} = object
    lpVtbl: ptr IUIAutomationEventHandlerVtbl
    vtbl: IUIAutomationEventHandlerVtbl
    refCount: LONG


converter pointerConverter(x: ptr): ptr PVOID = cast[ptr PVOID](x)
converter EventHandlerToIUIAutomationEventHandler(x: ptr EventHandler): ptr IUIAutomationEventHandler = cast[ptr IUIAutomationEventHandler](x)


proc newEventHandler(): ptr EventHandler =
  result = cast[ptr EventHandler](alloc0(sizeof(EventHandler)))
  if result == nil: return

  result.lpVtbl = &result.vtbl
  result.refCount = 1

  result.vtbl.AddRef = proc(self: ptr IUnknown): ULONG {.stdcall.} =
    let obj = cast[ptr EventHandler](self)
    discard InterlockedIncrement(&obj.refCount)
    echo "add", obj.refCount
    return obj.refCount

  result.vtbl.Release = proc(self: ptr IUnknown): ULONG {.stdcall.} =
    let obj = cast[ptr EventHandler](self)
    discard InterlockedDecrement(&obj.refCount)
    echo "rel", obj.refCount
    if obj.refCount == 0:
      dealloc(obj)
      return 0

    return obj.refCount

  result.vtbl.HandleAutomationEvent = proc(self: ptr IUIAutomationEventHandler,
    sender: ptr IUIAutomationElement, eventId: EVENTID): HRESULT {.stdcall.} =
    var name: BSTR
    sender.get_CurrentName(&name)
    echo name

    return S_OK

  result.vtbl.QueryInterface = proc(self: ptr IUnknown, riid: REFIID, ppvObject: ptr pointer): HRESULT {.stdcall.} =
    if IsEqualIID(riid, &IID_IUnknown) or IsEqualIID(riid, &IID_IUIAutomationEventHandler):
      ppvObject[] = cast[ptr IUIAutomationEventHandler](self)
    else:
      ppvObject[] = nil
      return E_NOINTERFACE

    self.AddRef()
    return S_OK


try:
  CoInitializeEx(nil, COINIT_MULTITHREADED)
  var handler = newEventHandler()

  var
    uia: ptr IUIAutomation
    desktop: ptr IUIAutomationElement
    ret: HRESULT

  ret = CoCreateInstance(&CLSID_CUIAutomation, NULL, CLSCTX_INPROC_SERVER,
      &IID_IUIAutomation, &uia)
  if ret != S_OK or uia.isNil: raise


  ret = uia.GetRootElement(&desktop)
  if ret != S_OK or desktop.isNil: raise

  ret = uia.AddAutomationEventHandler(
      UIA_Window_WindowOpenedEventId,
      desktop,
      TreeScope_Subtree,
      NULL,
      handler
    )
  if ret != S_OK: raise



except:
  echo "something wrong !"

finally:
  echo readLineFromStdin("Press enter to exit...")
  CoUninitialize()
