import winim/com

# Ported from:
# https://docs.microsoft.com/en-us/windows/win32/winauto/uiauto-howto-implement-event-handlers

type
  UIAutomationEventHandlerVtbl = ref object of IUIAutomationEventHandlerVtbl
  UiAutomationEventHandler {.pure.} = object
    lpVtbl: ptr IUIAutomationEventHandlerVtbl
    vtbl: IUIAutomationEventHandlerVtbl
    refCount: LONG

  AutomationEventHandler* = proc(self: ptr IUIAutomationEventHandler,
                         sender: ptr IUIAutomationElement,
                         eventId: EVENTID): HRESULT {.stdcall.}

converter toIUIAutomationEventHandler*(x: ptr UiAutomationEventHandler):
                                      ptr IUIAutomationEventHandler =
  cast[ptr IUIAutomationEventHandler](x)

converter toEventHandler(x: ptr IUnknown):
                                    ptr UiAutomationEventHandler =
  cast[ptr UiAutomationEventHandler](x)

proc addRef(self: ptr IUnknown): ULONG {.stdcall.} =
  let obj = toEventHandler self
  result = InterlockedIncrement(&obj.refCount)

proc release(self: ptr IUnknown): ULONG {.stdcall.} =
  let obj = toEventHandler self
  result = InterlockedDecrement(&obj.refCount)
  if result == 0:
    dealloc(obj)

proc queryInterface(self: ptr IUnknown, riid: REFIID, ppvObject: ptr pointer):
                    HRESULT {.stdcall.} =
    if IsEqualIID(riid, &IID_IUnknown) or
       IsEqualIID(riid, &IID_IUIAutomationEventHandler)
    :
      ppvObject[] = toEventHandler self
    else:
      ppvObject[] = nil
      return E_NOINTERFACE

    self.AddRef()
    return S_OK

proc newUiAutomationEventHandler*(handler: AutomationEventHandler):
                                  ptr UiAutomationEventHandler =
  result = create UiAutomationEventHandler

  result.lpVtbl = &result.vtbl
  result.refCount = 1

  result.vtbl.AddRef = addRef

  result.vtbl.Release = release

  result.vtbl.HandleAutomationEvent = handler

  result.vtbl.QueryInterface = queryInterface