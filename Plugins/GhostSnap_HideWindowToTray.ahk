#NoTrayIcon ;~不显示托盘图标
#SingleInstance Off

global 参数1 := A_Args[1]
;═══════════════════════════════════════════════════════════════════════════════════════════
;https://www.autohotkey.com/boards/viewtopic.php?t=93964
DetectHiddenWindows, On
global EVENT_SYSTEM_MINIMIZESTART := 0x0016
    , EVENT_SYSTEM_MINIMIZEEND   := 0x0017
    , EVENT_OBJECT_DESTROY       := 0x8001
    , Windows := []

MinimizeHook := new WinEventHook(EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND, "HookProc")
DestroyHook  := new WinEventHook(EVENT_OBJECT_DESTROY      , EVENT_OBJECT_DESTROY    , "HookProc")
OnMessage(0x404, "AHK_NOTIFYICON")
OnExit("ShowHidden")
AddToListAndMinimize()
Return

AddToListAndMinimize() {
    hWnd := WinExist(参数1)

    if !(hWnd)
        ExitApp
    SetTitleMatchMode, RegEx
    if WinActive("ahk_class ^(Progman|WorkerW|Shell_TrayWnd)$")
        ExitApp
    if !Windows.HasKey(hWnd) {
        WinGetTitle, title
        Windows[hwnd] := {title: title, hIcon: GetWindowIcon(hWnd)}
    }
    WinMinimize
}

ShowHidden() {
    for hwnd, v in Windows {
        if !DllCall("IsWindowVisible", "Ptr", hwnd){
            WinShow, ahk_id %hwnd%
            WinActivate, ahk_id %hwnd%
        }
        if WinExist("ahk_id" . v.gui)
            RemoveTrayIcon(v.gui)
    }
}

GetWindowIcon(hWnd) {
    static WM_GETICON := 0x007F, ICON_SMALL := 0, GCLP_HICONSM := -34
        , GetClassLong := "GetClassLong" . (A_PtrSize = 4 ? "" : "Ptr")
    SendMessage, WM_GETICON, ICON_SMALL, A_ScreenDPI,, ahk_id %hWnd%
    if !smallIcon := ErrorLevel
        smallIcon := DllCall(GetClassLong, "Ptr", hWnd, "Int", GCLP_HICONSM, "Ptr")
    Return smallIcon
}

AddTrayIcon(hIcon, tip := "")
{
    static NIF_MESSAGE := 1, NIF_ICON := 2, NIF_TIP := 4, NIM_ADD := 0
    flags := NIF_MESSAGE|NIF_ICON|(tip = "" ? 0 : NIF_TIP)
    VarSetCapacity(NOTIFYICONDATA, size := A_PtrSize = 8 ? 848 : A_IsUnicode? 828 : 444, 0)
    Gui, New, +hwndhGui
    NumPut(size         , NOTIFYICONDATA)
    NumPut(hGui         , NOTIFYICONDATA, A_PtrSize)
    NumPut(uID  := 0x404, NOTIFYICONDATA, A_PtrSize*2)
    NumPut(flags        , NOTIFYICONDATA, A_PtrSize*2 + 4)
    NumPut(nMsg := 0x404, NOTIFYICONDATA, A_PtrSize*2 + 8)
    NumPut(hIcon        , NOTIFYICONDATA, A_PtrSize*3 + 8)
    if (tip != "")
        StrPut(tip, &NOTIFYICONDATA + 4*A_PtrSize + 8, "CP0")
    DllCall("shell32\Shell_NotifyIcon", "UInt", NIM_ADD, "Ptr", &NOTIFYICONDATA)
    Return hGui
}

RemoveTrayIcon(hWnd, uID := 0x404)
{
    VarSetCapacity(NOTIFYICONDATA, size := A_PtrSize = 8 ? 848 : A_IsUnicode? 828 : 444, 0)
    NumPut(size, NOTIFYICONDATA)
    NumPut(hWnd, NOTIFYICONDATA, A_PtrSize)
    NumPut(uID , NOTIFYICONDATA, A_PtrSize*2)
    DllCall("shell32\Shell_NotifyIcon", "UInt", NIM_DELETE := 2, "Ptr", &NOTIFYICONDATA)
    Return
}

AHK_NOTIFYICON(wp, lp, msg, hwnd)   ; wp — uID, lp — Message
{
    static WM_LBUTTONDOWN := 0x201, WM_RBUTTONUP := 0x205, maxLenMenuStr := 40
    if !(lp = WM_LBUTTONDOWN || lp = WM_RBUTTONUP)
        Return

    for k, v in Windows
        if (v.gui = hwnd && window := k)
            break
    if !window
        Return

    Switch lp {
    Case WM_LBUTTONDOWN:
        RemoveTrayIcon(hwnd)
        Gui, %hwnd%: Destroy
        WinShow, ahk_id %window%
        WinActivate, ahk_id %window%
        ExitApp
    Case WM_RBUTTONUP:
        title := Windows[window, "title"]
        b := StrLen(title) > maxLenMenuStr
        menuText := "恢复 «" . SubStr(title, 1, maxLenMenuStr) . (b ? "..." : "") . "»"
        fn := Func(A_ThisFunc).Bind(0x404, WM_LBUTTONDOWN, 0x404, hwnd)

        Menu, IconMenu, Add, 左击托盘图标恢复,Terminate
        Menu, IconMenu, Disable, 左击托盘图标恢复
        Menu, IconMenu, Add , % menuText, % fn
        Menu, IconMenu, Icon, % menuText, % "HICON:*" . Windows[window, "hIcon"]
        ;Menu, IconMenu, Add , Terminate script and show all windows, Terminate
        ;Menu, IconMenu, Add , 关闭窗口(&X), 隐藏到托盘退出
        ;Menu, IconMenu, Icon, 关闭窗口(&X), shell32.dll, 28
        Menu, IconMenu, Show
        Menu, IconMenu, DeleteAll
    }
}

HookProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    static OBJID_WINDOW := 0
    if !( idObject = OBJID_WINDOW && Windows.HasKey(hwnd) )
        Return
    Switch event {
    Case EVENT_SYSTEM_MINIMIZESTART:
        WinHide, ahk_id %hWnd%
        Windows[hwnd, "gui"] := AddTrayIcon(Windows[hwnd, "hIcon"], Windows[hwnd, "title"])
    Case EVENT_OBJECT_DESTROY, EVENT_SYSTEM_MINIMIZEEND:
        iconGui := Windows[hwnd, "gui"]
        if WinExist("ahk_id" . iconGui)
            RemoveTrayIcon(iconGui)
        try Gui, %iconGui%: Destroy
      ( event = EVENT_OBJECT_DESTROY && Windows.Delete(hwnd) )
   }
}

class WinEventHook
{  ; Event Constants: https://is.gd/tRT5Wr
   __New(eventMin, eventMax, hookProc, eventInfo := 0, idProcess := 0, idThread := 0, dwFlags := 0) {
      this.pCallback := RegisterCallback(hookProc, "F",, eventInfo)
      this.hHook := DllCall("SetWinEventHook", "UInt", eventMin, "UInt", eventMax, "Ptr", 0, "Ptr", this.pCallback
                                             , "UInt", idProcess, "UInt", idThread, "UInt", dwFlags, "Ptr")
   }
   __Delete() {
      DllCall("UnhookWinEvent", "Ptr", this.hHook)
      DllCall("GlobalFree", "Ptr", this.pCallback, "Ptr")
   }
}

Terminate() {
    ExitApp
}
