; 编译exe文件信息及版本号设置
global 当前工具版本:="1.2.0"                                                 ;设置版本号
;@Ahk2Exe-Obey U_bits, = "%A_PtrSize%>4" ? "-64bit" : "-32bit"       ;判断位数
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%       ;读取版本号以编译
;@Ahk2Exe-SetMainIcon GhostSnap图标.ico                              ;指定托盘图标文件
;@Ahk2Exe-AddResource GhostSnap图标.ico, 160                         ;替换自带的'蓝色H'图标
;@Ahk2Exe-AddResource GhostSnap图标.ico, 206                         ;替换为 '绿色 S'
;@Ahk2Exe-AddResource GhostSnap图标.ico, 207                         ;替换自带的'红色H'图标
;@Ahk2Exe-AddResource GhostSnap图标.ico, 208                         ;替换为 '红色 S'
;@Ahk2Exe-ExeName %A_ScriptDir%\GhostSnap%U_version%.exe             ;打包后的exe文件路径
;@Ahk2Exe-SetCompanyName 逍遥xiaoyao                                 ;企业信息
;@Ahk2Exe-SetCopyright 逍遥xiaoyao                                   ;版权信息
;@Ahk2Exe-SetDescription 把窗口拖拽变成磁铁吸附，靠近边缘自动对齐       ;文件说明
;@Ahk2Exe-SetFileVersion %U_version%                                 ;文件版本
;@Ahk2Exe-SetInternalName GhostSnap                                  ;文件内部名
;@Ahk2Exe-SetLanguage 0x0804                                         ;区域语言
;@Ahk2Exe-SetName GhostSnap                                          ;名称
;@Ahk2Exe-SetProductName GhostSnap                                   ;产品名称
;@Ahk2Exe-SetOrigFilename GhostSnap.exe                              ;原始文件名称
;@Ahk2Exe-SetProductVersion %U_version%                              ;产品版本号
;@Ahk2Exe-SetVersion %U_version%                                     ;版本号

#NoEnv
#SingleInstance Force
#Include %A_ScriptDir%\Plugins\Lib\Gdip_All.ahk
#Persistent
SetBatchLines, -1
SetWinDelay, -1
CoordMode, Mouse, Screen

; ====================================================
; ======== 跨版本单例与优雅关闭旧进程 ========
; ====================================================
DetectHiddenWindows, On
; 查找是否有固定名称为 "GhostSnap_Main_Instance" 的旧版隐藏主窗口
oldInstance := WinExist("GhostSnap_Main_Instance ahk_class AutoHotkey")
if (oldInstance && oldInstance != A_ScriptHwnd) {
    WinClose, ahk_id %oldInstance%
    WinWaitClose, ahk_id %oldInstance%, , 3                    ;给旧版 3 秒时间执行 OnExit(Cleanup) 释放钩子和恢复窗口
}
; 将当前新版本的主窗口重命名为固定名称，供未来的新版本识别
WinSetTitle, ahk_id %A_ScriptHwnd%, , GhostSnap_Main_Instance
DetectHiddenWindows, Off
; ====================================================

; 设置标题匹配模式为 2 (包含匹配)，方便黑名单模糊写标题
SetTitleMatchMode, 2

; ==========================================
; 用户配置区
; ==========================================
global SettingsDir := A_ScriptDir "\GhostSnap.ini"                                                           ;配置文件路径

global SnapDistance := Var_Read("SnapDistance","20","基础配置",SettingsDir,"否")                              ;触发吸附的距离（像素）
global BreakoutDistance := Var_Read("BreakoutDistance","30","基础配置",SettingsDir,"否")                      ;挣脱距离(阻尼感)

global StrictSingleAxisSnap := Var_Read("StrictSingleAxisSnap","0","基础配置",SettingsDir,"否")               ;默认吸附模式
global EnableGhostWindow := Var_Read("EnableGhostWindow","1","基础配置",SettingsDir,"否")                     ;启用幽灵窗口特效
global EnableScreenEdgeSnap := Var_Read("EnableScreenEdgeSnap","1","基础配置",SettingsDir,"否")               ;屏幕边缘吸附
global EnableSmartSync := Var_Read("EnableSmartSync","1","基础配置",SettingsDir,"否")                         ;智能尺寸同步
global SmartSyncKey := Var_Read("SmartSyncKey","Alt","基础配置",SettingsDir,"否")                             ;触发智能尺寸同步的按键

global EnableChaining := Var_Read("EnableChaining","1","基础配置",SettingsDir,"否")                           ;窗口联动移动
global GhostColor := Var_Read("GhostColor","0078D7","基础配置",SettingsDir,"否")                              ;幽灵窗口颜色
global GhostOpacity := Var_Read("GhostOpacity","80","基础配置",SettingsDir,"否")                              ;幽灵窗口透明度

global EnableSnapAnimation := Var_Read("EnableSnapAnimation","1","基础配置",SettingsDir,"否")                 ;是否启用吸附动画
global SnapAnimSteps := Var_Read("SnapAnimSteps","4","基础配置",SettingsDir,"否")                             ;动画过渡帧数
global SnapAnimSleep := Var_Read("SnapAnimSleep","10","基础配置",SettingsDir,"否")                            ;动画每帧延迟(毫秒)

global SnapToggleKey := Var_Read("SnapToggleKey","Shift","基础配置",SettingsDir,"否")                         ;临时停止/触发吸附的按键
global RequireKeyToSnap := Var_Read("RequireKeyToSnap","0","基础配置",SettingsDir,"否")                       ;反向吸附

global DragModKey := Var_Read("DragModKey","LWin","基础配置",SettingsDir,"否","否")                           ;任意位置拖拽修饰键
global ResizeModKey := Var_Read("ResizeModKey","Rwin","基础配置",SettingsDir,"否","否")                       ;任意位置调整大小修饰键
global MaxRestoreCount := Var_Read("MaxRestoreCount", "10", "基础配置", SettingsDir, "否")                    ;还原列表最大记录数 (默认10，防菜单过长)

global CurrentResizeModKey := ResizeModKey

global DragDirectKey := Var_Read("DragDirectKey","XButton1","基础配置",SettingsDir,"否","否")                 ;任意位置拖拽直接键
global ChainModKey := Var_Read("ChainModKey","Ctrl","基础配置",SettingsDir,"否")                              ;触发联动的修饰键

defaultBlacklist := "FloatingBall悬浮球 ahk_class AutoHotkeyGUI`nahk_exe PixPin.exe`nahk_exe Snipaste.exe`nahk_class Progman`nahk_class WorkerW`nahk_class Shell_TrayWnd`nahk_class TopLevelWindowForOverflow`nahk_class Shell_SecondaryTrayWnd"
global Blacklist := Var_Read("Blacklist", defaultBlacklist, "基础配置", SettingsDir, "否", "是")              ;窗口黑名单
global DragModBlacklist := Var_Read("DragModBlacklist", "", "基础配置", SettingsDir, "否", "是")              ;修饰键拖拽黑名单
global DragDirectBlacklist := Var_Read("DragDirectBlacklist", "", "基础配置", SettingsDir, "否", "是")        ;直接键拖拽黑名单

; --- 新增：支持最大化、菜单热键与黑名单 ---
global AllowMaximizedWin := Var_Read("AllowMaximizedWin","0","基础配置",SettingsDir,"否") ; 是否支持拖拽/缩放最大化窗口
global MenuHotkey := Var_Read("MenuHotkey","#m","基础配置",SettingsDir,"否")              ; 呼出菜单热键
global CurrentMenuHotkey := MenuHotkey                                                    ; 用于动态解绑旧热键
global MenuHotkeyBlacklist := Var_Read("MenuHotkeyBlacklist", "", "基础配置", SettingsDir, "否", "是") ; 菜单及动作热键黑名单

global MenuStyle := Var_Read("MenuStyle","2","基础配置",SettingsDir,"否") ; 1=原生菜单, 2=GDI+自绘菜单
global GdipMenuData := {}       ; 存储 GDI+ 菜单的数据树
global ActiveGdipMenus := []    ; 记录当前展开的自绘菜单句柄与信息

global AdminLaunch := Var_Read("AdminLaunch","0","基础配置",SettingsDir,"否")                                 ;是否管理员运行
global AutoRun := Var_Read("AutoRun","0","基础配置",SettingsDir,"否")                                         ;是否开机自启
global ShowTrayIcon := Var_Read("ShowTrayIcon","1","基础配置",SettingsDir,"否")                               ;是否显示托盘图标

; --- 贴边隐藏配置 ---
global AutoHideModKey := Var_Read("AutoHideModKey","CapsLock","贴边隐藏",SettingsDir,"否","否")               ;触发按键
global AutoHideDistance := Var_Read("AutoHideDistance","20","贴边隐藏",SettingsDir,"否")                      ;独立触发贴边距离 (默认20)
global AutoHideProtrude := Var_Read("AutoHideProtrude","8","贴边隐藏",SettingsDir,"否")                       ;边缘凸出长度
global AutoHideShowDelay := Var_Read("AutoHideShowDelay","150","贴边隐藏",SettingsDir,"否")                   ;悬停显示延迟
global AutoHideHideDelay := Var_Read("AutoHideHideDelay","350","贴边隐藏",SettingsDir,"否")                   ;移出隐藏延迟
global AutoHideTolerance := Var_Read("AutoHideTolerance","5","贴边隐藏",SettingsDir,"否")                     ;移出判定容差
global AutoHideEdgePriority := Var_Read("AutoHideEdgePriority","0","贴边隐藏",SettingsDir,"否")               ;优先级: 0=上下, 1=左右, 2=距离优先
global AutoHideTopmost := Var_Read("AutoHideTopmost","0","贴边隐藏",SettingsDir,"否")                         ;是否置顶
global AutoHideFocus := Var_Read("AutoHideFocus","1","贴边隐藏",SettingsDir,"否")                             ;呼出时是否获取焦点
global AutoHideFullscreenHide := Var_Read("AutoHideFullscreenHide","1","贴边隐藏",SettingsDir,"否")           ;全屏时是否完全隐藏凸出部分

; 独立动画配置
global EnableAutoHideAnim := Var_Read("EnableAutoHideAnim","1","贴边隐藏",SettingsDir,"否")                   ;是否启用贴边隐藏动画
global AutoHideAnimSteps := Var_Read("AutoHideAnimSteps","5","贴边隐藏",SettingsDir,"否")                     ;贴边隐藏动画过渡帧数
global AutoHideAnimSleep := Var_Read("AutoHideAnimSleep","8","贴边隐藏",SettingsDir,"否")                     ;贴边隐藏动画每帧延迟
global HiddenWindows := {}                                                                                   ;用于存储正在贴边隐藏的窗口信息字典
global wasHiddenHwnd := 0                                                                                    ;用于存储被拖拽出的贴边隐藏窗口ID

; --- 自绘菜单配置 ---
global MenuGdipTheme := Var_Read("MenuGdipTheme","Light","自绘菜单",SettingsDir,"否")                         ; 1. 主题 (Light/Dark)
global MenuGdipHoverHighlight := Var_Read("MenuGdipHoverHighlight","1","自绘菜单",SettingsDir,"否")           ; 2. 悬停高亮 (1=开, 0=关)
global MenuGdipShowIcon := Var_Read("MenuGdipShowIcon","1","自绘菜单",SettingsDir,"否")                       ; 3. 显示图标
global MenuGdipIconSize := Var_Read("MenuGdipIconSize","16","自绘菜单",SettingsDir,"否")                      ; 4. 图标尺寸
global MenuGdipShowTooltip := Var_Read("MenuGdipShowTooltip","1","自绘菜单",SettingsDir,"否")                 ; 5. 悬停信息提示
global MenuGdipFontName := Var_Read("MenuGdipFontName","Microsoft YaHei","自绘菜单",SettingsDir,"否")         ; 6. 字体名称
global MenuGdipFontSize := Var_Read("MenuGdipFontSize","12","自绘菜单",SettingsDir,"否")                      ; 7. 字体大小
global MenuGdipLineSpacing := Var_Read("MenuGdipLineSpacing","22","自绘菜单",SettingsDir,"否")                ; 8. 行距
global MenuGdipMaxWidth := Var_Read("MenuGdipMaxWidth","240","自绘菜单",SettingsDir,"否")                     ; 9. 菜单最大宽度
global MenuGdipMinWidth := Var_Read("MenuGdipMinWidth","150","自绘菜单",SettingsDir,"否")          ; 10. 菜单最小宽度

; --- 管理员启动 ---
if (!A_IsAdmin && AdminLaunch="1")
{
    try
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }catch{
        MsgBox, 1,, 以【管理员权限】启动失败！将以普通权限启动，管理员应用窗口将失效！
        IfMsgBox OK
        {
            if A_IsCompiled
                Run "%A_ScriptFullPath%" /restart
            else
                Run "%A_AhkPath%" /restart "%A_ScriptFullPath%"
        }
    }
    ExitApp
}

; --- 开机自启检测 ---
Label_AutoRun(AutoRun)

global CurrentDragModKey := DragModKey
global CurrentDragDirectKey := DragDirectKey

; ==========================================
; 系统托盘菜单初始化
; ==========================================
iconFile := A_ScriptDir "\GhostSnap.ico"
if FileExist(iconFile)
    Menu, Tray, Icon, %iconFile%

if (!ShowTrayIcon)
    Menu, Tray, NoIcon

Menu, Tray, NoStandard
Menu, Tray, Add, 设置中心, OpenSettingsGui
Menu, Tray, Default, 设置中心
Menu, Tray, Add
Menu, Tray, Add, 单轴滑动微调模式, ToggleSnapMode
if (StrictSingleAxisSnap)
    Menu, Tray, Check, 单轴滑动微调模式
Menu, Tray, Add, 启用幽灵窗口, ToggleGhostWindow
if (EnableGhostWindow)
    Menu, Tray, Check, 启用幽灵窗口
Menu, Tray, Add, 启用智能尺寸同步, ToggleSmartSync
if (EnableSmartSync)
    Menu, Tray, Check, 启用智能尺寸同步
Menu, Tray, Add, 启用按键联动移动, ToggleChaining
if (EnableChaining)
    Menu, Tray, Check, 启用按键联动移动
Menu, Tray, Add

Menu, RestoreSubMenu, Add, (无记录), DoNothing
Menu, RestoreSubMenu, Disable, (无记录)
Menu, Tray, Add, 还原窗口大小, :RestoreSubMenu

Menu, HiddenWinSubMenu, Add, (无记录), DoNothing
Menu, HiddenWinSubMenu, Disable, (无记录)
Menu, Tray, Add, 隐藏窗口列表, :HiddenWinSubMenu

Menu, ClickThroughSubMenu, Add, (无记录), DoNothing
Menu, ClickThroughSubMenu, Disable, (无记录)
Menu, Tray, Add, 穿透窗口列表, :ClickThroughSubMenu

Menu, Tray, Add, 重载脚本, ReloadApp
Menu, Tray, Add, 退出程序, ExitAppRoutine

; --- 全局状态变量 ---
global isMoving := false
global movingHwnd := 0
global ghostVisible := false
global willSnap := false
global snappedX := false, snappedY := false

global dragMode := "system"
global dragTriggerType := ""
global triggerKey := "LButton"
global dragMouseOffsetX := 0
global dragMouseOffsetY := 0

global destX := 0, destY := 0
global diffX := 0, diffY := 0, diffW := 0, diffH := 0

global TargetWindows := []
global TargetMonitors := []
global syncTargetX := 0
global syncTargetY := 0

global startMoveX := 0, startMoveY := 0
global ChainedGroup := []
global OrigWinSizes := {}
global RestoreOrder := []  ; 新增：专门用于记录窗口恢复项的先后顺序 (实现FIFO队列)

global SavedWinSizes := Var_Read("SavedWinSizes", "", "基础配置", SettingsDir, "否", "否")

global HiddenWinsMap := {}
global HiddenWinsOrder := []
global SavedHiddenWins := Var_Read("SavedHiddenWins", "", "基础配置", SettingsDir, "否", "否")

global ClickThroughWinsMap := {}
global ClickThroughWinsOrder := []
global SavedClickThroughWins := Var_Read("SavedClickThroughWins", "", "基础配置", SettingsDir, "否", "否")

; 初始化解析持久化的隐藏窗口记录
if (SavedHiddenWins != "") {
    Loop, Parse, SavedHiddenWins, |
    {
        if (A_LoopField = "")
            continue
        hw := A_LoopField
        HiddenWinsMap[hw] := true
        HiddenWinsOrder.Push(hw)
    }
    GoSub, UpdateHiddenWinMenu
}

; 初始化解析持久化的穿透窗口记录
if (SavedClickThroughWins != "") {
    Loop, Parse, SavedClickThroughWins, |
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, ",")
        if (parts.Length() == 2) {
            hw := parts[1], trans := parts[2]
            ClickThroughWinsMap[hw] := {Trans: trans}
            ClickThroughWinsOrder.Push(hw)
        }
    }
    GoSub, UpdateClickThroughMenu
}

; 初始化解析持久化的窗口记录
if (SavedWinSizes != "") {
    Loop, Parse, SavedWinSizes, |
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, ",")
        if (parts.Length() == 3) {
            hw := parts[1], w := parts[2], h := parts[3]
            OrigWinSizes[hw] := {W: w, H: h}
            RestoreOrder.Push(hw)
        }
    }
    GoSub, UpdateRestoreMenu ; 解析后更新一次菜单
}

; --- 初始化幽灵窗口 ---
global pToken := Gdip_Startup() ; 【新增】全局启动GDI+，防止频繁启停导致崩溃
Gui, Ghost: +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale +HwndGhostHwnd
Gui, Ghost: Color, % GhostColor
WinSet, Transparent, % GhostOpacity

global hookStart := DllCall("SetWinEventHook", "UInt", 0x000A, "UInt", 0x000A, "Ptr", 0, "Ptr", RegisterCallback("OnMoveStart"), "UInt", 0, "UInt", 0, "UInt", 0)
global hookEnd := DllCall("SetWinEventHook", "UInt", 0x000B, "UInt", 0x000B, "Ptr", 0, "Ptr", RegisterCallback("OnMoveEnd"), "UInt", 0, "UInt", 0, "UInt", 0)

if (CurrentDragModKey != "")
    Hotkey, %CurrentDragModKey% & LButton, DoModDrag, On, UseErrorLevel
if (CurrentDragDirectKey != "")
    Hotkey, %CurrentDragDirectKey%, DoDirectDrag, On, UseErrorLevel
if (CurrentResizeModKey != "")
    Hotkey, %CurrentResizeModKey% & LButton, DoResizeDrag, On, UseErrorLevel

OnExit("Cleanup")
; ==========================================
; 动态自定义菜单初始化
; ==========================================
global DynamicMenuActions := {}
global DynamicMenuFile := A_ScriptDir "\GhostSnap_menu.ini"

if not FileExist(DynamicMenuFile)
    FileCopy,%A_ScriptDir%\Plugins\Lib\GhostSnap_defaultmenu.ini, %A_ScriptDir%\GhostSnap_menu.ini

; 设置一个呼出主菜单的全局快捷键 (动态读取)
if (MenuHotkey != "")
    Hotkey, %MenuHotkey%, ShowDynamicMenu, On, UseErrorLevel

if FileExist(DynamicMenuFile)
    BuildDynamicMenu(DynamicMenuFile)
Return

; ===========================================================
; 全局鼠标事件双保险 (防止拖拽状态卡死)
; ===========================================================
~LButton Up::
    if (isMoving && dragMode == "manual") {
        SetTimer, TrackMove, Off
        SetTimer, ExecEndMove, -1          ;使用异步定时器脱钩执行
    }
    if (isResizingWin) {
        SetTimer, TrackResize, Off
        isResizingWin := false
        resizeHwnd := 0
    }
return

; 异步中转器，脱离系统的 Hook 线程保护操作
ExecEndMove:
    Gosub, ForceEndMove
return

; ===========================================================
; 托盘菜单与 GUI 辅助函数
; ===========================================================

ToggleSnapMode:
    StrictSingleAxisSnap := !StrictSingleAxisSnap
    Menu, Tray, ToggleCheck, 单轴滑动微调模式 (防角落锁死)
    Var_Set(StrictSingleAxisSnap, "0", "StrictSingleAxisSnap", "基础配置", SettingsDir)
return
ToggleGhostWindow:
    EnableGhostWindow := !EnableGhostWindow
    Menu, Tray, ToggleCheck, 启用幽灵窗口
    if (!EnableGhostWindow && ghostVisible) {
        Gui, Ghost: Hide
        ghostVisible := false
    }
    Var_Set(EnableGhostWindow, "1", "EnableGhostWindow", "基础配置", SettingsDir)
return
ToggleSmartSync:
    EnableSmartSync := !EnableSmartSync
    Menu, Tray, ToggleCheck, 启用智能尺寸同步
    Var_Set(EnableSmartSync, "1", "EnableSmartSync", "基础配置", SettingsDir)
return
ToggleChaining:
    EnableChaining := !EnableChaining
    Menu, Tray, ToggleCheck, 启用按键联动移动
    Var_Set(EnableChaining, "1", "EnableChaining", "基础配置", SettingsDir)
return

ReloadApp:
    Reload
return
ExitAppRoutine:
ExitApp
return

UpdateRestoreMenu:
    Menu, RestoreSubMenu, DeleteAll
    isEmpty := true
    deadHwnds := []

    ; 倒序遍历 RestoreOrder，让最新添加的显示在菜单最上方
    index := RestoreOrder.Length()
    while (index > 0) {
        hw := RestoreOrder[index]
        if WinExist("ahk_id " hw) {
            WinGetTitle, wTitle, ahk_id %hw%
            if (wTitle = "")
                wTitle := "未知窗口"
            menuStr := SubStr(wTitle, 1, 40) . " [" . hw . "]"
            Menu, RestoreSubMenu, Add, %menuStr%, RestoreTargetWindow
            isEmpty := false
        } else {
            deadHwnds.Push(index) ; 记录已经不存在的窗口的索引（由于倒序遍历，收集到的是从大到小的索引）
        }
        index--
    }

    ; 清理已关闭/失效的窗口记录 (从大索引开始Remove不影响小索引)
    For i, deadIdx in deadHwnds {
        dhw := RestoreOrder[deadIdx]
        OrigWinSizes.Delete(dhw)
        RestoreOrder.RemoveAt(deadIdx)
    }

    ; 如果清理了失效窗口，同步更新一次 ini
    if (deadHwnds.Length() > 0)
        SaveRestoreListToIni()

    if (isEmpty) {
        Menu, RestoreSubMenu, Add, (无记录), DoNothing
        Menu, RestoreSubMenu, Disable, (无记录)
    } else {
        ; 添加分隔符和清空列表功能
        Menu, RestoreSubMenu, Add
        Menu, RestoreSubMenu, Add, 清空窗口列表, ClearRestoreList
    }

return

DoNothing:
return

ShowDynamicMenu:
    if (MenuHotkeyBlacklist != "" && CheckWindowInList(WinExist("A"), MenuHotkeyBlacklist))
        return

    if (MenuStyle == 1) {
        Menu, CustomMenu_Level1, Show
    } else {
        ; 注册鼠标消息钩子（仅在菜单显示时起效）
        OnMessage(0x0200, "GdipMenu_MouseMove")
        OnMessage(0x0201, "GdipMenu_LButtonDown")
        OnMessage(0x0204, "GdipMenu_RButtonDown")

        CoordMode, Mouse, Screen
        MouseGetPos, mX, mY
        ShowGdipMenu_Level("CustomMenu_Level1", mX, mY, 1)
    }
return

RestoreTargetWindow:
    RegExMatch(A_ThisMenuItem, "\[(.*?)\]$", match)
    targetHwnd := match1
    if (targetHwnd && OrigWinSizes.HasKey(targetHwnd)) {
        orig := OrigWinSizes[targetHwnd]

        ; 临时开启隐藏窗口检测，确保能捕捉到被隐藏的窗口
        DetectHiddenWindows, On

        ; 判断窗口是否真的还存在（没被用户彻底关闭）
        if WinExist("ahk_id " targetHwnd) {

            ; 先强制取消隐藏
            WinShow, ahk_id %targetHwnd%

            ; 检测窗口是否被最小化，如果是，则先将其恢复
            WinGet, minMax, MinMax, ahk_id %targetHwnd%
            if (minMax = -1)
                WinRestore, ahk_id %targetHwnd%

            ; 为了体验更好，将它直接激活带到最前面来
            WinActivate, ahk_id %targetHwnd%

            ; 恢复状态后再移动和调整大小
            WinMove, ahk_id %targetHwnd%, , , , % orig.W, % orig.H
        }

        ; 恢复系统默认状态（关闭隐藏窗口检测，防止影响脚本其他逻辑）
        DetectHiddenWindows, Off

        ; 无论窗口是成功还原了，还是因为已经被关闭导致还原失败，都将其从记录中清理掉
        OrigWinSizes.Delete(targetHwnd)
        For i, hw in RestoreOrder {
            if (hw == targetHwnd) {
                RestoreOrder.RemoveAt(i)
                break
            }
        }

        Gosub, UpdateRestoreMenu
        SaveRestoreListToIni() ; 同步到 INI
    }
return

; 新增：一键清空还原列表
ClearRestoreList:
    OrigWinSizes := {}
    RestoreOrder := []
    Gosub, UpdateRestoreMenu
    SaveRestoreListToIni()
return

; ==========================================
; 隐藏窗口的托盘菜单与恢复逻辑
; ==========================================
UpdateHiddenWinMenu:
    Menu, HiddenWinSubMenu, DeleteAll
    isEmpty := true
    deadHwnds := []

    index := HiddenWinsOrder.Length()
    while (index > 0) {
        hw := HiddenWinsOrder[index]
        DetectHiddenWindows, On ; 开启隐藏窗口检测以获取标题
        if WinExist("ahk_id " hw) {
            WinGetTitle, wTitle, ahk_id %hw%
            if (wTitle = "")
                wTitle := "未知隐藏窗口"
            menuStr := SubStr(wTitle, 1, 40) . " [" . hw . "]"
            Menu, HiddenWinSubMenu, Add, %menuStr%, RestoreHiddenTargetWindow
            isEmpty := false
        } else {
            deadHwnds.Push(index)
        }
        DetectHiddenWindows, Off
        index--
    }

    For i, deadIdx in deadHwnds {
        dhw := HiddenWinsOrder[deadIdx]
        HiddenWinsMap.Delete(dhw)
        HiddenWinsOrder.RemoveAt(deadIdx)
    }
    if (deadHwnds.Length() > 0)
        SaveHiddenListToIni()

    if (isEmpty) {
        Menu, HiddenWinSubMenu, Add, (无记录), DoNothing
        Menu, HiddenWinSubMenu, Disable, (无记录)
    } else {
        Menu, HiddenWinSubMenu, Add
        Menu, HiddenWinSubMenu, Add, 恢复所有隐藏窗口, RestoreAllHiddenWindows
    }
return

RestoreHiddenTargetWindow:
    RegExMatch(A_ThisMenuItem, "\[(.*?)\]$", match)
    targetHwnd := match1
    if (targetHwnd && HiddenWinsMap.HasKey(targetHwnd)) {
        DetectHiddenWindows, On
        if WinExist("ahk_id " targetHwnd) {
            WinShow, ahk_id %targetHwnd%
            WinActivate, ahk_id %targetHwnd%
        }
        DetectHiddenWindows, Off

        HiddenWinsMap.Delete(targetHwnd)
        For i, hw in HiddenWinsOrder {
            if (hw == targetHwnd) {
                HiddenWinsOrder.RemoveAt(i)
                break
            }
        }
        Gosub, UpdateHiddenWinMenu
        SaveHiddenListToIni()
    }
return

RestoreAllHiddenWindows:
    DetectHiddenWindows, On
    For i, targetHwnd in HiddenWinsOrder {
        if WinExist("ahk_id " targetHwnd) {
            WinShow, ahk_id %targetHwnd%
        }
    }
    DetectHiddenWindows, Off

    HiddenWinsMap := {}
    HiddenWinsOrder := []
    Gosub, UpdateHiddenWinMenu
    SaveHiddenListToIni()
return

; ==========================================
; 鼠标穿透窗口的托盘菜单与恢复逻辑
; ==========================================
UpdateClickThroughMenu:
    Menu, ClickThroughSubMenu, DeleteAll
    isEmpty := true
    deadHwnds := []

    index := ClickThroughWinsOrder.Length()
    while (index > 0) {
        hw := ClickThroughWinsOrder[index]
        if WinExist("ahk_id " hw) {
            WinGetTitle, wTitle, ahk_id %hw%
            if (wTitle = "")
                wTitle := "未知窗口"
            menuStr := SubStr(wTitle, 1, 40) . " [" . hw . "]"
            Menu, ClickThroughSubMenu, Add, %menuStr%, RestoreClickThroughTargetWindow
            isEmpty := false
        } else {
            deadHwnds.Push(index)
        }
        index--
    }

    For i, deadIdx in deadHwnds {
        dhw := ClickThroughWinsOrder[deadIdx]
        ClickThroughWinsMap.Delete(dhw)
        ClickThroughWinsOrder.RemoveAt(deadIdx)
    }
    if (deadHwnds.Length() > 0)
        SaveClickThroughListToIni()

    if (isEmpty) {
        Menu, ClickThroughSubMenu, Add, (无记录), DoNothing
        Menu, ClickThroughSubMenu, Disable, (无记录)
    } else {
        Menu, ClickThroughSubMenu, Add
        Menu, ClickThroughSubMenu, Add, 恢复所有穿透窗口, RestoreAllClickThroughWindows
    }
return

RestoreClickThroughTargetWindow:
    RegExMatch(A_ThisMenuItem, "\[(.*?)\]$", match)
    targetHwnd := match1
    if (targetHwnd && ClickThroughWinsMap.HasKey(targetHwnd)) {
        if WinExist("ahk_id " targetHwnd) {
            WinSet, ExStyle, -0x20, ahk_id %targetHwnd%  ; 移除穿透属性
            origTrans := ClickThroughWinsMap[targetHwnd].Trans
            if (origTrans != "")
                WinSet, Transparent, %origTrans%, ahk_id %targetHwnd%
            else
                WinSet, Transparent, Off, ahk_id %targetHwnd%
        }

        ClickThroughWinsMap.Delete(targetHwnd)
        For i, hw in ClickThroughWinsOrder {
            if (hw == targetHwnd) {
                ClickThroughWinsOrder.RemoveAt(i)
                break
            }
        }
        Gosub, UpdateClickThroughMenu
        SaveClickThroughListToIni()
    }
return

RestoreAllClickThroughWindows:
    For i, targetHwnd in ClickThroughWinsOrder {
        if WinExist("ahk_id " targetHwnd) {
            WinSet, ExStyle, -0x20, ahk_id %targetHwnd%
            origTrans := ClickThroughWinsMap[targetHwnd].Trans
            if (origTrans != "")
                WinSet, Transparent, %origTrans%, ahk_id %targetHwnd%
            else
                WinSet, Transparent, Off, ahk_id %targetHwnd%
        }
    }
    ClickThroughWinsMap := {}
    ClickThroughWinsOrder := []
    Gosub, UpdateClickThroughMenu
    SaveClickThroughListToIni()
return

; ==========================================
; 设置中心 GUI 界面逻辑
; ==========================================
OpenSettingsGui:
    Gui, Settings:Destroy
    Gui, Settings:Font, s9, Microsoft YaHei
    Gui, Settings:Add, Tab3, x10 y10 w550 h485, 基础吸附|外观动画|拖拽/联动|贴边隐藏|黑名单|系统/高级|自绘菜单|关于

    ; --- 标签页 1: 基础吸附 ---
    Gui, Settings:Tab, 1
    Gui, Settings:Add, Text, x30 y45 w150 h20, 触发吸附距离 (像素):
    Gui, Settings:Add, Edit, x190 y43 w80 h20 vGui_SnapDistance Number, %SnapDistance%
    Gui, Settings:Add, UpDown, Range1-100, %SnapDistance%

    Gui, Settings:Add, Text, x30 y75 w150 h20, 挣脱阻尼距离 (像素):
    Gui, Settings:Add, Edit, x190 y73 w80 h20 vGui_BreakoutDistance Number, %BreakoutDistance%
    Gui, Settings:Add, UpDown, Range1-200, %BreakoutDistance%

    Gui, Settings:Add, Checkbox, x30 y105 w300 h20 vGui_StrictSingle Checked%StrictSingleAxisSnap%, 单轴滑动微调模式 (防角落锁死)
    Gui, Settings:Add, Checkbox, x30 y130 w300 h20 vGui_EdgeSnap Checked%EnableScreenEdgeSnap%, 启用屏幕边缘吸附

    Gui, Settings:Add, Checkbox, x30 y155 w130 h20 vGui_SmartSync Checked%EnableSmartSync%, 启用智能尺寸同步
    Gui, Settings:Add, Text, x170 y157 w60 h20, 触发按键:
    Gui, Settings:Add, Edit, x230 y155 w80 h20 vGui_SmartSyncKey, %SmartSyncKey%
    Gui, Settings:Add, Text, x320 y157 w100 h20 cGray, (默认: Alt)

    ; [优化 1] 用方框将吸附按键与反向模式框在一起
    Gui, Settings:Add, GroupBox, x20 y185 w420 h105, 吸附按键与反向模式
    Gui, Settings:Add, Text, x30 y210 w130 h20, 吸附切换/中断按键:
    Gui, Settings:Add, Edit, x170 y208 w80 h20 vGui_SnapToggleKey, %SnapToggleKey%
    Gui, Settings:Add, Text, x260 y210 w150 h20 cGray, (默认: Shift)

    Gui, Settings:Add, Checkbox, x30 y240 w380 h20 vGui_RequireKeyToSnap Checked%RequireKeyToSnap%, 反向模式：平时不吸附，按住上方按键才触发吸附
    Gui, Settings:Add, Text, x50 y260 w380 h30 cGray, 备注: 勾选此项后，按键逻辑反转。适合特定时刻才触发的用户。

    ; --- 标签页 2: 外外观与动画 ---
    Gui, Settings:Tab, 2
    Gui, Settings:Add, Checkbox, x30 y45 w300 h20 vGui_GhostWin Checked%EnableGhostWindow%, 启用幽灵窗口特效

    Gui, Settings:Add, Text, x30 y75 w100 h20, 幽灵窗口颜色:
    Gui, Settings:Add, Edit, x130 y73 w70 h20 vGui_GhostColor Limit6, %GhostColor%
    Gui, Settings:Add, Progress, x210 y73 w20 h20 Background%GhostColor% vColorPreview
    Gui, Settings:Add, Button, x240 y71 w80 h24 gChooseColorBtn, 选择颜色

    Gui, Settings:Add, Text, x30 y105 w100 h20, 幽灵透明度 (0-255):
    Gui, Settings:Add, Slider, x125 y105 w200 h30 vGui_GhostOpacity Range0-255 TickInterval25 ToolTip, %GhostOpacity%

    ; --- 动画配置 (紧凑化) ---
    Gui, Settings:Add, GroupBox, x25 y145 w410 h130, 磁吸释放平滑过渡动画
    Gui, Settings:Add, Checkbox, x40 y170 w350 h20 vGui_EnableAnim Checked%EnableSnapAnimation% gToggleAnimGuiState, 启用释放吸附时的平滑过渡动画 (关闭则为生硬瞬移)

    Gui, Settings:Add, Text, x40 y205 w110 h20 vGui_TextSteps, 动画过渡帧数 (组):
    Gui, Settings:Add, Edit, x155 y203 w60 h20 vGui_AnimSteps Number, %SnapAnimSteps%
    Gui, Settings:Add, UpDown, Range1-30, %SnapAnimSteps%
    Gui, Settings:Add, Text, x225 y205 w200 h20 cGray vGui_DescSteps, (帧数越多，过渡动作分解越细)

    Gui, Settings:Add, Text, x40 y235 w110 h20 vGui_TextSleep, 每帧延迟时间 (ms):
    Gui, Settings:Add, Edit, x155 y233 w60 h20 vGui_AnimSleep Number, %SnapAnimSleep%
    Gui, Settings:Add, UpDown, Range1-100, %SnapAnimSleep%
    Gui, Settings:Add, Text, x225 y235 w200 h20 cGray vGui_DescSleep, (延迟越低帧率越高，动画结算越快)

    GoSub, ToggleAnimGuiState

    ; --- 标签页 3: 拖拽与联动 ---
    Gui, Settings:Tab, 3
    Gui Settings:Add, Text, x30 y45 w140 h20, 任意位置拖拽修饰键:
    Gui, Settings:Add, Edit, x170 y43 w100 h20 vGui_DragModKey, %DragModKey%
    Gui, Settings:Add, Text, x280 y45 w150 h20 cGray, (如: LWin 留空禁用)

    Gui, Settings:Add, Text, x30 y75 w140 h20, 任意位置拖拽直接键:
    Gui, Settings:Add, Edit, x170 y73 w100 h20 vGui_DragDirectKey, %DragDirectKey%
    Gui, Settings:Add, Text, x280 y75 w150 h20 cGray, (如: XButton1 MButton)

    ; [优化 2] 用方框将调整大小修饰键与还原记录框在一起
    Gui, Settings:Add, GroupBox, x20 y105 w420 h90, 窗口大小调整与还原记录
    Gui Settings:Add, Text, x30 y130 w140 h20, 任意位置调整大小修饰键:
    Gui, Settings:Add, Edit, x170 y128 w80 h20 vGui_ResizeModKey, %ResizeModKey%
    Gui, Settings:Add, Text, x260 y130 w170 h20 cGray, (如: RWin 留空禁用)

    Gui, Settings:Add, Text, x30 y160 w140 h20, 还原列表最大记录数:
    Gui, Settings:Add, Edit, x170 y158 w80 h20 vGui_MaxRestoreCount Number, %MaxRestoreCount%
    Gui, Settings:Add, UpDown, Range1-50, %MaxRestoreCount%
    Gui, Settings:Add, Text, x260 y160 w170 h20 cGray, (默认: 10，防菜单过长)

    ; [优化 3] 启用联动与修饰键合并到同一行
    Gui, Settings:Add, Checkbox, x30 y215 w140 h20 vGui_Chaining Checked%EnableChaining%, 启用窗口联动移动
    Gui, Settings:Add, Text, x175 y215 w90 h20, 触发联动修饰键:
    Gui, Settings:Add, Edit, x270 y213 w60 h20 vGui_ChainModKey, %ChainModKey%
    Gui, Settings:Add, Text, x340 y215 w100 h20 cGray, (如: Ctrl, Alt)
    Gui, Settings:Add, Checkbox, x30 y245 w400 h20 vGui_AllowMaximized Checked%AllowMaximizedWin%, 允许修饰键直接拖拽/调整[最大化]的窗口 (将自动还原)

    ; --- 标签页 4: 贴边隐藏 ---
    Gui, Settings:Tab, 4
    Gui, Settings:Add, Text, x30 y45 w140 h20, 触发贴边隐藏按键:
    Gui, Settings:Add, Edit, x180 y43 w100 h20 vGui_AutoHideModKey, %AutoHideModKey%
    Gui, Settings:Add, Text, x290 y45 w150 h20 cGray, (默认: CapsLock, 留空禁用)

    Gui, Settings:Add, Text, x30 y75 w140 h20, 触发贴边距离 (像素):
    Gui, Settings:Add, Edit, x180 y73 w50 h20 vGui_AutoHideDistance Number, %AutoHideDistance%

    Gui, Settings:Add, Text, x250 y75 w140 h20, 边缘凸出长度 (像素):
    Gui, Settings:Add, Edit, x380 y73 w50 h20 vGui_AutoHideProtrude Number, %AutoHideProtrude%

    Gui, Settings:Add, Text, x30 y105 w140 h20, 悬停显示延迟 (毫秒):
    Gui, Settings:Add, Edit, x180 y103 w50 h20 vGui_AutoHideShowDelay Number, %AutoHideShowDelay%

    Gui, Settings:Add, Text, x250 y105 w140 h20, 移出隐藏延迟 (毫秒):
    Gui, Settings:Add, Edit, x380 y103 w50 h20 vGui_AutoHideHideDelay Number, %AutoHideHideDelay%

    Gui, Settings:Add, Text, x30 y135 w140 h20, 移出判定容差 (像素):
    Gui, Settings:Add, Edit, x180 y133 w50 h20 vGui_AutoHideTolerance Number, %AutoHideTolerance%

    Gui, Settings:Add, Text, x250 y135 w90 h20, 角落隐藏优先:
    edgeChoice := (AutoHideEdgePriority == "2") ? 3 : ((AutoHideEdgePriority == "1") ? 2 : 1)
    Gui, Settings:Add, DropDownList, x340 y133 w90 vGui_AutoHideEdgePriority AltSubmit Choose%edgeChoice%, 上下优先|左右优先|距离优先

    Gui, Settings:Add, Checkbox, x30 y165 w200 h20 vGui_AutoHideTopmost Checked%AutoHideTopmost%, 隐藏/显示时保持置顶
    Gui, Settings:Add, Checkbox, x250 y165 w200 h20 vGui_AutoHideFocus Checked%AutoHideFocus%, 呼出时获取焦点，隐藏时失去

    ; 独立动画配置 (紧凑化)
    Gui, Settings:Add, GroupBox, x25 y195 w410 h100, 贴边隐藏平滑过渡动画
    Gui, Settings:Add, Checkbox, x40 y215 w350 h20 vGui_EnableAutoHideAnim Checked%EnableAutoHideAnim% gToggleAutoHideAnimGuiState, 启用贴边隐藏/呼出时的平滑过渡动画

    Gui, Settings:Add, Text, x40 y245 w110 h20 vGui_TextAHSteps, 动画过渡帧数 (组):
    Gui, Settings:Add, Edit, x155 y243 w60 h20 vGui_AHAnimSteps Number, %AutoHideAnimSteps%
    Gui, Settings:Add, UpDown, Range1-30, %AutoHideAnimSteps%

    Gui, Settings:Add, Text, x235 y245 w110 h20 vGui_TextAHSleep, 每帧延迟时间 (ms):
    Gui, Settings:Add, Edit, x350 y243 w60 h20 vGui_AHAnimSleep Number, %AutoHideAnimSleep%
    Gui, Settings:Add, UpDown, Range1-100, %AutoHideAnimSleep%

    Gui, Settings:Add, Checkbox, x30 y305 w350 h20 vGui_AutoHideFullscreen Checked%AutoHideFullscreenHide%, 全屏时自动完全隐藏凸出部分 (防打扰)
    Gui, Settings:Add, Text, x30 y330 w400 h40 cGray, 提示：按住指定修饰键移动到边缘即可触发。贴边隐藏的窗口再次拖拽可记忆原状态。

    GoSub, ToggleAutoHideAnimGuiState

    ; --- 标签页 5: 黑名单 ---
    Gui, Settings:Tab, 5
    Gui, Settings:Add, Text, x25 y45 w400 h20, 全局窗口黑名单 (吸附与拖拽均无效):
    Gui, Settings:Add, Edit, x25 y65 w410 h80 vGui_Blacklist Multi WantReturn, %Blacklist%

    Gui, Settings:Add, Text, x25 y155 w400 h20, 修饰键拖拽黑名单 (仅限修饰键拖拽无效):
    Gui, Settings:Add, Edit, x25 y175 w410 h70 vGui_DragModBlacklist Multi WantReturn, %DragModBlacklist%

    Gui, Settings:Add, Text, x25 y255 w400 h20, 直接键拖拽黑名单 (仅限直接键拖拽无效):
    Gui, Settings:Add, Edit, x25 y275 w410 h70 vGui_DragDirectBlacklist Multi WantReturn, %DragDirectBlacklist%

    Gui, Settings:Add, Text, x25 y355 w400 h20, 菜单与动态动作热键黑名单 (在这些窗口中按键无效):
    Gui, Settings:Add, Edit, x25 y375 w410 h70 vGui_MenuHotkeyBlacklist Multi WantReturn, %MenuHotkeyBlacklist%

    ; --- 标签页 6: 系统与高级 ---
    Gui, Settings:Tab, 6
    Gui, Settings:Add, Checkbox, x30 y45 w300 h20 vGui_AdminLaunch Checked%AdminLaunch%, 以管理员权限运行 (需重启脚本生效)
    Gui, Settings:Add, Checkbox, x30 y75 w300 h20 vGui_AutoRun Checked%AutoRun%, 开机自启动
    Gui, Settings:Add, Checkbox, x30 y105 w350 h20 vGui_ShowTrayIcon Checked%ShowTrayIcon%, 显示托盘图标 (若隐藏需手动修改 ini 文件恢复)

    ; --- 标签页 7: 自绘菜单 ---
    Gui, Settings:Tab, 7

    ; 【新增】从 Tab 6 移动过来的配置项，放于顶部
    Gui, Settings:Add, Text, x30 y45 w110 h20, 全局菜单渲染样式:
    Gui, Settings:Add, DropDownList, x145 y43 w150 vGui_MenuStyle Choose%MenuStyle% AltSubmit, 系统原生风格|GDI+ 现代化风格

    Gui, Settings:Add, Text, x30 y85 w110 h20, 呼出菜单全局热键:
    Gui, Settings:Add, Hotkey, x145 y83 w120 h20 vGui_MenuHotkey_Helper gSyncMenuHotkey
    Gui, Settings:Add, Text, x270 y85 w20 h20, ➔
    Gui, Settings:Add, Edit, x290 y83 w120 h20 vGui_MenuHotkey, %MenuHotkey%
    Gui, Settings:Add, Text, x30 y110 w140 h20 cGray, 注：右侧为准，可手加 # 代表 Win

    ; 【修复】处理主题色彩默认值 (将保存的字符串转为数字索引，让 AltSubmit 能识别)
    ThemeChoice := (MenuGdipTheme == "Dark") ? 2 : 1
    Gui, Settings:Add, Text, x30 y145 w110 h20, 菜单主题色彩:
    Gui, Settings:Add, DropDownList, x145 y143 w150 vGui_MenuGdipTheme Choose%ThemeChoice% AltSubmit, 浅色模式 (Light)|深色模式 (Dark)

    ; 下方控件整体调整 Y 坐标下移
    Gui, Settings:Add, Checkbox, x30 y185 w150 h20 vGui_MenuGdipHover Checked%MenuGdipHoverHighlight%, 开启悬停高亮菜单项
    Gui, Settings:Add, Checkbox, x200 y185 w150 h20 vGui_MenuGdipTooltip Checked%MenuGdipShowTooltip%, 开启悬停信息提示

    Gui, Settings:Add, Checkbox, x30 y225 w100 h20 vGui_MenuGdipIcon Checked%MenuGdipShowIcon%, 启用菜单图标
    Gui, Settings:Add, Text, x200 y227 w60 h20, 图标尺寸:
    Gui, Settings:Add, Edit, x270 y225 w60 h20 vGui_MenuGdipIconSize Number, %MenuGdipIconSize%
    Gui, Settings:Add, UpDown, Range8-64, %MenuGdipIconSize%

    Gui, Settings:Add, Text, x30 y265 w60 h20, 字体名称:
    Gui, Settings:Add, Edit, x95 y263 w100 h20 vGui_MenuGdipFontName, %MenuGdipFontName%
    Gui, Settings:Add, Text, x210 y265 w60 h20, 字体大小:
    Gui, Settings:Add, Edit, x270 y263 w60 h20 vGui_MenuGdipFontSize Number, %MenuGdipFontSize%
    Gui, Settings:Add, UpDown, Range8-36, %MenuGdipFontSize%

    Gui, Settings:Add, Text, x30 y305 w60 h20, 菜单行距:
    Gui, Settings:Add, Edit, x95 y303 w100 h20 vGui_MenuGdipLineSpacing Number, %MenuGdipLineSpacing%
    Gui, Settings:Add, UpDown, Range20-80, %MenuGdipLineSpacing%
    Gui, Settings:Add, Text, x210 y305 w60 h20, 最小宽度:
    Gui, Settings:Add, Edit, x270 y303 w40 h20 vGui_MenuGdipMinWidth Number, %MenuGdipMinWidth%
    Gui, Settings:Add, Text, x320 y305 w60 h20, 最大宽度:
    Gui, Settings:Add, Edit, x380 y303 w40 h20 vGui_MenuGdipMaxWidth Number, %MenuGdipMaxWidth%

    ; --- 标签页 8: 关于 ---
    Gui, Settings:Tab, 8
    Gui, Settings:Add, GroupBox, x25 y45 w410 h270, 关于软件
    Gui, Settings:Add, Text, x45 y75 w80 h20, 软件名称:
    Gui, Settings:Add, Text, x120 y75 w200 h20 c0078D7, GhostSnap
    Gui, Settings:Add, Text, x45 y110 w80 h20, 当前版本:
    Gui, Settings:Add, Text, x120 y110 w200 h20, v%当前工具版本%
    Gui, Settings:Add, Text, x45 y145 w80 h20, 软件作者:
    Gui, Settings:Add, Text, x120 y145 w200 h20, 逍遥
    Gui, Settings:Add, Text, x45 y180 w80 h20, 开源地址:
    Gui, Settings:Add, Link, x120 y180 w300 h20, <a href="https://github.com/lch319/GhostSnap">github.com/lch319/GhostSnap</a>
    Gui, Settings:Add, Text, x45 y225 w370 h60 cGray, 声明与提示:`n本软件为开源窗口增强工具，提供智能吸附、尺寸同步、幽灵窗口、贴边隐藏及窗口移动联动等功能。感谢您的使用与支持！

    ; --- 底部按钮区 ---
    Gui, Settings:Tab
    Gui, Settings:Add, Button, x155 y505 w100 h32 Default gSaveAndRestart, 保存并重启
    Gui, Settings:Add, Button, x265 y505 w80 h32 gApplyConfig, 应用
    Gui, Settings:Add, Button, x355 y505 w80 h32 gSettingsGuiClose, 取消

    Gui, Settings:Show, w570 h550, GhostSnap_v%当前工具版本% 设置中心
return

ToggleAnimGuiState:
    Gui, Settings:Submit, NoHide
    state := Gui_EnableAnim ? "Enable" : "Disable"
    GuiControl, Settings:%state%, Gui_AnimSteps
    GuiControl, Settings:%state%, Gui_AnimSleep
    GuiControl, Settings:%state%, Gui_TextSteps
    GuiControl, Settings:%state%, Gui_TextSleep
    GuiControl, Settings:%state%, Gui_DescSteps
    GuiControl, Settings:%state%, Gui_DescSleep
return

ToggleAutoHideAnimGuiState:
    Gui, Settings:Submit, NoHide
    stateAH := Gui_EnableAutoHideAnim ? "Enable" : "Disable"
    GuiControl, Settings:%stateAH%, Gui_AHAnimSteps
    GuiControl, Settings:%stateAH%, Gui_AHAnimSleep
    GuiControl, Settings:%stateAH%, Gui_TextAHSteps
    GuiControl, Settings:%stateAH%, Gui_TextAHSleep
return

ChooseColorBtn:
    Gui, Settings:Submit, NoHide
    NewColor := ChooseColor(Gui_GhostColor)
    if (NewColor != "") {
        GuiControl, Settings:, Gui_GhostColor, %NewColor%
        GuiControl, Settings:+Background%NewColor%, ColorPreview
    }
return

ApplyConfig:
    Gui, Settings:Submit, NoHide

    Var_Set(Gui_SnapDistance, "20", "SnapDistance", "基础配置", SettingsDir)
    Var_Set(Gui_BreakoutDistance, "30", "BreakoutDistance", "基础配置", SettingsDir)
    Var_Set(Gui_StrictSingle, "0", "StrictSingleAxisSnap", "基础配置", SettingsDir)
    Var_Set(Gui_GhostWin, "1", "EnableGhostWindow", "基础配置", SettingsDir)
    Var_Set(Gui_GhostColor, "0078D7", "GhostColor", "基础配置", SettingsDir)
    Var_Set(Gui_GhostOpacity, "80", "GhostOpacity", "基础配置", SettingsDir)
    Var_Set(Gui_EdgeSnap, "1", "EnableScreenEdgeSnap", "基础配置", SettingsDir)
    Var_Set(Gui_SmartSync, "1", "EnableSmartSync", "基础配置", SettingsDir)

    Var_Set(Gui_EnableAnim, "1", "EnableSnapAnimation", "基础配置", SettingsDir)
    Var_Set(Gui_AnimSteps, "4", "SnapAnimSteps", "基础配置", SettingsDir)
    Var_Set(Gui_AnimSleep, "10", "SnapAnimSleep", "基础配置", SettingsDir)

    Var_Set(Gui_SmartSyncKey, "Alt", "SmartSyncKey", "基础配置", SettingsDir)
    Var_Set(Gui_SnapToggleKey, "Shift", "SnapToggleKey", "基础配置", SettingsDir)
    Var_Set(Gui_RequireKeyToSnap, "0", "RequireKeyToSnap", "基础配置", SettingsDir)

    Var_Set(Gui_DragModKey, "", "DragModKey", "基础配置", SettingsDir)
    Var_Set(Gui_DragDirectKey, "", "DragDirectKey", "基础配置", SettingsDir)
    Var_Set(Gui_ResizeModKey, "", "ResizeModKey", "基础配置", SettingsDir)
    Var_Set(Gui_AllowMaximized, "0", "AllowMaximizedWin", "基础配置", SettingsDir)
    Var_Set(Gui_MenuHotkey, "#m", "MenuHotkey", "基础配置", SettingsDir)
    Var_Set(Gui_MenuHotkeyBlacklist, "", "MenuHotkeyBlacklist", "基础配置", SettingsDir)
    Var_Set(Gui_MaxRestoreCount, "10", "MaxRestoreCount", "基础配置", SettingsDir)
    Var_Set(Gui_Chaining, "1", "EnableChaining", "基础配置", SettingsDir)
    Var_Set(Gui_ChainModKey, "Ctrl", "ChainModKey", "基础配置", SettingsDir)
    Var_Set(Gui_Blacklist, defaultBlacklist, "Blacklist", "基础配置", SettingsDir)
    Var_Set(Gui_DragModBlacklist, "", "DragModBlacklist", "基础配置", SettingsDir)
    Var_Set(Gui_DragDirectBlacklist, "", "DragDirectBlacklist", "基础配置", SettingsDir)

    Var_Set(Gui_AdminLaunch, "0", "AdminLaunch", "基础配置", SettingsDir)
    Var_Set(Gui_AutoRun, "0", "AutoRun", "基础配置", SettingsDir)
    Var_Set(Gui_ShowTrayIcon, "1", "ShowTrayIcon", "基础配置", SettingsDir)

    ; 保存贴边隐藏配置
    Var_Set(Gui_AutoHideModKey, "", "AutoHideModKey", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideDistance, "20", "AutoHideDistance", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideProtrude, "8", "AutoHideProtrude", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideShowDelay, "150", "AutoHideShowDelay", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideHideDelay, "350", "AutoHideHideDelay", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideTolerance, "5", "AutoHideTolerance", "贴边隐藏", SettingsDir)

    newEdgePriority := (Gui_AutoHideEdgePriority == 3) ? "2" : ((Gui_AutoHideEdgePriority == 2) ? "1" : "0")
    Var_Set(newEdgePriority, "0", "AutoHideEdgePriority", "贴边隐藏", SettingsDir)

    Var_Set(Gui_AutoHideTopmost, "0", "AutoHideTopmost", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideFocus, "1", "AutoHideFocus", "贴边隐藏", SettingsDir)
    Var_Set(Gui_EnableAutoHideAnim, "1", "EnableAutoHideAnim", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AHAnimSteps, "5", "AutoHideAnimSteps", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AHAnimSleep, "8", "AutoHideAnimSleep", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideFullscreen, "1", "AutoHideFullscreenHide", "贴边隐藏", SettingsDir)

    Var_Set(Gui_MenuStyle, "2", "MenuStyle", "基础配置", SettingsDir)
    MenuStyle := Gui_MenuStyle

    ; [增加以下代码]
    Var_Set(Gui_MenuGdipTheme == 1 ? "Light" : "Dark", "Light", "MenuGdipTheme", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipHover, "1", "MenuGdipHoverHighlight", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipIcon, "1", "MenuGdipShowIcon", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipIconSize, "16", "MenuGdipIconSize", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipTooltip, "1", "MenuGdipShowTooltip", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipFontName, "Microsoft YaHei", "MenuGdipFontName", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipFontSize, "12", "MenuGdipFontSize", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipLineSpacing, "22", "MenuGdipLineSpacing", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipMaxWidth, "240", "MenuGdipMaxWidth", "自绘菜单", SettingsDir)
    Var_Set(Gui_MenuGdipMinWidth, "150", "MenuGdipMinWidth", "自绘菜单", SettingsDir)

    MenuGdipTheme := Gui_MenuGdipTheme == 1 ? "Light" : "Dark"
    MenuGdipHoverHighlight := Gui_MenuGdipHover
    MenuGdipShowIcon := Gui_MenuGdipIcon
    MenuGdipIconSize := Gui_MenuGdipIconSize
    MenuGdipShowTooltip := Gui_MenuGdipTooltip
    MenuGdipFontName := Gui_MenuGdipFontName
    MenuGdipFontSize := Gui_MenuGdipFontSize
    MenuGdipLineSpacing := Gui_MenuGdipLineSpacing
    MenuGdipMaxWidth := Gui_MenuGdipMaxWidth
    MenuGdipMinWidth := Gui_MenuGdipMinWidth

    SnapDistance := Gui_SnapDistance
    BreakoutDistance := Gui_BreakoutDistance
    StrictSingleAxisSnap := Gui_StrictSingle
    EnableGhostWindow := Gui_GhostWin
    GhostColor := Gui_GhostColor
    GhostOpacity := Gui_GhostOpacity
    EnableScreenEdgeSnap := Gui_EdgeSnap
    EnableSmartSync := Gui_SmartSync

    EnableSnapAnimation := Gui_EnableAnim
    SnapAnimSteps := Gui_AnimSteps
    SnapAnimSleep := Gui_AnimSleep

    SmartSyncKey := Gui_SmartSyncKey
    SnapToggleKey := Gui_SnapToggleKey
    RequireKeyToSnap := Gui_RequireKeyToSnap

    DragModKey := Gui_DragModKey
    DragDirectKey := Gui_DragDirectKey
    ResizeModKey := Gui_ResizeModKey
    AllowMaximizedWin := Gui_AllowMaximized
    MenuHotkey := Gui_MenuHotkey
    MenuHotkeyBlacklist := Gui_MenuHotkeyBlacklist
    MaxRestoreCount := Gui_MaxRestoreCount
    EnableChaining := Gui_Chaining
    ChainModKey := Gui_ChainModKey
    Blacklist := Gui_Blacklist
    DragModBlacklist := Gui_DragModBlacklist
    DragDirectBlacklist := Gui_DragDirectBlacklist

    AdminLaunch := Gui_AdminLaunch
    AutoRun := Gui_AutoRun
    ShowTrayIcon := Gui_ShowTrayIcon

    AutoHideModKey := Gui_AutoHideModKey
    AutoHideDistance := Gui_AutoHideDistance
    AutoHideProtrude := Gui_AutoHideProtrude
    AutoHideShowDelay := Gui_AutoHideShowDelay
    AutoHideHideDelay := Gui_AutoHideHideDelay
    AutoHideTolerance := Gui_AutoHideTolerance
    AutoHideEdgePriority := newEdgePriority
    AutoHideTopmost := Gui_AutoHideTopmost
    AutoHideFocus := Gui_AutoHideFocus
    EnableAutoHideAnim := Gui_EnableAutoHideAnim
    AutoHideAnimSteps := Gui_AHAnimSteps
    AutoHideAnimSleep := Gui_AHAnimSleep
    AutoHideFullscreenHide := Gui_AutoHideFullscreen

    Menu, Tray, % StrictSingleAxisSnap ? "Check" : "Uncheck", 单轴滑动微调模式
    Menu, Tray, % EnableGhostWindow ? "Check" : "Uncheck", 启用幽灵窗口
    Menu, Tray, % EnableSmartSync ? "Check" : "Uncheck", 启用智能尺寸同步
    Menu, Tray, % EnableChaining ? "Check" : "Uncheck", 启用按键联动移动

    Gui, Ghost: Color, % GhostColor
    WinSet, Transparent, % GhostOpacity, ahk_id %GhostHwnd%
    if (!EnableGhostWindow && ghostVisible) {
        Gui, Ghost: Hide
        ghostVisible := false
    }

    if (CurrentDragModKey != "" && CurrentDragModKey != DragModKey)
        Hotkey, %CurrentDragModKey% & LButton, Off, UseErrorLevel
    if (CurrentDragDirectKey != "" && CurrentDragDirectKey != DragDirectKey)
        Hotkey, %CurrentDragDirectKey%, Off, UseErrorLevel
    if (CurrentResizeModKey != "" && CurrentResizeModKey != ResizeModKey)
        Hotkey, %CurrentResizeModKey% & LButton, Off, UseErrorLevel

    ; 动态替换主菜单热键
    if (CurrentMenuHotkey != "" && CurrentMenuHotkey != MenuHotkey)
        Hotkey, %CurrentMenuHotkey%, Off, UseErrorLevel
    if (MenuHotkey != "")
        Hotkey, %MenuHotkey%, ShowDynamicMenu, On, UseErrorLevel
    CurrentMenuHotkey := MenuHotkey

    if (DragModKey != "")
        Hotkey, %DragModKey% & LButton, DoModDrag, On, UseErrorLevel
    if (DragDirectKey != "")
        Hotkey, %DragDirectKey%, DoDirectDrag, On, UseErrorLevel
    if (ResizeModKey != "")
        Hotkey, %ResizeModKey% & LButton, DoResizeDrag, On, UseErrorLevel

    CurrentDragModKey := DragModKey
    CurrentDragDirectKey := DragDirectKey
    CurrentResizeModKey := ResizeModKey

    Label_AutoRun(AutoRun)
    if (ShowTrayIcon)
        Menu, Tray, Icon
    else
        Menu, Tray, NoIcon

    TrayTip, GhostSnap 设置, 配置已应用并即时生效！, 1.5
return

SaveAndRestart:
    GoSub, ApplyConfig
    Reload
return

SettingsGuiClose:
    Gui, Settings:Destroy
return

SyncMenuHotkey:
    GuiControlGet, capturedKey,, Gui_MenuHotkey_Helper
    if (capturedKey != "")
        GuiControl,, Gui_MenuHotkey, %capturedKey%
return
; ===========================================================
; 核心逻辑与钩子部分
; ===========================================================

Cleanup() {
    global HiddenWindows
    ; 退出时释放所有被贴边隐藏的窗口
    For hw, info in HiddenWindows {
        if WinExist("ahk_id " hw) {
            WinMove, ahk_id %hw%, , % info.shownX, % info.shownY, % info.w, % info.h
            if (!info.origTopmost)
                WinSet, Topmost, Off, ahk_id %hw%
        }
    }
    ; 退出时恢复被手动隐藏的窗口
    global HiddenWinsOrder
    DetectHiddenWindows, On
    For i, targetHwnd in HiddenWinsOrder {
        if WinExist("ahk_id " targetHwnd)
            WinShow, ahk_id %targetHwnd%
    }
    DetectHiddenWindows, Off

    ; 退出时恢复鼠标穿透的窗口
    global ClickThroughWinsOrder, ClickThroughWinsMap
    For i, targetHwnd in ClickThroughWinsOrder {
        if WinExist("ahk_id " targetHwnd) {
            WinSet, ExStyle, -0x20, ahk_id %targetHwnd%
            origTrans := ClickThroughWinsMap[targetHwnd].Trans
            if (origTrans != "")
                WinSet, Transparent, %origTrans%, ahk_id %targetHwnd%
            else
                WinSet, Transparent, Off, ahk_id %targetHwnd%
        }
    }

    DllCall("UnhookWinEvent", "Ptr", hookStart)
    DllCall("UnhookWinEvent", "Ptr", hookEnd)
    Gdip_Shutdown(pToken) ; 【新增】脚本退出时统一释放 GDI+
}

HasOverlap(min1, max1, min2, max2, padding:=0) {
    return (max1 + padding >= min2) && (min1 - padding <= max2)
}

IsBlacklisted(hwnd) {
    Loop, Parse, Blacklist, `n, `r
    {
        rule := Trim(A_LoopField)
        if (rule = "")
            continue
        if WinExist(rule " ahk_id " hwnd)
            return true
    }
    return false
}

CheckWindowInList(hwnd, listStr) {
    Loop, Parse, listStr, `n, `r
    {
        rule := Trim(A_LoopField)
        if (rule = "")
            continue
        if WinExist(rule " ahk_id " hwnd)
            return true
    }
    return false
}

IsFullscreen(hwnd) {
    WinGetPos, x, y, w, h, ahk_id %hwnd%
    SysGet, monCount, MonitorCount
    Loop, %monCount% {
        SysGet, mon, Monitor, %A_Index%
        if (x == monLeft && y == monTop && w == (monRight - monLeft) && h == (monBottom - monTop))
            return true
    }
    return false
}

; 检测当前激活状态的是否为全屏窗口（如游戏、电影）
IsActiveWindowFullscreen() {
    hwnd := WinExist("A")
    if (!hwnd)
        return false
    WinGet, style, Style, ahk_id %hwnd%
    if (style & 0x10000000) { ; WS_VISIBLE
        WinGetPos, x, y, w, h, ahk_id %hwnd%
        SysGet, monCount, MonitorCount
        Loop, %monCount% {
            SysGet, mon, Monitor, %A_Index%
            if (x == monLeft && y == monTop && w == (monRight - monLeft) && h == (monBottom - monTop)) {
                WinGetClass, winClass, ahk_id %hwnd%
                ; 排除桌面壁纸等系统默认覆盖物
                if (winClass != "WorkerW" && winClass != "Progman")
                    return true
            }
        }
    }
    return false
}

SetupMoveData:
    WinGet, minMax, MinMax, ahk_id %movingHwnd%
    if (minMax != 0) {
        isMoving := false
        return
    }

    WinGetPos, stdX, stdY, stdW, stdH, ahk_id %movingHwnd%
    GetRealPos(movingHwnd, realX, realY, realW, realH)

    diffX := stdX - realX
    diffY := stdY - realY
    diffW := stdW - realW
    diffH := stdH - realH

    TargetWindows := []
    TargetMonitors := []
    HigherRects := []

    if (EnableScreenEdgeSnap) {
        SysGet, monCount, MonitorCount
        Loop, %monCount% {
            SysGet, mon, MonitorWorkArea, %A_Index%
            TargetMonitors.Push({X: monLeft, Y: monTop, R: monRight, B: monBottom})
        }
    }

    WinGet, id, List
    Loop, %id%
    {
        this_id := id%A_Index%
        if (this_id = movingHwnd or this_id = GhostHwnd)
            continue

        WinGet, style, Style, ahk_id %this_id%
        WinGet, exStyle, ExStyle, ahk_id %this_id%
        if !(style & 0x10000000) || (style & 0x08000000)
            continue
        if (exStyle & 0x00000020) || (exStyle & 0x00000080)
            continue
        if IsBlacklisted(this_id)
            continue

        WinGetTitle, title, ahk_id %this_id%
        if (title = "")
            continue

        if (GetRealPos(this_id, tX, tY, tW, tH)) {
            tR := tX + tW, tB := tY + tH
            isCovered := false
            For index, hRect in HigherRects {
                if (tX >= hRect.X && tY >= hRect.Y && tR <= hRect.R && tB <= hRect.B) {
                    isCovered := true
                    break
                }
            }
            if (isCovered)
                continue

            TargetWindows.Push({hwnd: this_id, X: tX, Y: tY, W: tW, H: tH, R: tR, B: tB})
            HigherRects.Push({X: tX, Y: tY, R: tR, B: tB})
        }
    }

    startMoveX := realX
    startMoveY := realY
    ChainedGroup := []

    if (EnableChaining && GetKeyState(ChainModKey, "P")) {
        For index, target in TargetWindows {
            xOverlap := HasOverlap(realX, realX + realW, target.X, target.R, 2)
            yOverlap := HasOverlap(realY, realY + realH, target.Y, target.B, 2)

            isAdjacent := false
            if (yOverlap && (Abs(realX + realW - target.X) <= SnapDistance || Abs(realX - target.R) <= SnapDistance))
                isAdjacent := true
            else if (xOverlap && (Abs(realY + realH - target.Y) <= SnapDistance || Abs(realY - target.B) <= SnapDistance))
                isAdjacent := true

            if (isAdjacent) {
                WinGetPos, cStdX, cStdY, cStdW, cStdH, % "ahk_id " target.hwnd
                cDiffX := cStdX - target.X
                cDiffY := cStdY - target.Y
                ChainedGroup.Push({hwnd: target.hwnd, sX: target.X, sY: target.Y, dX: cDiffX, dY: cDiffY})
                target.isChained := true
            }
        }
    }
return

OnMoveStart(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    if (idObject != 0 or !hwnd)
        return
    if (hwnd = GhostHwnd)
        return
    if (isMoving)
        return
    if IsFullscreen(hwnd)
        return

    ; --- 若当前窗口处于贴边隐藏状态，处理调整大小和拖出 ---
    global HiddenWindows
    global wasHiddenHwnd
    if (HiddenWindows.HasKey(hwnd)) {
        CoordMode, Mouse, Screen
        MouseGetPos, mX, mY
        hit := 0
        ; 使用 SendMessageTimeout 安全检测鼠标正在交互的窗口区域 (是否为边框拖拽调整大小)
        DllCall("SendMessageTimeout", "Ptr", hwnd, "UInt", 0x84, "Ptr", 0, "Ptr", (mY << 16)|(mX & 0xFFFF), "UInt", 2, "UInt", 100, "Ptr*", hit)
        isResize := (hit >= 10 && hit <= 17)

        if (isResize) {
            ; 若为调整大小，标记正在调整并放行，不破坏隐藏逻辑
            HiddenWindows[hwnd].isResizing := true
            wasHiddenHwnd := 0
            return
        } else {
            ; 拖动标题栏等，解除隐藏，标记记忆变量
            wasHiddenHwnd := hwnd
            if (!HiddenWindows[hwnd].origTopmost)
                WinSet, Topmost, Off, ahk_id %hwnd%
            HiddenWindows.Delete(hwnd)
        }
    } else {
        wasHiddenHwnd := 0
    }

    movingHwnd := hwnd
    dragMode := "system"
    triggerKey := "LButton"
    isMoving := true

    Gosub, SetupMoveData

    if (isMoving)
        SetTimer, TrackMove, 15
}

OnMoveEnd(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    if (idObject != 0)
        return

    ; --- 若刚刚完成了隐藏窗口的大小调整，刷新边界判定范围 ---
    if (HiddenWindows.HasKey(hwnd) && HiddenWindows[hwnd].isResizing) {
        HiddenWindows[hwnd].isResizing := false
        GetRealPos(hwnd, rX, rY, rW, rH)
        WinGetPos, sX, sY, sW, sH, ahk_id %hwnd%
        diffX := sX - rX, diffY := sY - rY
        diffW := sW - rW, diffH := sH - rH
        realW := sW - diffW
        realH := sH - diffH

        info := HiddenWindows[hwnd]
        info.shownX := sX
        info.shownY := sY
        info.w := sW
        info.h := sH
        info.realW := realW
        info.realH := realH

        info.hiddenX := sX
        info.hiddenY := sY

        edge := info.edge
        ; 根据新的宽高，重新计算应该隐藏缩进去的坐标系
        if (edge == "Top")
            info.hiddenY := sY - realH + AutoHideProtrude
        else if (edge == "Bottom")
            info.hiddenY := sY + realH - AutoHideProtrude
        else if (edge == "Left")
            info.hiddenX := sX - realW + AutoHideProtrude
        else if (edge == "Right")
            info.hiddenX := sX + realW - AutoHideProtrude

        return ; 调整大小直接返回，不触发后续常规吸附计算
    }

    if (hwnd != movingHwnd)
        return
    if (dragMode = "manual")
        return
    SetTimer, TrackMove, Off
    SetTimer, ExecEndMove, -1          ;使用异步定时器脱钩执行，防止 Hook 线程阻塞
}

DoModDrag:
    triggerKey := "LButton"
    dragTriggerType := "Mod"
    Gosub, StartManualDrag
return

DoDirectDrag:
    triggerKey := RegExReplace(A_ThisHotkey, "^[~*$]+")
    dragTriggerType := "Direct"
    Gosub, StartManualDrag
return

StartManualDrag:
    CoordMode, Mouse, Screen
    MouseGetPos, mX, mY, hoverHwnd

    if (!hoverHwnd or hoverHwnd = GhostHwnd)
        return

    if IsFullscreen(hoverHwnd)
        return

    if IsBlacklisted(hoverHwnd)
        return

    if (dragTriggerType = "Mod" && CheckWindowInList(hoverHwnd, DragModBlacklist))
        return

    if (dragTriggerType = "Direct" && CheckWindowInList(hoverHwnd, DragDirectBlacklist))
        return

    WinGet, minMax, MinMax, ahk_id %hoverHwnd%
    if (minMax != 0) {
        if (!AllowMaximizedWin || minMax == -1) ; 不允许或为最小化时直接返回
            return
        WinRestore, ahk_id %hoverHwnd%
        Sleep, 50 ; 给系统动画一点缓冲时间，防止坐标计算偏差
    }

    ; --- 解除被拖拽窗口的隐藏状态 ---
    global HiddenWindows
    global wasHiddenHwnd
    if (HiddenWindows.HasKey(hoverHwnd)) {
        wasHiddenHwnd := hoverHwnd
        if (!HiddenWindows[hoverHwnd].origTopmost)
            WinSet, Topmost, Off, ahk_id %hoverHwnd%
        HiddenWindows.Delete(hoverHwnd)
    } else {
        wasHiddenHwnd := 0
    }

    WinActivate, ahk_id %hoverHwnd%

    GetRealPos(hoverHwnd, rX, rY, rW, rH)
    dragMouseOffsetX := rX - mX
    dragMouseOffsetY := rY - mY

    movingHwnd := hoverHwnd
    dragMode := "manual"
    isMoving := true

    Gosub, SetupMoveData

    if (isMoving)
        SetTimer, TrackMove, 15
return

TrackMove:
    if (!isMoving || !movingHwnd)
        return

    if !GetKeyState(triggerKey, "P") {
        SetTimer, TrackMove, Off
        SetTimer, ExecEndMove, -1          ;同步改为异步执行
        return
    }

    if (dragMode = "manual") {
        CoordMode, Mouse, Screen
        MouseGetPos, cmX, cmY
        mX := cmX + dragMouseOffsetX
        mY := cmY + dragMouseOffsetY
        WinMove, ahk_id %movingHwnd%, , % mX + diffX, % mY + diffY

        WinGetPos, cStdX, cStdY, cStdW, cStdH, ahk_id %movingHwnd%
        mW := cStdW - diffW
        mH := cStdH - diffH
    } else {
        WinGetPos, cStdX, cStdY, cStdW, cStdH, ahk_id %movingHwnd%
        mX := cStdX - diffX
        mY := cStdY - diffY
        mW := cStdW - diffW
        mH := cStdH - diffH
    }

    if (ChainedGroup.Length() > 0) {
        deltaX := mX - startMoveX
        deltaY := mY - startMoveY
        For index, child in ChainedGroup {
            WinMove, % "ahk_id " child.hwnd, , % child.sX + deltaX + child.dX, % child.sY + deltaY + child.dY
        }
    }

    togglePressed := (SnapToggleKey != "") ? GetKeyState(SnapToggleKey, "P") : false
    syncPressed := (EnableSmartSync && SmartSyncKey != "") ? GetKeyState(SmartSyncKey, "P") : false

    ; 识别是否需要触发贴边隐藏（含记忆贴边判定）
    hideIntent := (AutoHideModKey != "" && GetKeyState(AutoHideModKey, "P")) || (movingHwnd == wasHiddenHwnd)

    if (dragMode = "manual") {
        suspendSnapping := togglePressed && !syncPressed
    } else {
        if (syncPressed) {
            suspendSnapping := false
        } else {
            suspendSnapping := RequireKeyToSnap ? !togglePressed : togglePressed
        }
    }

    ; 如果用户触发了贴边隐藏意图，则无视反向模式的挂起，强制进行边缘计算
    if (suspendSnapping && !hideIntent) {
        willSnap := false
        if (ghostVisible) {
            Gui, Ghost: Hide
            ghostVisible := false
        }
        return
    }

    mRight := mX + mW
    mBottom := mY + mH

    newX := mX, newY := mY
    snappedX := false, snappedY := false
    syncTargetX := 0, syncTargetY := 0

    effSnapDist := hideIntent ? AutoHideDistance : SnapDistance
    effBreakDist := hideIntent ? AutoHideDistance : BreakoutDistance

    currSnapDistX := (willSnap && snappedX) ? effBreakDist : effSnapDist
    currSnapDistY := (willSnap && snappedY) ? effBreakDist : effSnapDist
    minDx := currSnapDistX + 1
    minDy := currSnapDistY + 1

    For index, target in TargetWindows {
        if (target.isChained)
            continue

        yOverlap := HasOverlap(mY, mBottom, target.Y, target.B, SnapDistance)
        xOverlap := HasOverlap(mX, mRight, target.X, target.R, SnapDistance)

        if (yOverlap) {
            edgesX := [{d: Abs(mRight - target.X), p: target.X - mW}
                , {d: Abs(mX - target.R), p: target.R}
                , {d: Abs(mX - target.X), p: target.X}
                , {d: Abs(mRight - target.R), p: target.R - mW}]
            For i, e in edgesX {
                if (e.d <= currSnapDistX && e.d < minDx) {
                    minDx := e.d, newX := e.p, snappedX := true, syncTargetX := target
                }
            }
        }
        if (xOverlap) {
            edgesY := [{d: Abs(mBottom - target.Y), p: target.Y - mH}
                , {d: Abs(mY - target.B), p: target.B}
                , {d: Abs(mY - target.Y), p: target.Y}
                , {d: Abs(mBottom - target.B), p: target.B - mH}]
            For i, e in edgesY {
                if (e.d <= currSnapDistY && e.d < minDy) {
                    minDy := e.d, newY := e.p, snappedY := true, syncTargetY := target
                }
            }
        }
    }

    For index, mon in TargetMonitors {
        eX := [{d: Abs(mX - mon.X), p: mon.X}
            , {d: Abs(mRight - mon.R), p: mon.R - mW}]
        eY := [{d: Abs(mY - mon.Y), p: mon.Y}
            , {d: Abs(mBottom - mon.B), p: mon.B - mH}]

        For i, e in eX {
            if (e.d <= currSnapDistX && e.d < minDx) {
                minDx := e.d, newX := e.p, snappedX := true, syncTargetX := mon
            }
        }
        For i, e in eY {
            if (e.d <= currSnapDistY && e.d < minDy) {
                minDy := e.d, newY := e.p, snappedY := true, syncTargetY := mon
            }
        }
    }

    if (StrictSingleAxisSnap && snappedX && snappedY) {
        if (minDx <= minDy) {
            snappedY := false, newY := mY, syncTargetY := 0
        } else {
            snappedX := false, newX := mX, syncTargetX := 0
        }
    }

    if (snappedX || snappedY) {
        destX := newX
        destY := newY
        willSnap := true

        if (EnableGhostWindow) {
            ghostX := newX, ghostY := newY, ghostW := mW, ghostH := mH

            if (EnableSmartSync && SmartSyncKey != "" && GetKeyState(SmartSyncKey, "P")) {
                if (snappedX && syncTargetX) {
                    ghostY := syncTargetX.Y
                    ghostH := syncTargetX.B ? (syncTargetX.B - syncTargetX.Y) : 0
                }
                if (snappedY && syncTargetY) {
                    ghostX := syncTargetY.X
                    ghostW := syncTargetY.R ? (syncTargetY.R - syncTargetY.X) : 0
                }
            }

            if (!ghostVisible) {
                Gui, Ghost: Show, x%ghostX% y%ghostY% w%ghostW% h%ghostH% NA
                ghostVisible := true
            } else {
                WinMove, ahk_id %GhostHwnd%, , %ghostX%, %ghostY%, %ghostW%, %ghostH%
            }
        }
    } else {
        willSnap := false
        if (ghostVisible) {
            Gui, Ghost: Hide
            ghostVisible := false
        }
    }
return

ForceEndMove:
    isMoving := false

    if (ghostVisible) {
        Gui, Ghost: Hide
        ghostVisible := false
    }

    if (willSnap && movingHwnd) {
        WinGetPos, currStdX, currStdY, currStdW, currStdH, ahk_id %movingHwnd%
        currX := currStdX
        currY := currStdY

        finalX := destX + diffX
        finalY := destY + diffY
        finalW := currStdW
        finalH := currStdH

        if (EnableSmartSync && SmartSyncKey != "" && GetKeyState(SmartSyncKey, "P")) {
            if (snappedX && syncTargetX) {
                finalY := syncTargetX.Y + diffY
                finalH := (syncTargetX.B ? (syncTargetX.B - syncTargetX.Y) : syncTargetX.H) + diffH
            }
            if (snappedY && syncTargetY) {
                finalX := syncTargetY.X + diffX
                finalW := (syncTargetY.R ? (syncTargetY.R - syncTargetY.X) : syncTargetY.W) + diffW
            }
        }

        currRealX := currX - diffX
        currRealY := currY - diffY
        finalRealX := finalX - diffX
        finalRealY := finalY - diffY

        ; ===== 条件平滑过渡动画渲染 =====
        if (EnableSnapAnimation && SnapAnimSteps > 1) {
            steps := SnapAnimSteps
            Loop % steps {
                progress := A_Index / steps
                curFinalX := currX + (finalX - currX) * progress
                curFinalY := currY + (finalY - currY) * progress
                curFinalW := currStdW + (finalW - currStdW) * progress
                curFinalH := currStdH + (finalH - currStdH) * progress

                WinMove, ahk_id %movingHwnd%, , %curFinalX%, %curFinalY%, %curFinalW%, %curFinalH%

                if (ChainedGroup.Length() > 0) {
                    curRealXProg := currRealX + (finalRealX - currRealX) * progress
                    curRealYProg := currRealY + (finalRealY - currRealY) * progress
                    curDeltaX := curRealXProg - startMoveX
                    curDeltaY := curRealYProg - startMoveY
                    For index, child in ChainedGroup {
                        WinMove, % "ahk_id " child.hwnd, , % child.sX + curDeltaX + child.dX, % child.sY + curDeltaY + child.dY
                    }
                }
                Sleep, %SnapAnimSleep%
            }
        }

        ; 终帧兜底精确对齐
        WinMove, ahk_id %movingHwnd%, , %finalX%, %finalY%, %finalW%, %finalH%

        if (ChainedGroup.Length() > 0) {
            finalDeltaX := finalRealX - startMoveX
            finalDeltaY := finalRealY - startMoveY
            For index, child in ChainedGroup {
                WinMove, % "ahk_id " child.hwnd, , % child.sX + finalDeltaX + child.dX, % child.sY + finalDeltaY + child.dY
            }
        }

        ; =======================================================
        ; 贴边隐藏检测与注册
        ; =======================================================
        hideIntent := (AutoHideModKey != "" && GetKeyState(AutoHideModKey, "P")) || (movingHwnd == wasHiddenHwnd)

        if (hideIntent) {
            edge := ""
            realFinalW := finalW - diffW
            realFinalH := finalH - diffH

            ; 使用物理屏幕边界进行判定，解决最大化窗口干扰问题
            SysGet, monCount, MonitorCount
            Loop, %monCount% {
                SysGet, mon, MonitorWorkArea, %A_Index%

                ; 计算各边距离
                distT := Abs(finalY - diffY - monTop)
                distB := Abs(finalY - diffY + realFinalH - monBottom)
                distL := Abs(finalX - diffX - monLeft)
                distR := Abs(finalX - diffX + realFinalW - monRight)

                ; 判定是否贴边 (增加少许容错至5像素，由于前方已触发贴边吸附，距离通常为0)
                edgeT := (distT <= 5)
                edgeB := (distB <= 5)
                edgeL := (distL <= 5)
                edgeR := (distR <= 5)

                ; 判定逻辑：优先检查设置内的边缘角优先级
                if (AutoHideEdgePriority == "2") { ; 距离优先 (使用松开鼠标时的真实坐标判断意图)
                    rawDistT := Abs(currRealY - monTop)
                    rawDistB := Abs(currRealY + realFinalH - monBottom)
                    rawDistL := Abs(currRealX - monLeft)
                    rawDistR := Abs(currRealX + realFinalW - monRight)

                    minDist := 999999
                    if (edgeT && rawDistT < minDist)
                        minDist := rawDistT, edge := "Top"
                    if (edgeB && rawDistB < minDist)
                        minDist := rawDistB, edge := "Bottom"
                    if (edgeL && rawDistL < minDist)
                        minDist := rawDistL, edge := "Left"
                    if (edgeR && rawDistR < minDist)
                        minDist := rawDistR, edge := "Right"

                    ; 极端情况兜底：如果大力拖拽直接把鼠标怼到了死角，导致距离完全相等(比如都为0)
                    ; 此时引入鼠标的物理位置作为最后决胜条件
                    tieCount := 0
                    if (edgeT && rawDistT == minDist)
                        tieCount++
                    if (edgeB && rawDistB == minDist)
                        tieCount++
                    if (edgeL && rawDistL == minDist)
                        tieCount++
                    if (edgeR && rawDistR == minDist)
                        tieCount++

                    if (tieCount > 1) {
                        CoordMode, Mouse, Screen
                        MouseGetPos, mX, mY
                        mouseDistMin := 999999
                        if (edgeT && rawDistT == minDist) {
                            md := Abs(mY - monTop)
                            if (md < mouseDistMin)
                                mouseDistMin := md, edge := "Top"
                        }
                        if (edgeB && rawDistB == minDist) {
                            md := Abs(mY - monBottom)
                            if (md < mouseDistMin)
                                mouseDistMin := md, edge := "Bottom"
                        }
                        if (edgeL && rawDistL == minDist) {
                            md := Abs(mX - monLeft)
                            if (md < mouseDistMin)
                                mouseDistMin := md, edge := "Left"
                        }
                        if (edgeR && rawDistR == minDist) {
                            md := Abs(mX - monRight)
                            if (md < mouseDistMin)
                                mouseDistMin := md, edge := "Right"
                        }
                    }
                } else if (AutoHideEdgePriority == "1") { ; 左右优先
                    if (edgeL)
                        edge := "Left"
                    else if (edgeR)
                        edge := "Right"
                    else if (edgeT)
                        edge := "Top"
                    else if (edgeB)
                        edge := "Bottom"
                } else { ; 上下优先
                    if (edgeT)
                        edge := "Top"
                    else if (edgeB)
                        edge := "Bottom"
                    else if (edgeL)
                        edge := "Left"
                    else if (edgeR)
                        edge := "Right"
                }

                if (edge != "") {
                    break
                }
            }

            if (edge != "") {
                ; 使用真实去除阴影的宽高来计算隐藏后的精准坐标
                hiddenX := finalX, hiddenY := finalY
                if (edge == "Top")
                    hiddenY := finalY - realFinalH + AutoHideProtrude
                else if (edge == "Bottom")
                    hiddenY := finalY + realFinalH - AutoHideProtrude
                else if (edge == "Left")
                    hiddenX := finalX - realFinalW + AutoHideProtrude
                else if (edge == "Right")
                    hiddenX := finalX + realFinalW - AutoHideProtrude

                ; 记录窗口原有样式与位置
                WinGet, exStyle, ExStyle, ahk_id %movingHwnd%
                origTopmost := (exStyle & 0x8) ? 1 : 0

                HiddenWindows[movingHwnd] := { edge: edge
                    , state: "hidden"
                    , hoverTime: 0
                    , leaveTime: 0
                    , origTopmost: origTopmost
                    , shownX: finalX, shownY: finalY
                    , hiddenX: hiddenX, hiddenY: hiddenY
                    , w: finalW, h: finalH
                    , realW: realFinalW, realH: realFinalH
                    , isFullyHidden: false
                    , isResizing: false }

                ; 智能兼容：动态检测当前显示器的任务栏位置，只对无任务栏的一侧强制置顶
                tbEdge := GetTaskbarEdgeByPos(finalX + finalW/2, finalY + finalH/2)
                if (AutoHideTopmost || edge != tbEdge)
                    WinSet, Topmost, On, ahk_id %movingHwnd%
                else if (!origTopmost)
                    WinSet, Topmost, Off, ahk_id %movingHwnd%

                ; 启动监视器
                SetTimer, AutoHideTracker, 50

                ; 强制触发一次隐藏动画进行收缩
                DoAnimateWindow(movingHwnd, finalX, finalY, hiddenX, hiddenY, finalW, finalH)
            }
        }
        willSnap := false
    }

    wasHiddenHwnd := 0
    movingHwnd := 0
return

; ===========================================================
; 贴边隐藏辅助：执行平滑推拉动画 (采用独立配置)
; ===========================================================
DoAnimateWindow(hwnd, startX, startY, endX, endY, w, h) {
    global EnableAutoHideAnim, AutoHideAnimSteps, AutoHideAnimSleep
    if (EnableAutoHideAnim && AutoHideAnimSteps > 1) {
        steps := AutoHideAnimSteps
        Loop % steps {
            progress := A_Index / steps
            curX := startX + (endX - startX) * progress
            curY := startY + (endY - startY) * progress
            WinMove, ahk_id %hwnd%, , %curX%, %curY%, %w%, %h%
            Sleep, %AutoHideAnimSleep%
        }
    }
    ; 终帧兜底精确对齐
    WinMove, ahk_id %hwnd%, , %endX%, %endY%, %w%, %h%
}

; ===========================================================
; 贴边隐藏监视定时器 (负责鼠标悬停及移出判断)
; ===========================================================
AutoHideTracker:
    hasItems := false
    CoordMode, Mouse, Screen
    MouseGetPos, mX, mY
    toDelete := []

    ; 全局检测当前系统是否有全屏应用处于焦点（防打扰机制）
    global AutoHideFullscreenHide
    isFullscreenNow := (AutoHideFullscreenHide && IsActiveWindowFullscreen())

    For hw, info in HiddenWindows {
        hasItems := true
        ; 如果窗口已经被销毁，准备从字典中剔除
        if !WinExist("ahk_id " hw) {
            toDelete.Push(hw)
            continue
        }

        ; 如果窗口被最大化，则退出贴边隐藏机制
        WinGet, minMax, MinMax, ahk_id %hw%
        if (minMax = 1) {
            if (!info.origTopmost)
                WinSet, Topmost, Off, ahk_id %hw%
            toDelete.Push(hw)
            continue
        }

        if (info.state == "hidden") {
            ; --- 全屏完全隐藏逻辑 ---
            targetX := info.hiddenX
            targetY := info.hiddenY

            if (isFullscreenNow) {
                targetX := info.shownX
                targetY := info.shownY
                if (info.edge == "Top")
                    targetY := info.shownY - info.realH
                else if (info.edge == "Bottom")
                    targetY := info.shownY + info.realH
                else if (info.edge == "Left")
                    targetX := info.shownX - info.realW
                else if (info.edge == "Right")
                    targetX := info.shownX + info.realW
            }

            if (isFullscreenNow && !info.isFullyHidden) {
                info.isFullyHidden := true
                DoAnimateWindow(hw, info.hiddenX, info.hiddenY, targetX, targetY, info.w, info.h)
            } else if (!isFullscreenNow && info.isFullyHidden) {
                info.isFullyHidden := false
                WinGetPos, currX, currY, , , ahk_id %hw%
                DoAnimateWindow(hw, currX, currY, info.hiddenX, info.hiddenY, info.w, info.h)
            }

            ; 隐藏状态：鼠标移入"凸出部分"（如果完全隐藏则不响应悬停呼出）
            if (!info.isFullyHidden && mX >= info.hiddenX && mX <= info.hiddenX + info.w && mY >= info.hiddenY && mY <= info.hiddenY + info.h) {
                info.hoverTime += 50
                if (info.hoverTime >= AutoHideShowDelay) {
                    info.state := "shown"
                    info.hoverTime := 0
                    info.leaveTime := 0

                    ; 呼出时，如果不要求强制置顶，则剥夺强制置顶，恢复它原有的属性
                    if (!AutoHideTopmost && !info.origTopmost)
                        WinSet, Topmost, Off, ahk_id %hw%

                    DoAnimateWindow(hw, info.hiddenX, info.hiddenY, info.shownX, info.shownY, info.w, info.h)

                    if (AutoHideFocus)
                        WinActivate, ahk_id %hw%
                }
            } else {
                info.hoverTime := 0
            }
        }
        else if (info.state == "shown") {

            ; --- 防调整大小/防误触异常隐藏 ---
            ; 1. info.isResizing: 由系统钩子判断出用户正在拖拽边框调整大小
            ; 2. GetKeyState("LButton", "P") && WinActive: 用户正在按住左键操作这个激活的窗口（比如拖拽滚动条，框选文字等）
            ; 满足任一条件时，直接重置移出倒计时，暂停隐藏动作！
            if (info.isResizing || (GetKeyState("LButton", "P") && WinActive("ahk_id " hw))) {
                info.leaveTime := 0
                continue
            }

            ; 显示状态：计算离开区域的边界。如果是贴边隐藏，离开判定框必须向屏幕外围无限延伸，解决经过任务栏疯狂来回隐藏/抽搐的Bug
            tol := AutoHideTolerance
            leaveLeft := info.shownX - tol
            leaveRight := info.shownX + info.w + tol
            leaveTop := info.shownY - tol
            leaveBottom := info.shownY + info.h + tol

            if (info.edge == "Top")
                leaveTop := -99999
            else if (info.edge == "Bottom")
                leaveBottom := 99999
            else if (info.edge == "Left")
                leaveLeft := -99999
            else if (info.edge == "Right")
                leaveRight := 99999

            if (mX < leaveLeft || mX > leaveRight || mY < leaveTop || mY > leaveBottom) {
                info.leaveTime += 50
                if (info.leaveTime >= AutoHideHideDelay) {
                    info.state := "hidden"
                    info.leaveTime := 0
                    info.hoverTime := 0

                    ; 1. 先执行隐藏动画。如果用户刚刚激活了其他窗口，它能在背后平滑隐藏，避免置顶跳闪
                    DoAnimateWindow(hw, info.shownX, info.shownY, info.hiddenX, info.hiddenY, info.w, info.h)

                    ; 2. 动画完全结束后，再将边缘置顶，保证后续能正常悬停触发
                    tbEdge := GetTaskbarEdgeByPos(info.shownX + info.w/2, info.shownY + info.h/2)
                    if (AutoHideTopmost || info.edge != tbEdge)
                        WinSet, Topmost, On, ahk_id %hw%
                    else if (!info.origTopmost)
                        WinSet, Topmost, Off, ahk_id %hw%

                    ; 3. 失去焦点逻辑处理（延迟到最后交接焦点更平滑）
                    if (AutoHideFocus && WinActive("ahk_id " hw)) {
                        MouseGetPos,,, underHwnd
                        if (underHwnd && underHwnd != hw)
                            WinActivate, ahk_id %underHwnd%
                        else
                            WinActivate, ahk_class Progman
                    }
                }
            } else {
                info.leaveTime := 0
            }
        }
    }

    ; 安全地清除无效窗口记录
    For i, del in toDelete
        HiddenWindows.Delete(del)

    ; 字典清空后关闭计时器节约性能
    if (!hasItems)
        SetTimer, AutoHideTracker, Off
return

GetRealPos(hwnd, ByRef x, ByRef y, ByRef w, ByRef h) {
    VarSetCapacity(rect, 16, 0)
    if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", &rect, "UInt", 16) = 0) {
        x := NumGet(rect, 0, "Int"), y := NumGet(rect, 4, "Int")
        w := NumGet(rect, 8, "Int") - x, h := NumGet(rect, 12, "Int") - y
        return true
    }
    WinGetPos, x, y, w, h, ahk_id %hwnd%
    return true
}

; ===========================================================
; 系统调色盘与配置文件读写函数
; ===========================================================

ChooseColor(DefaultColorHex) {
    StructSize := (A_PtrSize == 8) ? 72 : 36
    VarSetCapacity(ChooseColorStruct, StructSize, 0)
    VarSetCapacity(CustColors, 64, 0)

    NumPut(StructSize, ChooseColorStruct, 0, "UInt")
    NumPut(A_ScriptHwnd, ChooseColorStruct, A_PtrSize, "Ptr")

    r := "0x" SubStr(DefaultColorHex, 1, 2)
    g := "0x" SubStr(DefaultColorHex, 3, 2)
    b := "0x" SubStr(DefaultColorHex, 5, 2)
    BGR := (b << 16) | (g << 8) | r

    NumPut(BGR, ChooseColorStruct, (A_PtrSize == 8) ? 24 : 12, "UInt")
    NumPut(&CustColors, ChooseColorStruct, (A_PtrSize == 8) ? 32 : 16, "Ptr")
    NumPut(0x103, ChooseColorStruct, (A_PtrSize == 8) ? 40 : 20, "UInt")

    if DllCall("comdlg32\ChooseColor", "Ptr", &ChooseColorStruct) {
        Color := NumGet(ChooseColorStruct, (A_PtrSize == 8) ? 24 : 12, "UInt")
        return Format("{:02X}{:02X}{:02X}", Color & 0xFF, (Color >> 8) & 0xFF, (Color >> 16) & 0xFF)
    }
    return ""
}

Var_Read(rValue,defVar:="",Section名:="基础配置",Config:="个人配置.ini",是否删除默认项:="是",为空时是否重置为默认值:="是"){
    IniRead, regVar,%Config%, %Section名%, %rValue%,% defVar ? defVar : A_Space
    if(regVar!=""){
        regVar := StrReplace(regVar, "[CRLF]", "`n")
        if(defVar!="" && regVar=defVar){
            if (是否删除默认项 = "是")
                IniDelete, %Config%, %Section名%, %rValue%
            return defVar
        }else
            return regVar
    }else{
        if (是否删除默认项 = "是")
            IniDelete, %Config%, %Section名%, %rValue%
        if (为空时是否重置为默认值 = "是")
            return defVar
        return ""
    }
}

Var_Set(vGui, var, sz, Section名:="基础配置", Config:="个人配置.ini"){
    StringCaseSense, On
    vGui_safe := StrReplace(vGui, "`r`n", "[CRLF]")
    vGui_safe := StrReplace(vGui_safe, "`n", "[CRLF]")

    var_safe := StrReplace(var, "`r`n", "[CRLF]")
    var_safe := StrReplace(var_safe, "`n", "[CRLF]")

    if(vGui_safe != var_safe)
        IniWrite,%vGui_safe%,%Config%, %Section名%, %sz%
    Else
        IniDelete,%Config%,%Section名%, %sz%
    StringCaseSense, Off
}

Label_AutoRun(Auto_Launch:="0"){
    RegRead, Auto_Launch_reg, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GhostSnap
    Auto_Launch_reg := (Auto_Launch_reg = A_ScriptFullPath) ? 1 : 0

    If(Auto_Launch != Auto_Launch_reg){
        If(Auto_Launch){
            RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GhostSnap, %A_ScriptFullPath%
        }Else{
            RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GhostSnap
        }
    }
}

; ===========================================================
; 辅助函数：智能检测窗口中心点所在显示器的任务栏边缘位置
; ===========================================================
GetTaskbarEdgeByPos(cx, cy) {
    SysGet, monCount, MonitorCount
    Loop, %monCount% {
        SysGet, mon, Monitor, %A_Index%
        ; 寻找当前坐标坐落于哪个物理显示器
        if (cx >= monLeft && cx <= monRight && cy >= monTop && cy <= monBottom) {
            SysGet, work, MonitorWorkArea, %A_Index%
            ; 对比物理边界与工作区边界，找出被任务栏占据的方向
            if (workBottom < monBottom)
                return "Bottom"
            if (workTop > monTop)
                return "Top"
            if (workLeft > monLeft)
                return "Left"
            if (workRight < monRight)
                return "Right"
            return "" ; 该显示器无任务栏遮挡
        }
    }
    return "Bottom" ; 兜底默认
}

; 新增函数：将还原列表持久化保存到 INI
SaveRestoreListToIni() {
    global SettingsDir, RestoreOrder, OrigWinSizes
    str := ""
    For i, hw in RestoreOrder {
        if (OrigWinSizes.HasKey(hw)) {
            str .= hw "," OrigWinSizes[hw].W "," OrigWinSizes[hw].H "|"
        }
    }
    IniWrite, %str%, %SettingsDir%, 基础配置, SavedWinSizes
}

SaveHiddenListToIni() {
    global SettingsDir, HiddenWinsOrder, HiddenWinsMap
    str := ""
    For i, hw in HiddenWinsOrder {
        if (HiddenWinsMap.HasKey(hw)) {
            str .= hw "|"
        }
    }
    IniWrite, %str%, %SettingsDir%, 基础配置, SavedHiddenWins
}

SaveClickThroughListToIni() {
    global SettingsDir, ClickThroughWinsOrder, ClickThroughWinsMap
    str := ""
    For i, hw in ClickThroughWinsOrder {
        if (ClickThroughWinsMap.HasKey(hw)) {
            str .= hw "," ClickThroughWinsMap[hw].Trans "|"
        }
    }
    IniWrite, %str%, %SettingsDir%, 基础配置, SavedClickThroughWins
}
; ===========================================================
; 任意位置拖拽调整窗口大小逻辑
; ===========================================================
global isResizingWin := false
global resizeHwnd := 0
global resizeStartX := 0, resizeStartY := 0
global resizeOrigStdW := 0, resizeOrigStdH := 0

DoResizeDrag:
    CoordMode, Mouse, Screen
    MouseGetPos, mX, mY, hoverHwnd

    if (!hoverHwnd or hoverHwnd = GhostHwnd)
        return
    if IsFullscreen(hoverHwnd)
        return
    if IsBlacklisted(hoverHwnd)
        return

    WinGet, minMax, MinMax, ahk_id %hoverHwnd%
    if (minMax != 0) {
        if (!AllowMaximizedWin || minMax == -1)
            return
        WinRestore, ahk_id %hoverHwnd%
        Sleep, 50
    }

    ; 临时解除贴边隐藏判定 (复用原有的防冲突逻辑)
    global HiddenWindows
    global wasHiddenHwnd
    if (HiddenWindows.HasKey(hoverHwnd)) {
        wasHiddenHwnd := hoverHwnd
        if (!HiddenWindows[hoverHwnd].origTopmost)
            WinSet, Topmost, Off, ahk_id %hoverHwnd%
        HiddenWindows.Delete(hoverHwnd)
    } else {
        wasHiddenHwnd := 0
    }

    WinActivate, ahk_id %hoverHwnd%

    ; 记录初始鼠标位置和窗口标准宽高
    WinGetPos, sX, sY, sW, sH, ahk_id %hoverHwnd%
    if (!OrigWinSizes.HasKey(hoverHwnd)) {
        OrigWinSizes[hoverHwnd] := {W: sW, H: sH}
        RestoreOrder.Push(hoverHwnd)

        ; 如果超过了最大数量限制，踢出最早记录的一个（FIFO）
        while (RestoreOrder.Length() > MaxRestoreCount) {
            oldHwnd := RestoreOrder.RemoveAt(1)
            OrigWinSizes.Delete(oldHwnd)
        }

        Gosub, UpdateRestoreMenu
        SaveRestoreListToIni()  ; 记录变化，写入 INI
    }
    resizeOrigStdW := sW
    resizeOrigStdH := sH
    resizeStartX := mX
    resizeStartY := mY
    resizeHwnd := hoverHwnd
    isResizingWin := true

    SetTimer, TrackResize, 15
return

TrackResize:
    if (!isResizingWin || !resizeHwnd)
        return

    ; 鼠标左键松开则停止调整
    if !GetKeyState("LButton", "P") {
        SetTimer, TrackResize, Off
        isResizingWin := false
        resizeHwnd := 0
        return
    }

    CoordMode, Mouse, Screen
    MouseGetPos, mX, mY

    ; 通过鼠标移动的偏移量直接计算宽高差值
    newW := resizeOrigStdW + (mX - resizeStartX)
    newH := resizeOrigStdH + (mY - resizeStartY)

    ; 限制最小尺寸，防止由于负数或太小导致窗口显示异常/崩溃
    if (newW < 80)
        newW := 80
    if (newH < 80)
        newH := 80

    WinMove, ahk_id %resizeHwnd%, , , , %newW%, %newH%
return

; ===========================================================
; 动态菜单核心解析与构建引擎
; ===========================================================
BuildDynamicMenu(iniPath) {
    global DynamicMenuActions, GdipMenuData
    FileRead, iniContent, %iniPath%
    if (ErrorLevel)
        return

    MenuStack := []
    MenuStack[1] := "CustomMenu_Level1"
    CurrentMenu := "CustomMenu_Level1"
    PendingSubmenus := {}
    MenuNeedsBreak := {}
    MenuCounts := {}

    ; 初始化 GDI+ 数据根节点
    GdipMenuData := {}

    Loop, Parse, iniContent, `n, `r
    {
        line := Trim(A_LoopField)
        if (line == "" || SubStr(line, 1, 1) == ";")
            continue

        level := 0
        while (SubStr(line, level + 1, 1) == "-")
            level++

        lineContent := Trim(SubStr(line, level + 1))
        targetMenu := CurrentMenu
        if (level > 0) {
            targetMenu := MenuStack[level]
            if (targetMenu == "")
                targetMenu := "CustomMenu_Level1"
            CurrentMenu := targetMenu
        }

        if (lineContent == "||") {
            MenuNeedsBreak[targetMenu] := true
            continue
        }

        parts := StrSplit(lineContent, "|")
        if (!GdipMenuData.HasKey(targetMenu))
            GdipMenuData[targetMenu] := []

        if (level > 0 && lineContent != "" && parts.Length() < 5) {

            itemName := Trim(parts[1])
            hotkeyDef := Trim(parts[2])
            iconDef := Trim(parts[3])
            remarkDef := Trim(parts[4])

            if (!MenuCounts.HasKey(targetMenu))
                MenuCounts[targetMenu] := {}
            if (MenuCounts[targetMenu].HasKey(itemName)) {
                MenuCounts[targetMenu][itemName]++
                itemName := itemName " [" MenuCounts[targetMenu][itemName] "]"
            } else {
                MenuCounts[targetMenu][itemName] := 0
            }

            newMenuName := "CustomMenu_L" (level + 1) "_" A_Index
            MenuStack[level + 1] := newMenuName
            CurrentMenu := newMenuName

            needsBreak := MenuNeedsBreak[targetMenu] ? true : false
            MenuNeedsBreak[targetMenu] := false

            PendingSubmenus[newMenuName] := {Parent: targetMenu, Name: itemName, Hotkey: hotkeyDef, Icon: iconDef, Remark: remarkDef, Break: needsBreak, LineNum: A_Index}
            continue
        }

        if (lineContent == "") {
            Menu, %targetMenu%, Add
            ; 【修改】追加 LineNum，让分隔线也能被右键精准定位
            GdipMenuData[targetMenu].Push({Type: "Separator", LineNum: A_Index})
        } else {
            itemName := Trim(parts[1])
            hotkeyDef := Trim(parts[2])
            iconDef := Trim(parts[3])
            remarkDef := Trim(parts[4])
            itemType := Trim(parts[5])
            itemParam := Trim(parts[6])

            if (!MenuCounts.HasKey(targetMenu))
                MenuCounts[targetMenu] := {}
            if (MenuCounts[targetMenu].HasKey(itemName)) {
                MenuCounts[targetMenu][itemName]++
                itemName := itemName " [" MenuCounts[targetMenu][itemName] "]"
            } else {
                MenuCounts[targetMenu][itemName] := 0
            }

            actionKey := targetMenu "_" itemName
            DynamicMenuActions[actionKey] := {Type: itemType, Param: itemParam}

            ; 【核心修复】先把换列标志存到一个临时变量里
            isBreak := MenuNeedsBreak[targetMenu]
            options := ""
            if (isBreak) {
                options := "+BarBreak"
                ; 原生菜单用完后重置，但我们后面 GDI+ 用的将是 isBreak
                MenuNeedsBreak[targetMenu] := false
            }

            ; 1. 添加原生菜单
            Menu, %targetMenu%, Add, %itemName%, DynamicMenuRouter, %options%
            SetMenuIcon(targetMenu, itemName, iconDef)

            ; 2. 注入 GDI+ 数据树 (这里使用存下来的 isBreak)
            GdipMenuData[targetMenu].Push({Type: "Item"
                , Name: itemName
                , ActionKey: actionKey
                , Hotkey: hotkeyDef
                , Icon: iconDef
                , Remark: remarkDef
                , FuncType: itemType
                , FuncParam: itemParam
                , Break: isBreak
                , LineNum: A_Index}) ; 【新增】记录当前文件行号

            if (hotkeyDef != "") {
                bf := Func("ExecuteDynamicAction").Bind(actionKey)
                Hotkey, %hotkeyDef%, %bf%, On, UseErrorLevel
            }
        }

        parentToAttach := targetMenu
        while (PendingSubmenus.HasKey(parentToAttach)) {
            pInfo := PendingSubmenus[parentToAttach]
            pName := pInfo.Parent
            iName := pInfo.Name
            iIcon := pInfo.Icon
            iBreak := pInfo.Break

            opt := iBreak ? "+BarBreak" : ""

            ; 1. 原生子菜单挂载
            Menu, %pName%, Add, %iName%, :%parentToAttach%, %opt%
            SetMenuIcon(pName, iName, iIcon)

            ; 2. GDI+ 子菜单挂载节点 (增加 Break 属性)
            GdipMenuData[pName].Push({Type: "SubMenu"
                , Name: iName
                , Target: parentToAttach
                , Hotkey: pInfo.Hotkey
                , Icon: iIcon
                , Remark: pInfo.Remark
                , Break: iBreak
                , LineNum: pInfo.LineNum}) ; 【新增】传递子菜单的行号

            PendingSubmenus.Delete(parentToAttach)
            parentToAttach := pName
        }
    }
}

SetMenuIcon(menuName, itemName, iconDef) {
    if (iconDef == "")
        return
    iconFile := iconDef
    iconNum := 1
    if InStr(iconDef, ",") {
        p := StrSplit(iconDef, ",")
        iconFile := Trim(p[1])
        iconNum := Trim(p[2])
    }
    Menu, %menuName%, Icon, %itemName%, %iconFile%, %iconNum%
}

; ===========================================================
; GDI+ 现代化自绘菜单引擎
; ===========================================================

ShowGdipMenu_Level(MenuName, X, Y, Level) {
    global GdipMenuData, ActiveGdipMenus

    if (!GdipMenuData.HasKey(MenuName))
        return

    ; 清理同级及更深层级的旧菜单
    Loop {
        if (ActiveGdipMenus.Length() >= Level)
            CloseGdipMenu_ByLevel(ActiveGdipMenus.Length())
        else
            break
    }

    ; --- UI 参数配置 ---
    ItemHeight := MenuGdipLineSpacing
    PaddingX := 15
    PaddingY := 10
    ColWidth := MenuGdipMaxWidth

    ; 主题色彩判定
    if (MenuGdipTheme = "Dark") {
        BgColor := 0xF0202020
        BorderColor := 0xFF404040
        TextColor := 0xFFEEEEEE
        SepColor := 0x44FFFFFF
    } else {
        BgColor := 0xFAFFFFFF
        BorderColor := 0x33000000
        TextColor := 0xFF333333
        SepColor := 0x22000000
    }

    MenuData := GdipMenuData[MenuName]

    ; --- 1. 计算自适应宽度 ---
    ActualColWidth := MenuGdipMinWidth
    For index, item in MenuData {
        if (item.Type != "Separator") {
            ; 估算文字宽度: 基础留白 + 图标 + 名字宽度 + 热键宽度 + 箭头宽度
            w := PaddingX * 2 + (MenuGdipShowIcon ? MenuGdipIconSize + 8 : 0) + (StrLen(item.Name) * MenuGdipFontSize * 0.85) + 15
            if (item.Hotkey != "")
                w += (StrLen(item.Hotkey) * MenuGdipFontSize * 0.75) + 20
            if (item.Type == "SubMenu")
                w += 20
            if (w > ActualColWidth)
                ActualColWidth := w
        }
    }
    if (ActualColWidth > MenuGdipMaxWidth)
        ActualColWidth := MenuGdipMaxWidth
    ColWidth := ActualColWidth

    ; --- 2. 计算总列数与动态高度 ---
    Cols := 1
    curColH := 0
    MaxColH := 0

    For index, item in MenuData {
        if (item.Break && curColH > 0) {
            Cols++
            if (curColH > MaxColH)
                MaxColH := curColH
            curColH := 0
        }
        ; 【核心修复】分隔符固定占用 10 像素高度，不再跟普通项一样宽大
        curColH += (item.Type == "Separator") ? 10 : ItemHeight
    }
    if (curColH > MaxColH)
        MaxColH := curColH

    MenuWidth := ColWidth * Cols
    MenuHeight := MaxColH + (PaddingY * 2)

    ; --- 屏幕边缘碰撞检测与坐标修正 ---
    SysGet, mon, MonitorWorkArea, 1
    if (Level > 1) {
        ParentInfo := ActiveGdipMenus[Level - 1]
        if (X + MenuWidth > monRight)
            X := ParentInfo.X - MenuWidth + 5
    } else {
        if (X + MenuWidth > monRight)
            X := monRight - MenuWidth
    }
    if (Y + MenuHeight > monBottom)
        Y := monBottom - MenuHeight

    GuiName := "GdipMenuUI_" Level
    Gui, %GuiName%: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +Owner
    Gui, %GuiName%: Show, NA
    hwnd := WinExist()

    hbm := CreateDIBSection(MenuWidth, MenuHeight)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    G := Gdip_GraphicsFromHDC(hdc)
    Gdip_SetSmoothingMode(G, 4)

    pBrushBg := Gdip_BrushCreateSolid(BgColor)
    pPenBorder := Gdip_CreatePen(BorderColor, 1)
    pBrushText := Gdip_BrushCreateSolid(TextColor)
    pBrushSep := Gdip_BrushCreateSolid(SepColor)
    Gdip_FillRoundedRectangle(G, pBrushBg, 1, 1, MenuWidth-2, MenuHeight-2, 6)
    Gdip_DrawRoundedRectangle(G, pPenBorder, 1, 1, MenuWidth-2, MenuHeight-2, 6)

    Hitboxes := []
    currentY := PaddingY
    currentCol := 0

    ; --- 3. 多列绘制循环 ---
    For index, item in MenuData {
        curItemH := (item.Type == "Separator") ? 10 : ItemHeight

        if (item.Break && index > 1) {
            currentCol++
            currentY := PaddingY
            Gdip_FillRectangle(G, pBrushSep, (currentCol * ColWidth), PaddingY, 1, MenuHeight - (PaddingY*2))
        }

        OffsetX := currentCol * ColWidth

        if (item.Type == "Separator") {
            Gdip_FillRectangle(G, pBrushSep, OffsetX + PaddingX, currentY + (curItemH/2), ColWidth - (PaddingX*2), 1)
            Hitboxes.Push({Type: "Separator", X1: OffsetX, X2: OffsetX + ColWidth, Y1: currentY, Y2: currentY + curItemH})
        } else {
            Hitboxes.Push({Type: item.Type, Index: index, Data: item, X1: OffsetX, X2: OffsetX + ColWidth, Y1: currentY, Y2: currentY + curItemH})

            if (MenuGdipShowIcon && item.Icon != "") {
                pBitmap := GetIconBitmap_xy(item.Icon, MenuGdipIconSize)
                if (pBitmap) {
                    iconOffset := (curItemH - MenuGdipIconSize) / 2
                    Gdip_DrawImage(G, pBitmap, OffsetX + PaddingX, currentY + iconOffset, MenuGdipIconSize, MenuGdipIconSize)
                    Gdip_DisposeImage(pBitmap)
                }
            }

            ; 画左侧菜单名
            TextOffsetX := MenuGdipShowIcon ? (PaddingX + MenuGdipIconSize + 8) : PaddingX
            Options := "x" OffsetX + TextOffsetX " y" currentY + (curItemH - MenuGdipFontSize)/2 - 2 " c" SubStr(TextColor, 3) " s" MenuGdipFontSize " r4"
            Gdip_TextToGraphics(G, item.Name, Options, MenuGdipFontName)

            ; 画右侧热键 (如果有)
            if (item.Hotkey != "") {
                hkOpt := "x" OffsetX " y" currentY + (curItemH - MenuGdipFontSize)/2 - 2 " cFF888888 s" (MenuGdipFontSize-1) " r4 Right"
                rightMargin := (item.Type == "SubMenu") ? 35 : 15
                Gdip_TextToGraphics(G, item.Hotkey, hkOpt " w" (ColWidth - rightMargin), MenuGdipFontName)
            }

            if (item.Type == "SubMenu") {
                Gdip_TextToGraphics(G, "▶", "x" OffsetX + ColWidth - 25 " y" currentY + (curItemH - 10)/2 " cFF999999 s10 r4", "Arial")
            }
        }
        currentY += curItemH
    }

    UpdateLayeredWindow(hwnd, hdc, X, Y, MenuWidth, MenuHeight)

    Gdip_DeleteBrush(pBrushBg)
    Gdip_DeleteBrush(pBrushText)
    Gdip_DeleteBrush(pBrushSep)
    Gdip_DeletePen(pPenBorder)
    SelectObject(hdc, obm)
    DeleteObject(hbm)
    DeleteDC(hdc)
    Gdip_DeleteGraphics(G)

    ActiveGdipMenus[Level] := {Hwnd: hwnd, Name: GuiName, X: X, Y: Y, W: MenuWidth, H: MenuHeight, Hitboxes: Hitboxes, ActiveHover: 0}
}

; ===========================================================
; GDI+ 菜单局部重绘引擎 (专用于悬停高亮响应)
; ===========================================================
RedrawGdipMenuLevel(Level, HoverIdx) {
    global ActiveGdipMenus, MenuGdipTheme, MenuGdipShowIcon, MenuGdipIconSize, MenuGdipFontSize, MenuGdipFontName, MenuGdipHoverHighlight, MenuGdipMaxWidth
    if (!ActiveGdipMenus.HasKey(Level))
        return
    info := ActiveGdipMenus[Level]

    ; 自动适配浅色与深色模式下的高亮背景色 (HoverBgColor)
    if (MenuGdipTheme = "Dark") {
        BgColor := 0xF0202020, BorderColor := 0xFF404040, TextColor := 0xFFEEEEEE, SepColor := 0x44FFFFFF, HoverBgColor := 0x40FFFFFF
    } else {
        BgColor := 0xFAFFFFFF, BorderColor := 0x33000000, TextColor := 0xFF333333, SepColor := 0x22000000, HoverBgColor := 0x20000000
    }

    hbm := CreateDIBSection(info.W, info.H)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    G := Gdip_GraphicsFromHDC(hdc)
    Gdip_SetSmoothingMode(G, 4)

    pBrushBg := Gdip_BrushCreateSolid(BgColor)
    pPenBorder := Gdip_CreatePen(BorderColor, 1)
    pBrushText := Gdip_BrushCreateSolid(TextColor)
    pBrushSep := Gdip_BrushCreateSolid(SepColor)
    pBrushHover := Gdip_BrushCreateSolid(HoverBgColor)

    ; 绘制总背景
    Gdip_FillRoundedRectangle(G, pBrushBg, 1, 1, info.W-2, info.H-2, 6)
    Gdip_DrawRoundedRectangle(G, pPenBorder, 1, 1, info.W-2, info.H-2, 6)

    ; 遍历并重绘所有热区内容
    For idx, box in info.Hitboxes {
        if (box.Type == "Separator") {
            Gdip_FillRectangle(G, pBrushSep, box.X1 + 15, box.Y1 + (box.Y2 - box.Y1)/2, box.X2 - box.X1 - 30, 1)
        } else {
            ; 【核心】绘制悬停高亮背景
            if (MenuGdipHoverHighlight && HoverIdx == idx) {
                Gdip_FillRoundedRectangle(G, pBrushHover, box.X1 + 5, box.Y1, box.X2 - box.X1 - 10, box.Y2 - box.Y1, 4)
            }

            if (MenuGdipShowIcon && box.Data.Icon != "") {
                pBitmap := GetIconBitmap_xy(box.Data.Icon, MenuGdipIconSize)
                if (pBitmap) {
                    iconOffset := (box.Y2 - box.Y1 - MenuGdipIconSize) / 2
                    Gdip_DrawImage(G, pBitmap, box.X1 + 15, box.Y1 + iconOffset, MenuGdipIconSize, MenuGdipIconSize)
                    Gdip_DisposeImage(pBitmap)
                }
            }

            TextOffsetX := MenuGdipShowIcon ? (15 + MenuGdipIconSize + 8) : 15
            Options := "x" box.X1 + TextOffsetX " y" box.Y1 + (box.Y2 - box.Y1 - MenuGdipFontSize)/2 - 2 " c" SubStr(TextColor, 3) " s" MenuGdipFontSize " r4"

            ; 绘制左侧菜单名
            Gdip_TextToGraphics(G, box.Data.Name, Options, MenuGdipFontName)

            ; 绘制悬停时的右侧热键
            if (box.Data.Hotkey != "") {
                hkOpt := "x" box.X1 " y" box.Y1 + (box.Y2 - box.Y1 - MenuGdipFontSize)/2 - 2 " cFF888888 s" (MenuGdipFontSize-1) " r4 Right"
                rightMargin := (box.Type == "SubMenu") ? 35 : 15
                Gdip_TextToGraphics(G, box.Data.Hotkey, hkOpt " w" (box.X2 - box.X1 - rightMargin), MenuGdipFontName)
            }

            if (box.Type == "SubMenu") {
                Gdip_TextToGraphics(G, "▶", "x" box.X2 - 25 " y" box.Y1 + (box.Y2 - box.Y1 - 10)/2 " cFF999999 s10 r4", "Arial")
            }
        }
    }

    ; 【新增/修复】将分割线绘制移到高亮图层之上，且动态获取真实的列宽
    if (info.Hitboxes.Length() > 0) {
        ColW := info.Hitboxes[1].X2 - info.Hitboxes[1].X1
        Cols := Round(info.W / ColW)
        if (Cols > 1) {
            Loop % Cols - 1 {
                Gdip_FillRectangle(G, pBrushSep, A_Index * ColW, 10, 1, info.H - 20)
            }
        }
    }
    UpdateLayeredWindow(info.Hwnd, hdc, info.X, info.Y, info.W, info.H)

    Gdip_DeleteBrush(pBrushBg), Gdip_DeleteBrush(pBrushText), Gdip_DeleteBrush(pBrushSep), Gdip_DeleteBrush(pBrushHover), Gdip_DeletePen(pPenBorder)
    SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc), Gdip_DeleteGraphics(G)
}

GdipMenu_MouseMove(wParam, lParam, msg, hwnd) {
    global ActiveGdipMenus

    currLevel := 0
    For idx, menu in ActiveGdipMenus {
        if (menu.Hwnd == hwnd) {
            currLevel := idx
            break
        }
    }
    if (!currLevel)
        return

    mY := lParam >> 16
    mX := lParam & 0xFFFF
    MenuInfo := ActiveGdipMenus[currLevel]

    HoverIndex := 0
    For idx, box in MenuInfo.Hitboxes {
        ; 增加 X1, X2 判定列宽范围
        if (mY >= box.Y1 && mY <= box.Y2 && mX >= box.X1 && mX <= box.X2 && box.Type != "Separator") {
            HoverIndex := idx
            break
        }
    }

    if (HoverIndex != MenuInfo.ActiveHover) {
        MenuInfo.ActiveHover := HoverIndex
        box := MenuInfo.Hitboxes[HoverIndex]

        if (MenuGdipShowTooltip) {
            if (HoverIndex && box.Type == "Item") {  ; 只允许菜单项触发，排除 SubMenu
                d := box.Data
                cleanName := StrSplit(d.Name, "`t")[1] ; 清理一下热键后缀，让提示更干净
                ttStr := "菜单项名: " cleanName
                if (d.Hotkey != "")
                    ttStr .= "`n热键: " d.Hotkey
                if (d.Icon != "")
                    ttStr .= "`n菜单图标: " d.Icon
                if (d.Remark != "")
                    ttStr .= "`n备注: " d.Remark
                if (d.FuncType != "")
                    ttStr .= "`n功能类型: " d.FuncType
                if (d.FuncParam != "")
                    ttStr .= "`n功能参数: " d.FuncParam

                ; 将文本存入全局变量并启动延迟定时器 (负数代表只执行一次，400即延迟400毫秒)
                global DelayedTooltipText := ttStr
                SetTimer, ExecuteDelayedTooltip, -400

                SetTimer, CheckMenuTooltipLeave, 100
            } else {
                SetTimer, ExecuteDelayedTooltip, Off  ; 鼠标移到非菜单项时，取消还没弹出的提示
                ToolTip
            }
        }

        RedrawGdipMenuLevel(currLevel, HoverIndex)

        if (box && box.Type == "SubMenu") {
            NextX := MenuInfo.X + box.X2 - 5
            NextY := MenuInfo.Y + box.Y1
            ShowGdipMenu_Level(box.Data.Target, NextX, NextY, currLevel + 1)
        } else {
            Loop {
                if (ActiveGdipMenus.Length() > currLevel)
                    CloseGdipMenu_ByLevel(ActiveGdipMenus.Length())
                else
                    break
            }
        }
    }
}

GdipMenu_LButtonDown(wParam, lParam, msg, hwnd) {
    global ActiveGdipMenus

    currLevel := 0
    For idx, menu in ActiveGdipMenus {
        if (menu.Hwnd == hwnd) {
            currLevel := idx
            break
        }
    }

    if (!currLevel) {
        CloseAllGdipMenus()
        return
    }

    mY := lParam >> 16
    mX := lParam & 0xFFFF
    MenuInfo := ActiveGdipMenus[currLevel]

    For idx, box in MenuInfo.Hitboxes {
        ; 同样增加 X 轴判定，防止点击错误列
        if (mY >= box.Y1 && mY <= box.Y2 && mX >= box.X1 && mX <= box.X2 && box.Type == "Item") {
            action := box.Data.ActionKey
            CloseAllGdipMenus()
            ExecuteDynamicAction(action)
            return
        }
    }
}
; ===========================================================
; GDI+ 菜单右键可视化编辑引擎
; ===========================================================
global EditMenuTargetLine := 0
global EditMenuTargetData := {}

GdipMenu_RButtonDown(wParam, lParam, msg, hwnd) {
    global ActiveGdipMenus
    currLevel := 0
    For idx, menu in ActiveGdipMenus {
        if (menu.Hwnd == hwnd) {
            currLevel := idx
            break
        }
    }
    if (!currLevel)
        return

    mY := lParam >> 16
    mX := lParam & 0xFFFF
    MenuInfo := ActiveGdipMenus[currLevel]

    For idx, box in MenuInfo.Hitboxes {
        ; 【修改】放开条件，允许右键点击 Separator (分隔线)
        if (mY >= box.Y1 && mY <= box.Y2 && mX >= box.X1 && mX <= box.X2 && (box.Type == "Item" || box.Type == "SubMenu" || box.Type == "Separator")) {
            global EditMenuTargetLine := box.Data.LineNum
            global EditMenuTargetData := box.Data

            ; --- 新增：读取文件以判断上下行是否为纯 - 的分隔符 ---
            global DynamicMenuFile
            FileRead, content, %DynamicMenuFile%
            lines := StrSplit(content, "`n", "`r")
            prevIsSep := (EditMenuTargetLine > 1 && RegExMatch(lines[EditMenuTargetLine - 1], "^[ \t]*-+$"))
            nextIsSep := (EditMenuTargetLine < lines.Length() && RegExMatch(lines[EditMenuTargetLine + 1], "^[ \t]*-+$"))

            Menu, GdipContextMenu, Add
            Menu, GdipContextMenu, DeleteAll

            ; 如果点的是分隔符，就不显示“编辑”
            if (box.Type != "Separator")
                Menu, GdipContextMenu, Add, ✏️ 编辑当前项, EditGdipMenuItem

            Menu, GdipContextMenu, Add, ➕ 在此项后新建, AddGdipMenuItem
            Menu, GdipContextMenu, Add, ➖ 在此项后添加分隔线, AddGdipMenuSeparator

            if (prevIsSep)
                Menu, GdipContextMenu, Add, ❌ 删除上方分隔线, DeleteUpperSeparator
            if (nextIsSep)
                Menu, GdipContextMenu, Add, ❌ 删除下方分隔线, DeleteLowerSeparator

            Menu, GdipContextMenu, Add
            Menu, GdipContextMenu, Add, ❌ 删除当前项, DeleteGdipMenuItem
            Menu, GdipContextMenu, Show
            return
        }
    }
}

EditGdipMenuItem:
    CloseAllGdipMenus()
    ShowMenuEditorGUI("Edit")
return

AddGdipMenuItem:
    CloseAllGdipMenus()
    ShowMenuEditorGUI("Add")
return

DeleteGdipMenuItem:
    CloseAllGdipMenus()
    MsgBox, 292, 确认删除, 警告：确定要删除该菜单项吗？`n(若是子分类，其内部子项可能也会受到影响)
    IfMsgBox, Yes
        ModifyMenuIniFile("Delete", EditMenuTargetLine, "")
return
AddGdipMenuSeparator:
    CloseAllGdipMenus()
    ModifyMenuIniFile("AddSep", EditMenuTargetLine, "")
return

DeleteUpperSeparator:
    CloseAllGdipMenus()
    ModifyMenuIniFile("DelUpper", EditMenuTargetLine, "")
return

DeleteLowerSeparator:
    CloseAllGdipMenus()
    ModifyMenuIniFile("DelLower", EditMenuTargetLine, "")
return

; --- 动态菜单编辑器 GUI ---
ShowMenuEditorGUI(Mode) {
    global EditMenuTargetData, GuiMenuMode, GuiMenuLine
    GuiMenuMode := Mode
    GuiMenuLine := EditMenuTargetLine

    Gui, MenuEditor:Destroy
    Gui, MenuEditor:Font, s9, Microsoft YaHei
    Gui, MenuEditor:Add, Text, x20 y20 w60 h20, 菜单名称:
    Gui, MenuEditor:Add, Edit, x80 y18 w220 h20 vE_Name

    Gui, MenuEditor:Add, Text, x20 y50 w60 h20, 快捷键:
    Gui, MenuEditor:Add, Edit, x80 y48 w220 h20 vE_Hotkey

    Gui, MenuEditor:Add, Text, x20 y80 w60 h20, 图标路径:
    Gui, MenuEditor:Add, Edit, x80 y78 w220 h20 vE_Icon

    Gui, MenuEditor:Add, Text, x20 y110 w60 h20, 提示备注:
    Gui, MenuEditor:Add, Edit, x80 y108 w220 h20 vE_Remark

    Gui, MenuEditor:Add, Text, x20 y140 w60 h20, 功能类型:
    Gui, MenuEditor:Add, DropDownList, x80 y138 w220 vE_Type, 1.内置函数||2.运行程序|3.外部脚本|子分类 (仅展开)

    Gui, MenuEditor:Add, Text, x20 y170 w60 h20, 功能参数:
    Gui, MenuEditor:Add, Edit, x80 y168 w220 h20 vE_Param

    if (Mode = "Edit" && IsObject(EditMenuTargetData)) {
        GuiControl, MenuEditor:, E_Name, % EditMenuTargetData.Name
        GuiControl, MenuEditor:, E_Hotkey, % EditMenuTargetData.Hotkey
        GuiControl, MenuEditor:, E_Icon, % EditMenuTargetData.Icon
        GuiControl, MenuEditor:, E_Remark, % EditMenuTargetData.Remark
        if (EditMenuTargetData.Type = "SubMenu") {
            GuiControl, MenuEditor:ChooseString, E_Type, 子分类 (仅展开)
        } else {
            GuiControl, MenuEditor:Choose, E_Type, % EditMenuTargetData.FuncType
        }
        GuiControl, MenuEditor:, E_Param, % EditMenuTargetData.FuncParam
    }

    btnText := (Mode = "Edit") ? "💾 保存修改" : "✅ 确认添加"
    Gui, MenuEditor:Add, Button, x80 y210 w110 h32 Default gSaveMenuEditor, %btnText%
    Gui, MenuEditor:Add, Button, x200 y210 w100 h32 gCloseMenuEditor, 取消

    Gui, MenuEditor:Show, w320 h260, % (Mode="Edit"?"编辑菜单项":"新增菜单项")
}

CloseMenuEditor:
    Gui, MenuEditor:Destroy
return

SaveMenuEditor:
    Gui, MenuEditor:Submit, NoHide

    ; 提取类型编号
    typeVal := SubStr(E_Type, 1, 1)
    if (InStr(E_Type, "子分类"))
        typeVal := ""

    ; 拼接符合原本 INI 解析规范的字符串结构
    newLine := E_Name "|" E_Hotkey "|" E_Icon "|" E_Remark
    if (typeVal != "")
        newLine .= "|" typeVal "|" E_Param

    ModifyMenuIniFile(GuiMenuMode, GuiMenuLine, newLine)
    Gui, MenuEditor:Destroy
return

; --- 文件修改与行替换核心引擎 (智能层级增强版 V2) ---
ModifyMenuIniFile(Action, TargetLineNum, NewContent) {
    global DynamicMenuFile

    FileRead, content, %DynamicMenuFile%
    lines := StrSplit(content, "`n", "`r")

    ActiveLevel := 1
    TargetActiveLevel := 1
    TargetWhiteSpace := ""

    ; --- 1. 模拟引擎解析，精准获取目标行的真实上下文层级和排版缩进 ---
    For index, line in lines {
        trimmedLine := Trim(line)

        ; 计算当前行的基本 level (破折号数量)
        level := 0
        if (trimmedLine != "" && SubStr(trimmedLine, 1, 1) != ";") {
            while (SubStr(trimmedLine, level + 1, 1) == "-")
                level++
        }

        ; 如果当前行有显式的 level，立即更新 ActiveLevel (这是跳出子分类的关键)
        if (level > 0)
            ActiveLevel := level

        ; 捕获目标行的状态
        if (index == TargetLineNum) {
            TargetActiveLevel := ActiveLevel
            RegExMatch(line, "^([ \t]*)", match)
            TargetWhiteSpace := match1
        }

        ; 检查当前行是否是子分类声明，如果是，为下一行准备更深的 ActiveLevel
        if (trimmedLine != "" && SubStr(trimmedLine, 1, 1) != ";") {
            lineContent := Trim(SubStr(trimmedLine, level + 1))
            parts := StrSplit(lineContent, "|")
            if (level > 0 && lineContent != "" && parts.Length() < 5)
                ActiveLevel := level + 1
        }
    }

    ; --- 2. 判定旧行和新行是否为子分类声明 ---
    oldIsSubMenu := false
    if (TargetLineNum <= lines.Length()) {
        StrReplace(lines[TargetLineNum], "|", "|", oldPipeCount)
        if (oldPipeCount < 4 && Trim(lines[TargetLineNum]) != "" && !RegExMatch(Trim(lines[TargetLineNum]), "^-+$"))
            oldIsSubMenu := true
    }

    isNewSubMenu := false
    if (NewContent != "") {
        StrReplace(NewContent, "|", "|", pipeCount)
        if (pipeCount < 4)
            isNewSubMenu := true
    }

    ; 生成匹配当前深度的破折号前缀
    dashPrefix := ""
    Loop % TargetActiveLevel {
        dashPrefix .= "-"
    }

    newNormalPrefix := TargetWhiteSpace
    newSpecialPrefix := TargetWhiteSpace . dashPrefix

    ; --- 3. 重构文件内容 ---
    newContentFile := ""
    DeletingSubMenu := false   ; 【新增】标记是否正在连带删除子分类内部项

    For index, line in lines {
        ; 【新增逻辑】判断当前行是否属于被删除子分类的内部内容
        if (DeletingSubMenu) {
            trimmedLine := Trim(line)
            if (trimmedLine == "" || SubStr(trimmedLine, 1, 1) == ";")
                continue ; 忽略并一并删除空行和注释

            curLevel := 0
            while (SubStr(trimmedLine, curLevel + 1, 1) == "-")
                curLevel++

            if (curLevel == 0 || curLevel > TargetActiveLevel) {
                continue ; 属于子分类内部项（层级为0或更深），一并删除
            } else if (curLevel == TargetActiveLevel && RegExMatch(trimmedLine, "^-+$")) {
                DeletingSubMenu := false ; 遇到同层级的纯分隔符（逃逸符），删除它并结束连带删除状态
                continue
            } else {
                DeletingSubMenu := false ; 遇到同层或更浅的其他有效项，说明子分类已结束，恢复正常读取
            }
        }

        if (index == TargetLineNum) {
            if (Action = "Edit") {
                if (isNewSubMenu) {
                    newContentFile .= newSpecialPrefix . NewContent . "`n"
                    ; 如果普通项被编辑成了子分类，防止后续项被误吸入，必须补充占位符和逃逸符
                    if (!oldIsSubMenu) {
                        newContentFile .= newNormalPrefix . "(无)|||||`n"
                        newContentFile .= newSpecialPrefix . "`n"
                    }
                } else {
                    newContentFile .= newNormalPrefix . NewContent . "`n"
                }
            } else if (Action = "Add") {
                newContentFile .= line . "`n"
                if (isNewSubMenu) {
                    newContentFile .= newSpecialPrefix . NewContent . "`n"
                    newContentFile .= newNormalPrefix . "(无)|||||`n"  ; 智能追加 (无) 占位符
                    newContentFile .= newSpecialPrefix . "`n"          ; 智能追加 父级逃逸分隔符
                } else {
                    newContentFile .= newNormalPrefix . NewContent . "`n"
                }
            } else if (Action = "AddSep") {
                newContentFile .= line . "`n" . newSpecialPrefix . "`n"
            } else if (Action = "Delete") {
                if (oldIsSubMenu)
                    DeletingSubMenu := true ; 【新增】若是删除子分类，开启连带删除状态
                continue
            } else {
                newContentFile .= line . "`n"
            }
        } else if (index == TargetLineNum - 1 && Action = "DelUpper") {
            continue
        } else if (index == TargetLineNum + 1 && Action = "DelLower") {
            continue
        } else {
            newContentFile .= line . "`n"
        }
    }

    ; 移除末尾多余换行并覆写文件
    newContentFile := RegExReplace(newContentFile, "`n$", "")
    FileDelete, %DynamicMenuFile%
    FileAppend, %newContentFile%, %DynamicMenuFile%, UTF-8

    Reload
}
; ===========================================================
; 监听鼠标移出菜单以清除 ToolTip 及边缘高亮
; ===========================================================
CheckMenuTooltipLeave:
    MouseGetPos,,, hoverHwnd
    WinGetClass, hoverClass, ahk_id %hoverHwnd%

    ; 【核心修复】：如果鼠标正巧指在 ToolTip 提示框上，属于正常悬停，不视为离开菜单！
    if (hoverClass == "tooltips_class32")
        return

    isMenuHit := false
    For idx, m in ActiveGdipMenus {
        if (m.Hwnd == hoverHwnd) {
            isMenuHit := true
            break
        }
    }

    if (!isMenuHit) {
        SetTimer, ExecuteDelayedTooltip, Off ; 鼠标移出整个菜单时，立刻取消还在倒计时的提示
        ToolTip ; 清除提示框
        SetTimer, CheckMenuTooltipLeave, Off

        ; 熄灭最后停留菜单的背景高亮残留
        For idx, m in ActiveGdipMenus {
            if (m.ActiveHover != 0) {
                m.ActiveHover := 0
                RedrawGdipMenuLevel(idx, 0)
            }
        }
    }
return
; ===========================================================
; 辅助函数：从 DLL/EXE/图片 获取 GDI+ Bitmap 格式的图标
; ===========================================================
GetIconBitmap_xy(iconDef, size:=16) {
    if (iconDef == "")
        return 0
    p := StrSplit(iconDef, ",")
    file := Trim(StrReplace(p[1], """", ""))
    index := p.MaxIndex() > 1 ? Trim(p[2]) : 1

    ; 修复1: 展开环境变量 (例如 %SystemRoot%\system32\shell32.dll 转换为绝对路径)
    VarSetCapacity(expFile, 32767 * (A_IsUnicode ? 2 : 1))
    DllCall("ExpandEnvironmentStrings", "Str", file, "Str", expFile, "UInt", 32767)
    file := expFile ? expFile : file

    ; 1. 如果是 exe/dll，调用系统 API 提取图标句柄
    if RegExMatch(file, "i)\.(exe|dll)$") {
        ; 修复2: 负数为资源ID时不减1，正数索引转为基于0
        realIndex := (index < 0) ? index : index - 1
        DllCall("shell32\ExtractIconEx", "Str", file, "Int", realIndex, "Ptr*", hIconLarge, "Ptr*", hIconSmall, "UInt", 1)

        hIcon := hIconSmall ? hIconSmall : hIconLarge
        if (hIcon) {
            pBitmap := Gdip_CreateBitmapFromHICON(hIcon)
            DllCall("DestroyIcon", "Ptr", hIconLarge)
            DllCall("DestroyIcon", "Ptr", hIconSmall)
            return pBitmap
        }
    }
    ; 2. 如果是常规图片文件 (ico, png, jpg 等)
    else if FileExist(file) {
        return Gdip_CreateBitmapFromFile(file)
    }
    return 0
}
ExecuteDelayedTooltip:
    if (DelayedTooltipText != "")
        ToolTip, % DelayedTooltipText
return

; 失去焦点检测 (点击外部时触发关闭)
~LButton::
    global ActiveGdipMenus
    if (ActiveGdipMenus.Length() > 0) {
        MouseGetPos,,, hoverHwnd
        isMenuHit := false
        For idx, menu in ActiveGdipMenus {
            if (menu.Hwnd == hoverHwnd) {
                isMenuHit := true
                break
            }
        }
        if (!isMenuHit) {
            CloseAllGdipMenus()
        }
    }
return

CloseGdipMenu_ByLevel(Level) {
    global ActiveGdipMenus
    if (ActiveGdipMenus.HasKey(Level)) {
        GuiName := ActiveGdipMenus[Level].Name
        Gui, %GuiName%: Destroy
        ActiveGdipMenus.RemoveAt(Level)
    }
}

CloseAllGdipMenus() {
    global ActiveGdipMenus
    OnMessage(0x0200, "") ; 注销鼠标移动事件
    OnMessage(0x0201, "") ; 注销鼠标点击事件
    OnMessage(0x0204, "")

    Loop {
        if (ActiveGdipMenus.Length() > 0)
            CloseGdipMenu_ByLevel(ActiveGdipMenus.Length())
        else
            break
    }
}

; --- 菜单点击事件路由 ---
DynamicMenuRouter:
    actionKey := A_ThisMenu "_" A_ThisMenuItem
    ExecuteDynamicAction(actionKey)
return

; --- 动作实际执行器 (终极修复版：彻底解决 JS 变量逃逸与 0x80020101 报错) ---
ExecuteDynamicAction(actionKey) {
    global ; 关键：开启全局变量访问，确保能动态读取脚本内的其他全局变量

    ; --- 热键黑名单拦截 ---
    if (MenuHotkeyBlacklist != "" && CheckWindowInList(WinExist("A"), MenuHotkeyBlacklist))
        return

    if (!DynamicMenuActions.HasKey(actionKey))
        return

    action := DynamicMenuActions[actionKey]

    if (action.Type == "1") {
        ; 匹配函数名和括号内的完整参数字符串
        if RegExMatch(action.Param, "O)^([a-zA-Z0-9_]+)\((.*)\)$", match) {
            funcName := match.Value(1)
            paramsStr := Trim(match.Value(2))
            ; 【修复新增】：将路径反斜杠 \ 转义为 \\，防止被 JS 引擎吞噬报错
            paramsStr := StrReplace(paramsStr, "\", "\\")

            paramArr := []
            try {
                ; 创建 JScript 引擎环境，加入 dummy script 强制激活 JS 引擎
                oDoc := ComObjCreate("htmlfile")
                oDoc.write("<meta http-equiv=""X-UA-Compatible"" content=""IE=edge""><script>var __isInit=1;</script>")
                jsWin := oDoc.parentWindow

                ; 新增：将 AHK 常用的布尔值映射到 JS 环境中，防止因大小写导致 0x80020101 报错
                jsWin.execScript("var True = true; var False = false; var TRUE = true; var FALSE = false;")

                ; 自动扫描参数中出现的所有单词，将其作为变量注入到 JScript 中
                if (paramsStr != "") {
                    pos := 1
                    while pos := RegExMatch(paramsStr, "\b([a-zA-Z_][a-zA-Z0-9_]*)\b", m, pos) {
                        vName := m1
                        pos += StrLen(vName) ; 移动指针

                        ; 过滤掉 JavaScript 的关键字和内置对象名
                        if (vName = "true" || vName = "false" || vName = "null" || vName = "Math" || vName = "undefined")
                            continue

                        ; 获取 AHK 变量当前的真实值
                        vVal := ""
                        if (vName = "A_ScreenWidth")
                            vVal := A_ScreenWidth
                        else if (vName = "A_ScreenHeight")
                            vVal := A_ScreenHeight
                        else if (vName = "A_TickCount")
                            vVal := A_TickCount
                        else {
                            ; 动态获取脚本内的全局变量，如果不存在则为空字符串
                            vVal := %vName%
                        }

                        ; 通过 execScript 严谨地注入到 JScript 内存中 (解决直接赋值导致的 0x80020101 问题)
                        if vVal is number
                        {
                            jsWin.execScript("var " vName " = " vVal ";")
                        }
                        else
                        {
                            safeStr := StrReplace(vVal, "\", "\\")
                            safeStr := StrReplace(safeStr, """", "\""")
                            jsWin.execScript("var " vName " = """ safeStr """;")
                        }
                    }
                }

                ; 核心魔法：将参数包裹在 [] 中，让 JScript 自动将其解析为真正的参数数组
                jsArr := jsWin.eval("[" paramsStr "]")

                ; 将 JScript 数组转换为 AHK 能够识别的参数型数组
                if (jsArr) {
                    len := jsArr.length
                    Loop % len
                    {
                        try {
                            ; 正常读取数组元素
                            itemVal := jsArr[A_Index - 1]
                            paramArr.Push(itemVal)
                        } catch {
                            ; 捕获 0x80020006 错误：如果由于连续逗号导致当前索引不存在，则压入空字符串
                            paramArr.Push("")
                        }
                    }
                }
            } catch e {
                MsgBox, 16, 动态菜单参数解析失败, % "错误配置: " action.Param "`n具体原因: " e.Message
                return
            }

            ; 安全调用 AHK 脚本内的对应函数
            if IsFunc(funcName)
                Func(funcName).Call(paramArr*)
            else
                MsgBox, 48, 函数未找到, % "找不到名为 " funcName " 的函数！"
        }
    } else if (action.Type == "2") {
        Run, % action.Param
    } else if (action.Type == "3") {
        ; --- [新增] 解析脚本路径与命令行参数 ---
        ; 使用正则分离路径和参数。支持带引号的路径（防空格干扰）和无引号路径
        if !RegExMatch(action.Param, "^\s*(?:""([^""]+)""|([^\s]+))\s*(.*)$", match)
            return

        scriptPath := match1 ? match1 : match2  ; 提取到的脚本路径
        scriptArgs := match3                    ; 提取到的剩余参数

        ; --- [智能路径补全逻辑] ---
        if (!RegExMatch(scriptPath, "^([a-zA-Z]:\\|\\\\)")) {
            tempPath := A_ScriptDir "\Plugins\" scriptPath
            if FileExist(tempPath) {
                scriptPath := tempPath
            } else if (!FileExist(scriptPath)) {
                scriptPath := tempPath
            }
        }

        ; --- [执行逻辑] ---
        if (RegExMatch(scriptPath, "i)\.ahk\b")) {
            if (!A_IsCompiled) {
                ; 源码环境：外挂参数 %scriptArgs%
                Run, "%A_AhkPath%" "%scriptPath%" %scriptArgs%, , UseErrorLevel
            } else {
                ; 编译环境：/script 后面接脚本路径，再接脚本参数
                Run, "%A_ScriptFullPath%" /script "%scriptPath%" %scriptArgs%, , UseErrorLevel

                if (ErrorLevel)
                    MsgBox, 16, 执行失败, % "内部解释器运行外部脚本失败：`n" scriptPath
            }
        } else {
            ; 其他可执行文件同样支持传参
            Run, "%scriptPath%" %scriptArgs%, , UseErrorLevel
            if (ErrorLevel)
                MsgBox, 16, 执行失败, % "系统无法执行该文件：`n" scriptPath
        }
    }
}

; --- 动态数学表达式计算引擎 ---
EvalMathParam(str) {
    ; 1. 动态解析并替换所有由 %% 包裹的 AHK 变量 (支持内置变量和脚本内的全局变量)
    pos := 1
    while pos := RegExMatch(str, "%([a-zA-Z0-9_#@$]+)%", match, pos) {
        varName := match1          ; 提取出变量名，比如 A_ScreenWidth
        varValue := %varName%      ; 动态获取该变量在脚本当前运行时的真实值

        ; 将原字符串中的 %变量名% 替换为实际数值
        str := StrReplace(str, match, varValue)

        ; 将正则搜索位置往后移，防止死循环
        pos += StrLen(varValue)
    }

    ; 2. 纯数字或不包含运算符号的字符串直接返回，避免不必要的 COM 调用
    if str is number
        return str
    if !RegExMatch(str, "[+\-*/()]")
        return str

    ; 3. 调用 JScript 进行文本公式计算
    try {
        oDoc := ComObjCreate("htmlfile")
        oDoc.write("<meta http-equiv=""X-UA-Compatible"" content=""IE=edge"">")
        result := oDoc.parentWindow.eval(str)
        return result != "" ? result : str
    } catch {
        return str
    }
}
;======================================================================================菜单调用的函数[开始]======================================================================================
;[窗口改变大小]
win_size_zz(var_width,var_height){
    WinRestore, A
    WinMove,A,,,,%var_width%,%var_height%
}

;[窗口改变大小并移动]
win_move_size_zz(var_x,var_y,var_width,var_height){
    WinRestore, A
    WinMove,A,,%var_x%,%var_y%,%var_width%,%var_height%
}

;[窗口透明度]
win_transparency_zz(flag = 1,amount = 10)
{
    WinGetTitle, ActiveTitle, A
    static t = 255
    If(flag=0)
        tmp := t + amount
    else if(flag=1)
        tmp := t - amount
    If(tmp > 255)
        tmp = 255
    else if(tmp < 0)
        tmp = 0
    WinSet,Transparent,%tmp%,%ActiveTitle%
    ToolTip,当前透明度:%tmp%
    Sleep,1000
    ToolTip
    t := tmp
}
;[最小化窗口]
win_minimize_xy(var_WinTitle:="A",var_WinText:="",var_ExcludeTitle="",var_ExcludeText:=""){
    WinMinimize, %var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
}
;[最大化窗口]
win_maximize_xy(var_WinTitle:="A",var_WinText:="",var_ExcludeTitle="",var_ExcludeText:=""){
    WinMaximize, %var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
}
;[关闭窗口]
win_close_xy(var_WinTitle:="A",var_WinText:="",var_ExcludeTitle="",var_ExcludeText:=""){
    WinClose, %var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
}
;[当前窗口进程结束] v1.0.4
win_kill_zz(var_WinTitle:="A",var_WinText:="",var_ExcludeTitle="",var_ExcludeText:=""){
    WinGet,name,ProcessName,%var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
    Process,Close,%name%
}

;[当前窗口进程pid结束] v1.0.7
win_kill_pid_zz(var_WinTitle:="A",var_WinText:="",var_ExcludeTitle="",var_ExcludeText:=""){
    WinGet,pid,PID,%var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
    Process,Close,%pid%
}

;[结束指定窗口程序所有进程] v1.0.0
win_kill_all_xy(var_WinTitle:="A"){
    WinGet, name, ProcessName, %var_WinTitle%
    if !(name)
        return
    loop {
        Process, Close, %name%
        if (!ErrorLevel) ; ErrorLevel 为 0 表示已经没有该名称的进程了，退出循环
            break
    }
}

;[重启当前窗口程序] v1.0.0
win_restart_xy(var_WinTitle:="A"){
    WinGet, path, ProcessPath, %var_WinTitle% ; 获取程序完整路径，用于重启
    WinGet, name, ProcessName, %var_WinTitle% ; 获取进程名，用于干净结束
    if !(path)
        return
    ; 1. 先循环结束该程序的所有相关进程（防止残留）
    loop {
        Process, Close, %name%
        if (!ErrorLevel)
            break
    }
    ; 2. 重新运行该程序
    Run, %path%
}

;[最大化窗口\非最大化]
win_toggle_maximize_xy(var_WinTitle:="A",var_WinText:="",var_ExcludeTitle="",var_ExcludeText:=""){
    WinGet, MinMaxState, MinMax, %var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
    if (MinMaxState = 1)
        WinRestore, %var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
    else
        WinMaximize, %var_WinTitle%, %var_WinText%, %var_ExcludeTitle%, %var_ExcludeText%
}

;[窗口置顶切换 开始]
/*
 * 函数: SetWindowTop
 * 参数说明:
 * Action      - "Toggle" (自动切换), "On" (强制开启), "Off" (强制关闭)
 * ShowBorder  - True (开启边框), False (关闭边框)
 * BorderColor - 边框颜色 (如 "Red", "Blue", "0xFF00FF" 等)
 * Thickness   - 边框粗细 (整数，代表像素大小)
 * Alpha       - 边框透明度 (0-255，0 完全透明，255 完全不透明)
 * WinAlpha    - 窗口透明度 (0-255，0 完全透明，255 完全不透明，默认不变)
 * WinTitle    - 目标窗口，默认 "A" 代表当前激活的主窗口
 */
win_SetWindowTop_xy(Action := "Toggle", ShowBorder := True, BorderColor := "Red", Thickness := 3, Alpha := 255, WinAlpha := "", WinTitle := "A") {
    global BorderTrackers
    if !IsObject(BorderTrackers)
        BorderTrackers := {}

    ; 1. 获取目标窗口的顶级主句柄 (HWND)
    WinGet, rawHWND, ID, %WinTitle%
    if !rawHWND
        return

    ; 寻根算法: 确保抓取的是主窗口而非子控件
    targetHWND := DllCall("GetAncestor", "Ptr", rawHWND, "UInt", 2, "Ptr")
    if !targetHWND
        targetHWND := rawHWND

    ; 2. 判断当前状态
    ; 【核心修复: 状态解耦】
    ; 既然寻根算法可靠，直接读取系统原生的置顶标志位 (0x8)，不再依赖边框记录。
    WinGet, ExStyle, ExStyle, ahk_id %targetHWND%
    isTop := (ExStyle & 0x8) ? True : False

    ; 3. 决定最终状态
    if (Action = "Toggle" || Action = 2)
        newState := !isTop
    else if (Action = "On" || Action = 1)
        newState := True
    else if (Action = "Off" || Action = 0)
        newState := False
    else
        return

    ; 4. 执行置顶/取消置顶 与 窗口自身透明度调节
    if (newState) {
        WinSet, AlwaysOnTop, On, ahk_id %targetHWND%
        if (WinAlpha != "")
            WinSet, Transparent, %WinAlpha%, ahk_id %targetHWND%
    }
    else {
        WinSet, AlwaysOnTop, Off, ahk_id %targetHWND%
        if (WinAlpha != "")
            WinSet, Transparent, Off, ahk_id %targetHWND%
    }

    ; 5. 边框逻辑处理
    if (newState && ShowBorder) {
        ; 如果属性有变，先销毁旧的
        if BorderTrackers.HasKey(targetHWND) {
            if (BorderTrackers[targetHWND].Color != BorderColor
                || BorderTrackers[targetHWND].Thick != Thickness
                || BorderTrackers[targetHWND].Alpha != Alpha) {
                GuiName := BorderTrackers[targetHWND].GuiName
                Gui, %GuiName%: Destroy
                BorderTrackers.Delete(targetHWND)
            }
        }

        ; 创建新边框 GUI
        if !BorderTrackers.HasKey(targetHWND) {
            GuiName := "Border_" targetHWND

            Gui, %GuiName%: New, -Caption +AlwaysOnTop +ToolWindow +Disabled +E0x20 +E0x80000 +E0x08000000 +HwndBorderHWND
            Gui, %GuiName%: Color, %BorderColor%
            Gui, %GuiName%: +Owner%targetHWND%
            WinSet, Transparent, 0, ahk_id %BorderHWND%

            BorderTrackers[targetHWND] := { Border: BorderHWND, GuiName: GuiName, Thick: Thickness, Color: BorderColor, Alpha: Alpha, IsReady: False }
        }

        UpdateWindowBorder(targetHWND)
        SetTimer, UpdateAllBorders, 15
    }
    else {
        ; 如果关闭置顶，或者处于置顶但要求不显示边框(ShowBorder=False)，清理现有边框
        if BorderTrackers.HasKey(targetHWND) {
            GuiName := BorderTrackers[targetHWND].GuiName
            Gui, %GuiName%: Destroy
            BorderTrackers.Delete(targetHWND)
        }
    }
}

; --- 辅助函数: 定时刷新所有边框 ---
UpdateAllBorders() {
    global BorderTrackers
    for hwnd, obj in BorderTrackers {
        UpdateWindowBorder(hwnd)
    }
}

; --- 辅助函数: 精准计算切割区域并绘制 ---
UpdateWindowBorder(hwnd) {
    global BorderTrackers
    if !BorderTrackers.HasKey(hwnd)
        return

    obj := BorderTrackers[hwnd]
    GuiName := obj.GuiName
    BorderHWND := obj.Border
    T := obj.Thick
    A := obj.Alpha

    IfWinNotExist, ahk_id %hwnd%
    {
        Gui, %GuiName%: Destroy
        BorderTrackers.Delete(hwnd)
        return
    }

    WinGet, style, Style, ahk_id %hwnd%
    if (style & 0x20000000) {
        Gui, %GuiName%: Hide
        return
    }

    GetRealPos(hwnd, X, Y, W, H)
    if (W = "" || H = "") {
        Gui, %GuiName%: Hide
        return
    }

    DllCall("SetWindowPos", "Ptr", BorderHWND, "Ptr", 0, "Int", X, "Int", Y, "Int", W, "Int", H, "UInt", 0x0054)

    oX := 0, oY := 0
    oX2 := W, oY2 := H
    iX := T, iY := T
    iX2 := W - T, iY2 := H - T
    RegionStr := oX "-" oY " " oX2 "-" oY " " oX2 "-" oY2 " " oX "-" oY2 " " oX "-" oY " " iX "-" iY " " iX2 "-" iY " " iX2 "-" iY2 " " iX "-" iY2 " " iX "-" iY
    WinSet, Region, %RegionStr%, ahk_id %BorderHWND%

    if (!obj.IsReady) {
        WinSet, Transparent, %A%, ahk_id %BorderHWND%
        obj.IsReady := True
    }
}
;[窗口置顶切换 结束]

; [窗口置底函数]
; 参数 Action: "Toggle"(切换), "On"(置底), "Off"(取消置底)
; 参数 WinTitle: 目标窗口，默认为 "A" (当前活动窗口)
Win_Bottom_xy(Action:="Toggle", WinTitle:="A") {
    global winBottomList

    Child_ID := WinExist(WinTitle)
    if (!Child_ID)
        return

    ; 确保记录存在
    if (!winBottomList.HasKey(Child_ID))
        winBottomList[Child_ID] := False

    ; 根据 Action 确定目标状态
    currentState := winBottomList[Child_ID]
    if (Action = "Toggle")
        TargetState := !currentState
    else if (Action = "On")
        TargetState := True
    else if (Action = "Off")
        TargetState := False
    else
        return ; 输入非法参数则直接返回

    ; 执行状态变更
    if (TargetState && !currentState) {
        ; --- 置底 ---
        ; 自动寻找正确的桌面句柄 (兼容 Progman 和 WorkerW)
        WinGet, Desktop_ID, ID, ahk_class Progman
        if (!Desktop_ID)
            WinGet, Desktop_ID, ID, ahk_class WorkerW

        DllCall("SetParent", "Ptr", Child_ID, "Ptr", Desktop_ID)
        winBottomList[Child_ID] := True

    } else if (!TargetState && currentState) {
        ; --- 取消置底 ---
        DllCall("SetParent", "Ptr", Child_ID, "Ptr", 0)
        winBottomList[Child_ID] := False
    }
}

;[管理其他窗口（最小化或关闭）]
; 函数：ManageOtherWindows
; 参数：
;   - targetWindow (字符串): 需要保留的窗口标识。默认为 "A"（当前激活窗口）。
;   - action (字符串): 执行的动作，"Minimize"（最小化，默认值）或 "Close"（关闭）。
ManageOtherWindows_xy(targetWindow := "A", action := "Minimize") {
    ; 1. 保存当前的隐藏窗口检测状态，避免污染脚本其他部分的设置
    prevDetectHidden := A_DetectHiddenWindows
    DetectHiddenWindows, Off

    ; 2. 获取需要保留的目标窗口的句柄
    targetHwnd := WinExist(targetWindow)

    ; 如果指定的目标窗口不存在，则直接恢复设置并退出，防止误操作所有窗口
    if (!targetHwnd) {
        DetectHiddenWindows, %prevDetectHidden%
        return
    }

    ; 3. 枚举当前系统的所有窗口
    WinGet, windowList, List

    Loop %windowList% {
        currentHwnd := windowList%A_Index%

        ; 跳过我们需要保留的那个目标窗口
        if (currentHwnd = targetHwnd)
            continue

        ; 获取当前遍历到的窗口的各项信息
        WinGetTitle, winTitle, ahk_id %currentHwnd%
        WinGetClass, winClass, ahk_id %currentHwnd%
        WinGet, winStyle, Style, ahk_id %currentHwnd%

        ; 4. 过滤系统底层窗口以及 Win10/11 的不可见 UI 窗口
        if (winTitle = "" || winClass = "Shell_TrayWnd" || winClass = "Progman" || winClass = "WorkerW" || winClass = "Windows.UI.Core.CoreWindow")
            continue

        ; 过滤不具备可见属性的窗口 (WS_VISIBLE = 0x10000000)
        if !(winStyle & 0x10000000)
            continue

        ; 5. 根据传入的参数执行对应的操作
        if (action = "Close") {
            WinClose, ahk_id %currentHwnd%
        } else {
            WinMinimize, ahk_id %currentHwnd%
        }
    }

    ; 6. 恢复最初始的环境设置
    DetectHiddenWindows, %prevDetectHidden%
}

;[窗口等比例缩放]
ScaleWindow(WinTitle, Scale) {
    ; 获取指定窗口的位置和大小
    WinGetPos, X, Y, Width, Height, %WinTitle%

    ; 如果找不到窗口，则直接退出函数，避免报错
    if (Width = "")
        return

    ; 计算新的宽度和高度
    NewWidth := Width * Scale
    NewHeight := Height * Scale

    ; 计算新的 X 和 Y 坐标，保持窗口中心点不变
    NewX := X + (Width - NewWidth) / 2
    NewY := Y + (Height - NewHeight) / 2

    ; 移动并调整窗口大小
    WinMove, %WinTitle%,, %NewX%, %NewY%, %NewWidth%, %NewHeight%
}

;[控制滚动条移动的函数]
;0x0115垂直滚动条  0x0114水平滚动条
;move_Scroll_Bar("0x0115","1")   ;向下滚动一行
;move_Scroll_Bar("0x0115","0")   ;向上滚动一行
;move_Scroll_Bar("0x0114","1")   ;向右滚动一行
;move_Scroll_Bar("0x0114","0")   ;向左滚动一行
move_Scroll_Bar(MsgNumber:="0x0115",wParam:="1",WinTitle:="A"){
    ControlGetFocus, control, %WinTitle%
    SendMessage, %MsgNumber%, %wParam%, 0, %control%, %WinTitle%
}

;[窗口功能开关函数]
; 核心功能函数
; 参数顺序: (窗口标题, 最小化, 最大化, 调整大小, 移动, 关闭按钮)
; 可选值: "On" (开启), "Off" (关闭), "Toggle" (自动切换), "" (留空表示不修改)
SetWindowFeatures_xy(WinTitle, p_Min:="", p_Max:="", p_Resize:="", p_Move:="", p_Close:="") {
    hWnd := WinExist(WinTitle)
    if (!hWnd) {
        MsgBox, 48, 提示, 找不到指定的窗口！
        return false
    }

    ; --- 1. 读取当前所有状态 ---
    WinGet, curStyle, Style, ahk_id %hWnd%
    hSysMenu := DllCall("GetSystemMenu", "Ptr", hWnd, "Int", False, "Ptr")

    ; 解析当前样式状态 (1 为开启，0 为关闭)
    curMin := (curStyle & 0x20000) ? 1 : 0
    curMax := (curStyle & 0x10000) ? 1 : 0
    curRes := (curStyle & 0x40000) ? 1 : 0

    ; 解析系统菜单状态：0xF010=移动, 0xF060=关闭
    moveState := DllCall("GetMenuState", "Ptr", hSysMenu, "UInt", 0xF010, "UInt", 0)
    curMove := (moveState != -1) ? 1 : 0  ; 不等于 -1 说明菜单项存在

    closeState := DllCall("GetMenuState", "Ptr", hSysMenu, "UInt", 0xF060, "UInt", 0)
    curClose := (closeState & 1) ? 0 : 1  ; 1 代表 MF_GRAYED 置灰禁用，这里反转一下逻辑

    ; --- 2. 计算每个属性的目标状态 ---
    ; 如果传入 "", 则沿用 cur 当前状态
    newMin := (p_Min = "Toggle") ? !curMin : (p_Min = "On") ? 1 : (p_Min = "Off") ? 0 : curMin
    newMax := (p_Max = "Toggle") ? !curMax : (p_Max = "On") ? 1 : (p_Max = "Off") ? 0 : curMax
    newRes := (p_Resize = "Toggle") ? !curRes : (p_Resize = "On") ? 1 : (p_Resize = "Off") ? 0 : curRes
    newMove := (p_Move = "Toggle") ? !curMove : (p_Move = "On") ? 1 : (p_Move = "Off") ? 0 : curMove
    newClose := (p_Close = "Toggle") ? !curClose : (p_Close = "On") ? 1 : (p_Close = "Off") ? 0 : curClose

    ; --- 3. 应用：窗口样式 (最小化 / 最大化 / 调整大小) ---
    if (newMin != curMin)
        WinSet, Style, % newMin ? "+0x20000" : "-0x20000", ahk_id %hWnd%
    if (newMax != curMax)
        WinSet, Style, % newMax ? "+0x10000" : "-0x10000", ahk_id %hWnd%
    if (newRes != curRes)
        WinSet, Style, % newRes ? "+0x40000" : "-0x40000", ahk_id %hWnd%

    ; --- 4. 应用：系统菜单 (移动 / 关闭) ---
    ; 只有当移动或关闭的真实状态发生改变时，才去重写系统菜单
    if (newMove != curMove || newClose != curClose) {
        ; 必须先让 Windows 将菜单重置为默认状态，再单独移除不需要的项
        DllCall("GetSystemMenu", "Ptr", hWnd, "Int", True, "Ptr")
        hSysMenu := DllCall("GetSystemMenu", "Ptr", hWnd, "Int", False, "Ptr")

        ; 如果目标是关闭，则移除或置灰
        if (!newMove)
            DllCall("RemoveMenu", "Ptr", hSysMenu, "UInt", 0xF010, "UInt", 0)
        if (!newClose)
            DllCall("EnableMenuItem", "Ptr", hSysMenu, "UInt", 0xF060, "UInt", 1) ; 1 = MF_GRAYED
    }

    ; --- 5. 强制刷新窗口渲染 ---
    DllCall("DrawMenuBar", "Ptr", hWnd)
    WinSet, Redraw,, ahk_id %hWnd%

    return true
}

;[窗口移动函数]
; 核心函数：MoveWindow (支持多显示器)
; 参数1: WinTitle - 窗口标题 (例如 "A" 代表当前活动窗口)
; 参数2: Pos      - 目标位置字符串
MoveWindow_xy(WinTitle, Pos) {
    ; 1. 获取目标窗口的当前位置和尺寸
    WinGet, targetHWND, ID, %WinTitle%
    ;WinGetPos, winX, winY, winW, winH, %WinTitle%
    GetRealPos(targetHWND, winX, winY, winW, winH)
    if (winW = "")
        return

    ; 计算窗口的中心点坐标，用于判断窗口当前属于哪个显示器
    winCenterX := winX + (winW / 2)
    winCenterY := winY + (winH / 2)

    ; 2. 获取系统中显示器的总数
    SysGet, monitorCount, MonitorCount
    targetMonitor := 1 ; 默认设为主屏

    ; 3. 遍历所有显示器，判断窗口中心点落在哪个显示器内
    Loop, %monitorCount% {
        ; 获取第 A_Index 个显示器的完整边界 (变量名生成 monLeft, monTop, monRight, monBottom)
        SysGet, mon, Monitor, %A_Index%

        if (winCenterX >= monLeft && winCenterX <= monRight && winCenterY >= monTop && winCenterY <= monBottom) {
            targetMonitor := A_Index
            break ; 找到了窗口所在的显示器，跳出循环
        }
    }

    ; 4. 获取目标显示器的“工作区”尺寸（排除该屏幕的任务栏）
    ; (变量名生成 WALeft, WATop, WARight, WABottom)
    SysGet, WA, MonitorWorkArea, %targetMonitor%

    ; 计算该显示器可用区域的宽度和高度
    screenWidth := WARight - WALeft
    screenHeight := WABottom - WATop

    ; 初始化目标坐标为窗口当前坐标
    targetX := winX
    targetY := winY

    ; 5. 基于该显示器的工作区进行坐标计算
    if (Pos = "左上角") {
        targetX := WALeft
        targetY := WATop
    }
    else if (Pos = "中间上侧") {
        targetX := WALeft + (screenWidth - winW) / 2
        targetY := WATop
    }
    else if (Pos = "右上角") {
        targetX := WARight - winW
        targetY := WATop
    }
    else if (Pos = "中间左侧") {
        targetX := WALeft
        targetY := WATop + (screenHeight - winH) / 2
    }
    else if (Pos = "正中央") {
        targetX := WALeft + (screenWidth - winW) / 2
        targetY := WATop + (screenHeight - winH) / 2
    }
    else if (Pos = "中间右侧") {
        targetX := WARight - winW
        targetY := WATop + (screenHeight - winH) / 2
    }
    else if (Pos = "左下角") {
        targetX := WALeft
        targetY := WABottom - winH
    }
    else if (Pos = "中间下侧") {
        targetX := WALeft + (screenWidth - winW) / 2
        targetY := WABottom - winH
    }
    else if (Pos = "右下角") {
        targetX := WARight - winW
        targetY := WABottom - winH
    }
    else if (Pos = "水平居中") {
        targetX := WALeft + (screenWidth - winW) / 2
        ; targetY 保持不变
    }
    else if (Pos = "垂直居中") {
        ; targetX 保持不变
        targetY := WATop + (screenHeight - winH) / 2
    }

    ; 6. 移动窗口
    WinMove, %WinTitle%, , %targetX%, %targetY%
}

;[强制贴边隐藏当前窗口]
ForceEdgeHide_xy(edge, WinTitle:="A") {
    global HiddenWindows, AutoHideProtrude, GhostHwnd, AutoHideTopmost

    targetHwnd := WinExist(WinTitle)
    ; 排除无效窗口或自身的幽灵窗口
    if (!targetHwnd || targetHwnd = GhostHwnd)
        return

    ; 如果该窗口已经是隐藏状态，直接返回防止冲突
    if (HiddenWindows.HasKey(targetHwnd))
        return

    ; 获取窗口真实和标准位置
    GetRealPos(targetHwnd, realX, realY, realW, realH)
    if (realW = "")
        return

    WinGetPos, sX, sY, sW, sH, ahk_id %targetHwnd%
    diffX := sX - realX, diffY := sY - realY

    ; 寻找窗口中心点所在的显示器
    winCenterX := realX + (realW / 2)
    winCenterY := realY + (realH / 2)
    SysGet, monitorCount, MonitorCount
    targetMonitor := 1
    Loop, %monitorCount% {
        SysGet, mon, Monitor, %A_Index%
        if (winCenterX >= monLeft && winCenterX <= monRight && winCenterY >= monTop && winCenterY <= monBottom) {
            targetMonitor := A_Index
            break
        }
    }

    ; 获取该显示器的工作区
    SysGet, mon, MonitorWorkArea, %targetMonitor%

    ; 计算贴靠到屏幕边缘后的 shownX / shownY (展示状态的坐标)
    shownX := sX
    shownY := sY

    if (edge = "Top")
        shownY := monTop + diffY
    else if (edge = "Bottom")
        shownY := monBottom - realH + diffY
    else if (edge = "Left")
        shownX := monLeft + diffX
    else if (edge = "Right")
        shownX := monRight - realW + diffX
    else
        return ; 非法参数直接退出

    ; 记录窗口原有样式，以便后续恢复
    WinGet, exStyle, ExStyle, ahk_id %targetHwnd%
    origTopmost := (exStyle & 0x8) ? 1 : 0

    ; 计算隐藏缩进后的坐标
    hiddenX := shownX, hiddenY := shownY
    if (edge == "Top")
        hiddenY := shownY - realH + AutoHideProtrude
    else if (edge == "Bottom")
        hiddenY := shownY + realH - AutoHideProtrude
    else if (edge == "Left")
        hiddenX := shownX - realW + AutoHideProtrude
    else if (edge == "Right")
        hiddenX := shownX + realW - AutoHideProtrude

    ; 将窗口信息写入贴边隐藏专用的全局监控字典
    HiddenWindows[targetHwnd] := { edge: edge
        , state: "hidden"
        , hoverTime: 0
        , leaveTime: 0
        , origTopmost: origTopmost
        , shownX: shownX, shownY: shownY
        , hiddenX: hiddenX, hiddenY: hiddenY
        , w: sW, h: sH
        , realW: realW, realH: realH
        , isFullyHidden: false
        , isResizing: false }

    ; 智能兼容：动态检测当前显示器的任务栏位置，处理置顶逻辑
    tbEdge := GetTaskbarEdgeByPos(shownX + sW/2, shownY + sH/2)
    if (AutoHideTopmost || edge != tbEdge)
        WinSet, Topmost, On, ahk_id %targetHwnd%
    else if (!origTopmost)
        WinSet, Topmost, Off, ahk_id %targetHwnd%

    ; 启动贴边隐藏的系统监视器
    SetTimer, AutoHideTracker, 50

    ; 强制触发一次隐藏动画，从窗口当前位置直接平滑吸入到边缘
    DoAnimateWindow(targetHwnd, sX, sY, hiddenX, hiddenY, sW, sH)
}

;[打开当前窗口进程所在目录] v1.0.7===============================================================================================
;openFolder：填写第三方文件管理器全路径打开文件夹，可选填，特殊写法：%"无路径软件"%
;openParams：第三方文件管理器的打开参数，可选填

win_folder_zz(WinTitle:="A",openFolder:="",openParams:=""){
    WinGet,path,ProcessPath ,%WinTitle%
    if(openFolder){
        if(openParams!="")
            openParams:=A_Space openParams
        Run,%openFolder%%openParams%%A_Space%"%path%"
    }else{
        ;Run,% "explorer.exe /select," path
        pidl:= 0
        DllCall("shell32\SHParseDisplayName","Str",path,"Ptr",0,"PtrP",pidl,"UInt",0,"Ptr",0) ; 解析文件路径获取 PIDL
        DllCall("shell32\SHOpenFolderAndSelectItems","Ptr",pidl,"UInt",0,"Ptr",0,"UInt",0)  ; 在资源管理器中打开并选中文件
        DllCall("ole32\CoTaskMemFree","Ptr",pidl) ; 释放 PIDL 内存
    }
}

;[窗口优先级]
;Level 应该为下列字母或单词的其中一个: L(或 Low)(低), B(或 BelowNormal)(低于标准), N(或 Normal)(普通), A(或 AboveNormal)(高于标准), H(或 High)(高), R(或 Realtime)(实时).
win_priority_zz(WinTitle:="A",Levelval:=""){
    WinGet,pid,PID,%WinTitle%
    if !(Levelval = "")
        Process, Priority, %pid%, %Levelval%
    else
        Process, Priority, %pid%, Normal
}

;[everything文档定位]
locationpath_xy(WinTitle:="A", evpath:=""){
    WinGetTitle, str, %WinTitle%

    ; 1. 解决 Notepad2、Notepad3 正编辑时标题带 "*" 的问题
    if (SubStr(str, 1, 1) = "*")
        str := SubStr(str, 3)

    ; 2. 正则精简：一步剥离窗口标题的程序名（例如 " - 记事本"），仅保留文件名
    str := RegExReplace(str, "(\.[^\.\s]+)\s+.*$", "$1")

    ; 3. 精简 Everything 路径获取逻辑，避免多重嵌套 if
    DetectHiddenWindows, On
    WinGet, ev1, ProcessPath, ahk_exe everything64.exe
    WinGet, ev2, ProcessPath, ahk_exe everything.exe
    DetectHiddenWindows, Off

    evpathget := ev1 ? ev1 : (ev2 ? ev2 : evpath)

    ; 4. 路径校验
    if not FileExist(evpathget) {
        ttip("请填写everything程序完整路径", "3000")
        return ; 【注】：原代码缺 return，若路径不存在仍强行 Run 会导致弹窗报错，此处补上以阻断执行
    }

    ; 5. 执行搜索
    Run, %evpathget% -s "wfn:ww:case:file:"""%str%"""
    ;Run, %plusxy_Path% -s "dateaccessed:today wfn:ww:case:file:"""%str%"""
}

;[ToolTip提示，不使用 Sleep(它会停止当前线程)]
;text内容，time显示时间,at显示长度, at显示宽度，divider省略词
ttip(text:="",time:="5000",at:="100", ay:="20",divider="......"){
    time:= - time
    ;MsgBox, %time%
    text2:=""
    if InStr(text, "`n"){
        Loop, parse, text, `n, `r
        {
            if (RegExMatch(A_LoopField, "^\s*$")) ;匹配空白行
                Continue
            if (strLen(A_LoopField) > at)
                text2 :=text2 . A_Index " " subStr(A_LoopField, 1, at/2) . divider . subStr(A_LoopField, -at/2) "`n"
            Else
                text2 :=text2 . A_Index " " A_LoopField "`n"
            if (A_Index > ay)
                Break
        }
    }Else
        text2:=分割字符串(text,at,"`n")
    ToolTip,%text2%
    SetTimer, RemoveToolTip, %time%
    return
}
分割字符串(字符串:="",间隔长度:="50",间隔词:="`n"){
    pattern := ".{1," 间隔长度 "}"
    ; 创建一个空数组来存储匹配的结果
    matches := []
    ; 使用循环提取每10个字符
    while (RegExMatch(字符串, pattern, match)) {
        matches.Push(match) ; 将匹配的结果添加到数组中
        字符串 := SubStr(字符串, StrLen(match) + 1) ; 从文本中去掉已匹配的部分
    }
    ; 输出结果
    result:=""
    for index, value in matches {
        ;MsgBox, % "匹配结果 " index ": " value
        result:=result . index " " value . 间隔词
        if (index>20)
            Break
    }
    ;MsgBox, % result
    Return result
}
RemoveToolTip:
    ToolTip
return

;[将指定窗口窗口移动到 指定显示器]
; 函数：MoveWindowToMonitor
; 参数：
;   winTitle       - 窗口标题（例如 "ahk_exe notepad.exe" 或 "A" 代表当前窗口）
;   targetMonitor  - 目标显示器编号（1, 2, 3...）
MoveWindowToMonitor(winTitle, targetMonitor) {
    ; 1. 获取系统中连接的显示器总数
    SysGet, monitorCount, MonitorCount
    if (targetMonitor > monitorCount || targetMonitor < 1) {
        ttip("错误, 目标显示器" targetMonitor " 不存在！当前共有" monitorCount " 个显示器。", "3000")
        return
    }

    ; 2. 检查目标窗口是否存在
    if !WinExist(winTitle) {
        ttip("错误, 找不到指定的窗口。", "3000")
        return
    }

    ; 3. 获取目标显示器的工作区坐标（排除任务栏的可用区域）
    ; 这会生成 monLeft, monTop, monRight, monBottom 四个变量
    SysGet, mon, MonitorWorkArea, %targetMonitor%

    ; 4. 获取窗口当前的状态 (-1: 最小化, 0: 正常, 1: 最大化)
    WinGet, winState, MinMax, %winTitle%

    ; 如果窗口处于最小化或最大化状态，需要先还原它才能准确移动和获取尺寸
    if (winState != 0) {
        WinRestore, %winTitle%
        Sleep, 50  ; 稍微等待一下窗口恢复动画
    }

    ; 5. 获取窗口当前的尺寸 (宽度和高度)
    WinGetPos, winX, winY, winW, winH, %winTitle%

    ; 6. 计算新坐标（这里将窗口移动到目标显示器的正中间）
    ; 如果你想移动到左上角，可以直接用 newX := monLeft, newY := monTop
    newX := monLeft + (monRight - monLeft - winW) / 2
    newY := monTop + (monBottom - monTop - winH) / 2

    ; 确保窗口不会超出目标显示器的左上边界
    if (newX < monLeft)
        newX := monLeft
    if (newY < monTop)
        newY := monTop

    ; 7. 移动窗口到新位置
    WinMove, %winTitle%, , %newX%, %newY%, %winW%, %winH%

    ; 8. 如果窗口原本是最大化状态，移动到新显示器后再把它最大化
    if (winState == 1) {
        Sleep, 50
        WinMaximize, %winTitle%
    }
}

;[复制窗口信息]
CopyWin(winTitle:="A",Output:="Title"){
    if (Output = "Title")
        WinGetTitle, copystr, %winTitle%
    if (Output = "commandline"){
        WinGet pid, PID, %winTitle%
        ; 获取 WMI 服务对象.
        wmi := ComObjGet("winmgmts:")
        ; 执行查询以获取匹配进程.
        queryEnum := wmi.ExecQuery(""
            . "Select * from Win32_Process where ProcessId=" . pid)
            ._NewEnum()
        ; 获取首个匹配进程.
        if queryEnum[proc]
            copystr:= proc.CommandLine
        else
            ttip("未找到", "3000")
        ; 释放所有全局对象(使用局部变量时不需要这么做).
        wmi := queryEnum := proc := ""
    }
    if (Output = "exePath")
        WinGet,copystr,ProcessPath ,%WinTitle%
    Clipboard := copystr
}
;[框选并调整指定窗口]
KuangXuan_xy(WinTitle:="A"){
    ; 在鼠标点击前，获取当前活动窗口的唯一句柄 (ID)
    WinGet, TargetID, ID, %WinTitle%
    TargetWindow := "ahk_id " . TargetID

    if (TargetID = "") {
        return
    }
    ; 调用框选调整函数
    KuangXuanResize(TargetWindow)
}
; ==========================================================
; 【核心函数】框选并调整指定窗口 (支持取消, 并处理置顶)
; ==========================================================
KuangXuanResize(WinTitle) {
    CoordMode, Mouse, Screen
    CoordMode, ToolTip, Screen

    ; 【关键修复1】记录窗口初始的“总是置顶”状态，并暂时开启它
    WinGet, originalExStyle, ExStyle, %WinTitle%
    ; WS_EX_TOPMOST 标志是 0x8，通过位运算检查它是否存在
    isInitiallyTopMost := originalExStyle & 0x8

    ; 暂时开启置顶，防止在框选时被覆盖
    WinSet, AlwaysOnTop, On, %WinTitle%

    ToolTip, 按住鼠标左键并移动进行框选`n按 ESC 键或鼠标右键取消

    ; 等待用户按下左键，监控取消键
    Loop {
        if GetKeyState("LButton", "P") {
            break ; 按下了左键，进入拖拽阶段
        }
        if GetKeyState("Esc", "P") || GetKeyState("RButton", "P") {
            ToolTip ; 取消提示框

            ; 【关键修复2】取消时，必须还原窗口的原始置顶状态
            if !isInitiallyTopMost
                WinSet, AlwaysOnTop, Off, %WinTitle%

            return  ; 退出函数
        }
        Sleep, 10
    }

    ; 用户按下左键后，关闭提示
    ToolTip

    ; 记录框选起始坐标
    MouseGetPos, startX, startY

    ; 创建一个半透明的蓝色 GUI 作为框选视觉反馈
    Gui, SelectionBox: +AlwaysOnTop -Caption +Border +ToolWindow +LastFound
    Gui, SelectionBox: Color, 0078D7
    WinSet, Transparent, 80

    IsCancelled := false

    ; 循环追踪鼠标位置，直到松开左键
    Loop {
        ; 如果松开了鼠标左键，则正常结束拖拽
        if !GetKeyState("LButton", "P")
            break

        ; 拖拽过程中取消
        if GetKeyState("Esc", "P") || GetKeyState("RButton", "P") {
            IsCancelled := true
            break
        }

        MouseGetPos, currentX, currentY

        if (currentX < startX) {
            X := currentX
            W := startX - currentX
        } else {
            X := startX
            W := currentX - startX
        }

        if (currentY < startY) {
            Y := currentY
            H := startY - currentY
        } else {
            Y := startY
            H := currentY - startY
        }

        ; 实时更新框选 GUI
        Gui, SelectionBox: Show, x%X% y%Y% w%W% h%H% NoActivate
        Sleep, 10
    }

    ; 拖拽结束或被取消，销毁框选框
    Gui, SelectionBox: Destroy

    ; 【关键修复3】动作结束，必须还原窗口的原始置顶状态
    if !isInitiallyTopMost
        WinSet, AlwaysOnTop, Off, %WinTitle%

    ; 处理取消情况
    if (IsCancelled) {
        ToolTip, 已取消框选
        SetTimer, RemoveToolTip, -1000
        return
    }

    ; 防误触判断，调整窗口
    if (W > 20 && H > 20) {
        if WinExist(WinTitle) {
            WinGet, winState, MinMax, %WinTitle%
            if (winState = 1)
                WinRestore, %WinTitle%

            ; 将窗口移动并调整到框选的区域
            WinMove, %WinTitle%, , %X%, %Y%, %W%, %H%

            ; 【体验优化】移动完成后，再次激活该窗口，确保其在最前层且获得焦点
            WinActivate, %WinTitle%
        }
    }
}

ToggleRollUp_xy(WinTitle:="A",MinHeight := 25) {
    ; 使用静态关联数组来记录多个窗口的原始高度：{ 窗口句柄: 原始高度 }
    static RolledWindows := {}

    WinGet, hwnd, ID, %WinTitle%

    ; 确保获取到了有效的句柄
    if (!hwnd)
        return

    ; 检查该窗口是否已经在记录列表里（即是否已经是卷起状态）
    if (RolledWindows.HasKey(hwnd)) {
        ; --- 恢复窗口 ---
        origHeight := RolledWindows[hwnd]

        ; 恢复到原始高度
        WinMove, ahk_id %hwnd%, , , , , %origHeight%

        ; 从记录中移除该窗口
        RolledWindows.Delete(hwnd)

    } else {
        ; --- 卷起窗口 ---
        ; 获取当前窗口的位置和尺寸
        WinGetPos, x, y, w, h, ahk_id %hwnd%

        ; 【安全处理】如果窗口当前是最大化状态，改变高度会失效或导致排版错乱
        ; 因此先将其还原为普通窗口，并重新获取高度
        WinGet, winState, MinMax, ahk_id %hwnd%
        if (winState == 1) {
            WinRestore, ahk_id %hwnd%
            WinGetPos, x, y, w, h, ahk_id %hwnd%
        }

        ; 记录它的原始高度
        RolledWindows[hwnd] := h

        ; 动态获取系统 UI 尺寸，计算出精确的标题栏高度
        SysGet, captionHeight, 4      ; SM_CYCAPTION (标题栏高度)
        SysGet, frameHeight, 33       ; SM_CYSIZEFRAME (可调边框厚度)
        SysGet, paddedBorder, 92      ; SM_CXPADDEDBORDER (边框填充)

        ; 卷起后的目标高度
        rollHeight := captionHeight + frameHeight + paddedBorder

        ; 给个保底值，防止某些无边框窗口计算出 0 导致窗口消失
        if (rollHeight < MinHeight) {
            rollHeight := MinHeight
        }

        ; 执行卷起（只改变高度，不改变 X, Y, W）
        WinMove, ahk_id %hwnd%, , , , , %rollHeight%
    }
}

;[复制窗口截图]
; 函数：CopyActiveWindowGdip
; 作用：使用 GDI+ 抓取当前活动窗口并写入剪贴板 (无按键模拟)
; 返回值：成功返回 true，失败返回 false
CopyActiveWindowGdip_xy(WinTitle:="A") {
    ; 1. 启动 GDI+ 引擎
    ;pToken := Gdip_Startup()
    if !pToken {
        MsgBox, 48, 错误, GDI+ 启动失败！`n请确认已正确下载并引入 Gdip_All.ahk。
        return false
    }

    ; 2. 获取当前处于最前方的活动窗口的句柄 (HWND)
    WinGet, activeHwnd, ID, %WinTitle%
    if !activeHwnd {
        ;Gdip_Shutdown(pToken)
        return false
    }

    ; 3. 让 GDI+ 根据窗口句柄在内存中生成一张图片 (Bitmap)
    ; 这里的 raster 参数通常留空，默认抓取窗口画面
    pBitmap := Gdip_BitmapFromHWND(activeHwnd)
    if !pBitmap {
        MsgBox, 48, 错误, 无法抓取该窗口的图像。
        ;Gdip_Shutdown(pToken)
        return false
    }

    ; 4. 清空原有剪贴板，并将生成的内存图片直接写入系统剪贴板
    Clipboard := ""
    Gdip_SetBitmapToClipboard(pBitmap)
    ttip("窗口截图(底层抓取)已成功复制到剪贴板！", "3000")
    ; 5. 打扫战场：释放内存图片，关闭 GDI+ 引擎 (非常重要，防止内存泄漏)
    Gdip_DisposeImage(pBitmap)
    ;Gdip_Shutdown(pToken)

    return true
}

;[底层静默切换窗口函数]
SwitchWindowLogic_xy(WinTitle:="A") {
    ; 1. 明确获取当前正在激活的窗口 ID
    WinGet, active_id, ID, %WinTitle%

    ; 2. 获取所有窗口列表
    WinGet, winList, List

    Loop % winList
    {
        this_id := winList%A_Index%

        ; 如果是当前窗口，直接跳过
        if (this_id = active_id)
            continue

        ; 获取窗口的样式和扩展样式
        WinGet, style, Style, ahk_id %this_id%
        WinGet, exStyle, ExStyle, ahk_id %this_id%

        ; 【核心过滤 1】跳过不可见的窗口 (WS_VISIBLE = 0x10000000)
        if !(style & 0x10000000)
            continue

        ; 【核心过滤 2】跳过工具窗口（通常是后台挂起的组件，WS_EX_TOOLWINDOW = 0x00000080）
        if (exStyle & 0x00000080)
            continue

        WinGetTitle, this_title, ahk_id %this_id%
        WinGetClass, this_class, ahk_id %this_id%

        ; 【核心过滤 3】跳过无标题窗口和 Win10/11 的幽灵框架
        if (this_title = "" || this_class = "Progman" || this_class = "WorkerW" || this_class = "Windows.UI.Core.CoreWindow")
            continue

        ; 找到真正有用的上一个窗口了，激活它！
        WinActivate, ahk_id %this_id%
        break
    }
}
;[强制隐藏指定窗口]
win_hide_xy(WinTitle:="A"){
    global HiddenWinsMap, HiddenWinsOrder, MaxRestoreCount

    WinGet, targetHwnd, ID, %WinTitle%
    if (!targetHwnd)
        return

    ; 防呆机制：绝对不能隐藏桌面、任务栏和程序的幽灵窗口本身
    WinGetClass, winClass, ahk_id %targetHwnd%
    if (winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd" || targetHwnd = GhostHwnd) {
        ttip("系统核心窗口，禁止隐藏！", "2000")
        return
    }

    if (!HiddenWinsMap.HasKey(targetHwnd)) {
        HiddenWinsMap[targetHwnd] := true
        HiddenWinsOrder.Push(targetHwnd)

        ; 使用你在设置中配置的最大记录数，先进先出淘汰最早的窗口
        while (HiddenWinsOrder.Length() > MaxRestoreCount) {
            oldHwnd := HiddenWinsOrder.RemoveAt(1)
            HiddenWinsMap.Delete(oldHwnd)
        }

        WinHide, ahk_id %targetHwnd%
        ttip("窗口已隐藏，可在右下角托盘恢复", "2000")

        Gosub, UpdateHiddenWinMenu
        SaveHiddenListToIni()
    }
}

;[强制将指定窗口变为鼠标穿透]
win_clickthrough_xy(WinTitle:="A"){
    global ClickThroughWinsMap, ClickThroughWinsOrder, MaxRestoreCount

    WinGet, targetHwnd, ID, %WinTitle%
    if (!targetHwnd)
        return

    ; 防呆机制：阻止穿透系统核心UI
    WinGetClass, winClass, ahk_id %targetHwnd%
    if (winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd" || targetHwnd = GhostHwnd) {
        ttip("系统核心窗口，禁止穿透！", "2000")
        return
    }

    if (!ClickThroughWinsMap.HasKey(targetHwnd)) {
        WinGet, currentTrans, Transparent, ahk_id %targetHwnd%
        ClickThroughWinsMap[targetHwnd] := {Trans: currentTrans}
        ClickThroughWinsOrder.Push(targetHwnd)

        while (ClickThroughWinsOrder.Length() > MaxRestoreCount) {
            oldHwnd := ClickThroughWinsOrder.RemoveAt(1)
            ClickThroughWinsMap.Delete(oldHwnd)
        }

        ; 原理：在 Windows 中使窗口实现穿透，必须附带 WS_EX_LAYERED 层叠属性
        ; 如果该窗口之前没有设置透明度，强制设为 255 以激活该属性
        if (currentTrans = "")
            WinSet, Transparent, 255, ahk_id %targetHwnd%

        ; 附加 WS_EX_TRANSPARENT 样式
        WinSet, ExStyle, +0x20, ahk_id %targetHwnd%

        ttip("窗口已进入鼠标穿透模式，可在托盘解除", "2000")

        Gosub, UpdateClickThroughMenu
        SaveClickThroughListToIni()
    }
}
;======================================================================================菜单调用的函数[结束]======================================================================================