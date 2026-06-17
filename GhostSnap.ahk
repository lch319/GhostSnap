; 编译exe文件信息及版本号设置
当前工具版本:="1.0.1"                  ;设置版本号
;@Ahk2Exe-Obey U_bits, = "%A_PtrSize%>4" ? "-64bit" : "-32bit"  ;判断位数
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%  ;读取版本号以编译
;@Ahk2Exe-SetMainIcon GhostSnap图标.ico          ; 指定托盘图标文件
;@Ahk2Exe-AddResource GhostSnap图标.ico, 160      ; 替换自带的'蓝色H'图标
;@Ahk2Exe-AddResource GhostSnap图标.ico, 206      ; 替换为 '绿色 S'
;@Ahk2Exe-AddResource GhostSnap图标.ico, 207      ; 替换自带的'红色H'图标
;@Ahk2Exe-AddResource GhostSnap图标.ico, 208      ; 替换为 '红色 S'
;@Ahk2Exe-ExeName %A_ScriptDir%\GhostSnap%U_version%.exe  ; 打包后的exe文件路径
;@Ahk2Exe-SetCompanyName 逍遥xiaoyao        ; 企业信息
;@Ahk2Exe-SetCopyright 逍遥xiaoyao          ; 版权信息
;@Ahk2Exe-SetDescription 把窗口拖拽变成磁铁吸附，靠近边缘自动对齐  ; 文件说明
;@Ahk2Exe-SetFileVersion %U_version%        ; 文件版本
;@Ahk2Exe-SetInternalName GhostSnap        ; 文件内部名
;@Ahk2Exe-SetLanguage 0x0804            ; 区域语言
;@Ahk2Exe-SetName GhostSnap          ; 名称
;@Ahk2Exe-SetProductName GhostSnap        ; 产品名称
;@Ahk2Exe-SetOrigFilename GhostSnap.exe      ; 原始文件名称
;@Ahk2Exe-SetProductVersion %U_version%        ; 产品版本号
;@Ahk2Exe-SetVersion %U_version%          ; 版本号

#NoEnv
#SingleInstance Force
#Persistent
SetBatchLines, -1
SetWinDelay, -1
CoordMode, Mouse, Screen

; 设置标题匹配模式为 2 (包含匹配)，方便黑名单模糊写标题
SetTitleMatchMode, 2

; ==========================================
; 用户配置区
; ==========================================
global CurrentToolVersion := "1.0.1"
global SettingsDir := A_ScriptDir "\GhostSnap.ini" ; 配置文件路径，默认放在脚本同目录下

global SnapDistance := Var_Read("SnapDistance","20","基础配置",SettingsDir,"否")    ; 触发吸附的距离（像素）
global BreakoutDistance := Var_Read("BreakoutDistance","30","基础配置",SettingsDir,"否")  ; 挣脱距离(阻尼感)，必须大于 SnapDistance

global StrictSingleAxisSnap := Var_Read("StrictSingleAxisSnap","0","基础配置",SettingsDir,"否")  ; 默认吸附模式 (1 = 单轴滑动微调，0 = 允许角落双轴锁死)
global EnableGhostWindow := Var_Read("EnableGhostWindow","1","基础配置",SettingsDir,"否")    ; 是否启用幽灵窗口特效
global EnableScreenEdgeSnap := Var_Read("EnableScreenEdgeSnap","1","基础配置",SettingsDir,"否")    ; 是否启用屏幕边缘吸附
global EnableSmartSync := Var_Read("EnableSmartSync","1","基础配置",SettingsDir,"否")   ; 是否启用智能尺寸同步
global SmartSyncKey := Var_Read("SmartSyncKey","Alt","基础配置",SettingsDir,"否")   ; 触发智能尺寸同步的按键

global EnableChaining := Var_Read("EnableChaining","1","基础配置",SettingsDir,"否")    ; 是否启用窗口联动移动

global GhostColor := Var_Read("GhostColor","0078D7","基础配置",SettingsDir,"否")    ; 幽灵窗口颜色，微软经典的系统强调色 (蓝色)，可自定义为其他颜色（格式：RRGGBB）
global GhostOpacity := Var_Read("GhostOpacity","80","基础配置",SettingsDir,"否")  ; 幽灵窗口透明度 (0-255，80 大约是 30% 不透明)

global SnapToggleKey := Var_Read("SnapToggleKey","Shift","基础配置",SettingsDir,"否") ; 临时停止/触发吸附的按键
global RequireKeyToSnap := Var_Read("RequireKeyToSnap","0","基础配置",SettingsDir,"否") ; 是否反向吸附 (0=默认吸附/按住暂停, 1=默认不吸附/按住才吸附)

global DragModKey := Var_Read("DragModKey","LWin","基础配置",SettingsDir,"否","否")  ; 任意位置拖拽窗口按键配置 (留空 "" 表示禁用该模式)
global DragDirectKey := Var_Read("DragDirectKey","XButton1","基础配置",SettingsDir,"否","否")   ; 任意位置拖拽窗口按键配置 (留空 "" 表示禁用该模式)
global ChainModKey := Var_Read("ChainModKey","Ctrl","基础配置",SettingsDir,"否")   ; 触发联动的修饰键 (按住此键拖拽窗口触发)

defaultBlacklist := "FloatingBall悬浮球 ahk_class AutoHotkeyGUI`nahk_exe PixPin.exe`nahk_exe Snipaste.exe`nahk_class Progman`nahk_class WorkerW`nahk_class Shell_TrayWnd`nahk_class TopLevelWindowForOverflow`nahk_class Shell_SecondaryTrayWnd"
global Blacklist := Var_Read("Blacklist", defaultBlacklist, "基础配置", SettingsDir, "否", "是")      ; 窗口黑名单 (原生 WinTitle 语法，换行隔开)
global DragBlacklist := Var_Read("DragBlacklist", "", "基础配置", SettingsDir, "否", "是")      ; 任意位置拖拽黑名单

global AdminLaunch := Var_Read("AdminLaunch","0","基础配置",SettingsDir,"否") ; 是否管理员运行
global AutoRun := Var_Read("AutoRun","0","基础配置",SettingsDir,"否") ; 是否开机自启
global ShowTrayIcon := Var_Read("ShowTrayIcon","1","基础配置",SettingsDir,"否") ; [新增] 是否显示托盘图标

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
; [新增] 初始化时判断是否隐藏图标
if (!ShowTrayIcon)
    Menu, Tray, NoIcon

Menu, Tray, NoStandard
Menu, Tray, Add, 设置中心, OpenSettingsGui
Menu, Tray, Default, 设置中心
Menu, Tray, Add
Menu, Tray, Add, 单轴滑动微调模式 (防角落锁死), ToggleSnapMode
if (StrictSingleAxisSnap)
    Menu, Tray, Check, 单轴滑动微调模式 (防角落锁死)
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
Menu, Tray, Add, 重载脚本, ReloadApp
Menu, Tray, Add, 退出程序, ExitAppRoutine

; --- 全局状态变量 ---
global isMoving := false
global movingHwnd := 0
global ghostVisible := false
global willSnap := false
global snappedX := false, snappedY := false

global dragMode := "system"
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

; --- 初始化幽灵窗口 ---
; 【修改】增加 -DPIScale 参数防止高分屏下幽灵窗口尺寸错乱
Gui, Ghost: +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale +HwndGhostHwnd
Gui, Ghost: Color, % GhostColor
WinSet, Transparent, % GhostOpacity

global hookStart := DllCall("SetWinEventHook", "UInt", 0x000A, "UInt", 0x000A, "Ptr", 0, "Ptr", RegisterCallback("OnMoveStart"), "UInt", 0, "UInt", 0, "UInt", 0)
global hookEnd := DllCall("SetWinEventHook", "UInt", 0x000B, "UInt", 0x000B, "Ptr", 0, "Ptr", RegisterCallback("OnMoveEnd"), "UInt", 0, "UInt", 0, "UInt", 0)

if (CurrentDragModKey != "")
    Hotkey, %CurrentDragModKey% & LButton, DoModDrag, On, UseErrorLevel
if (CurrentDragDirectKey != "")
    Hotkey, %CurrentDragDirectKey%, DoDirectDrag, On, UseErrorLevel

OnExit("Cleanup")
Return

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

; ===========================================================
; 设置中心 GUI 界面逻辑
; ===========================================================
OpenSettingsGui:
    Gui, Settings:Destroy

    Gui, Settings:Font, s9, Microsoft YaHei
    ; [修改] 增大了窗口和 Tab 的高度，以容纳新加的按键配置
    Gui, Settings:Add, Tab3, x10 y10 w460 h360, 基础吸附|外观特效|拖拽与联动|黑名单|系统与高级|关于

    ; --- 标签页 1: 基础吸附 ---
    Gui, Settings:Tab, 1
    Gui, Settings:Add, Text, x30 y45 w150 h20, 触发吸附距离 (像素):
    Gui, Settings:Add, Edit, x190 y43 w80 h20 vGui_SnapDistance Number, %SnapDistance%
    Gui, Settings:Add, UpDown, Range1-100, %SnapDistance%

    Gui, Settings:Add, Text, x30 y75 w150 h20, 挣脱阻尼距离 (像素):
    Gui, Settings:Add, Edit, x190 y73 w80 h20 vGui_BreakoutDistance Number, %BreakoutDistance%
    Gui, Settings:Add, UpDown, Range1-200, %BreakoutDistance%

    Gui, Settings:Add, Checkbox, x30 y115 w300 h20 vGui_StrictSingle Checked%StrictSingleAxisSnap%, 单轴滑动微调模式 (防角落锁死)
    Gui, Settings:Add, Checkbox, x30 y145 w300 h20 vGui_EdgeSnap Checked%EnableScreenEdgeSnap%, 启用屏幕边缘吸附

    Gui, Settings:Add, Checkbox, x30 y175 w130 h20 vGui_SmartSync Checked%EnableSmartSync%, 启用智能尺寸同步
    Gui, Settings:Add, Text, x170 y177 w60 h20, 触发按键:
    Gui, Settings:Add, Edit, x230 y175 w80 h20 vGui_SmartSyncKey, %SmartSyncKey%
    Gui, Settings:Add, Text, x320 y177 w100 h20 cGray, (默认: Alt)

    Gui, Settings:Add, Text, x30 y215 w130 h20, 吸附切换/中断按键:
    Gui, Settings:Add, Edit, x170 y213 w80 h20 vGui_SnapToggleKey, %SnapToggleKey%
    Gui, Settings:Add, Text, x260 y215 w180 h20 cGray, (默认: Shift)

    Gui, Settings:Add, Checkbox, x30 y250 w380 h20 vGui_RequireKeyToSnap Checked%RequireKeyToSnap%, 反向模式：平时不吸附，按住上方按键才触发吸附
    Gui, Settings:Add, Text, x50 y275 w380 h40 cGray, 备注: 勾选此项后，按键逻辑将反转。适合平时不希望频繁触发吸附，仅在特定时刻才需要的用户。

    ; --- 标签页 2: 外外观特效 ---
    Gui, Settings:Tab, 2
    Gui, Settings:Add, Checkbox, x30 y50 w300 h20 vGui_GhostWin Checked%EnableGhostWindow%, 启用幽灵窗口特效

    Gui, Settings:Add, Text, x30 y95 w100 h20, 幽灵窗口颜色:
    Gui, Settings:Add, Edit, x130 y93 w70 h20 vGui_GhostColor Limit6, %GhostColor%
    Gui, Settings:Add, Progress, x210 y93 w20 h20 Background%GhostColor% vColorPreview
    Gui, Settings:Add, Button, x240 y91 w80 h24 gChooseColorBtn, 选择颜色

    Gui, Settings:Add, Text, x30 y145 w100 h20, 透明度 (0-255):
    Gui, Settings:Add, Slider, x125 y145 w200 h30 vGui_GhostOpacity Range0-255 TickInterval25 ToolTip, %GhostOpacity%

    ; --- 标签页 3: 拖拽与联动 ---
    Gui, Settings:Tab, 3
    Gui, Settings:Add, Text, x30 y50 w140 h20, 任意位置拖拽修饰键:
    Gui, Settings:Add, Edit, x170 y48 w100 h20 vGui_DragModKey, %DragModKey%
    Gui, Settings:Add, Text, x280 y50 w150 h20 cGray, (如:LWin 留空则禁用)

    Gui, Settings:Add, Text, x30 y90 w140 h20, 任意位置拖拽直接键:
    Gui, Settings:Add, Edit, x170 y88 w100 h20 vGui_DragDirectKey, %DragDirectKey%
    Gui, Settings:Add, Text, x280 y90 w150 h20 cGray, (如: XButton1 MButton)

    Gui, Settings:Add, Checkbox, x30 y145 w300 h20 vGui_Chaining Checked%EnableChaining%, 启用窗口联动移动

    Gui, Settings:Add, Text, x30 y185 w140 h20, 触发联动修饰键:
    Gui, Settings:Add, Edit, x170 y183 w100 h20 vGui_ChainModKey, %ChainModKey%
    Gui, Settings:Add, Text, x280 y185 w150 h20 cGray, (如: Ctrl, Alt)

    ; --- 标签页 4: 黑名单 ---
    Gui, Settings:Tab, 4
    Gui, Settings:Add, Text, x25 y45 w400 h20, 窗口黑名单 (支持原生 WinTitle 语法，一行一个):
    Gui, Settings:Add, Edit, x25 y70 w410 h115 vGui_Blacklist Multi WantReturn, %Blacklist%
    
    Gui, Settings:Add, Text, x25 y195 w400 h20, 任意拖拽黑名单 (仅针对修饰键/直接键拖拽，一行一个):
    Gui, Settings:Add, Edit, x25 y220 w410 h115 vGui_DragBlacklist Multi WantReturn, %DragBlacklist%

    ; --- 标签页 5: 系统与高级 [新增] ---
    Gui, Settings:Tab, 5
    Gui, Settings:Add, Checkbox, x30 y50 w300 h20 vGui_AdminLaunch Checked%AdminLaunch%, 以管理员权限运行 (需重启脚本生效)
    Gui, Settings:Add, Checkbox, x30 y85 w300 h20 vGui_AutoRun Checked%AutoRun%, 开机自启动
    Gui, Settings:Add, Checkbox, x30 y120 w350 h20 vGui_ShowTrayIcon Checked%ShowTrayIcon%, 显示托盘图标 (若隐藏需手动修改 ini 文件恢复)

    ; --- 标签页 6: 关于 ---
    Gui, Settings:Tab, 6
    Gui, Settings:Add, GroupBox, x25 y45 w410 h270, 关于软件

    Gui, Settings:Add, Text, x45 y75 w80 h20, 软件名称:
    Gui, Settings:Add, Text, x120 y75 w200 h20 c0078D7, GhostSnap

    Gui, Settings:Add, Text, x45 y110 w80 h20, 当前版本:
    Gui, Settings:Add, Text, x120 y110 w200 h20, v%CurrentToolVersion%

    Gui, Settings:Add, Text, x45 y145 w80 h20, 软件作者:
    Gui, Settings:Add, Text, x120 y145 w200 h20, 逍遥

    Gui, Settings:Add, Text, x45 y180 w80 h20, 开源地址:
    ; 使用 Link 控件包裹 <a> 标签，用户点击即可自动用浏览器打开网页
    Gui, Settings:Add, Link, x120 y180 w300 h20, <a href="https://github.com/lch319/GhostSnap">github.com/lch319/GhostSnap</a>

    Gui, Settings:Add, Text, x45 y225 w370 h60 cGray, 声明与提示:`n本软件为开源窗口增强工具，提供智能吸附、尺寸同步、幽灵窗口及窗口移动联动等功能。感谢您的使用与支持！

    ; --- 底部按钮区 ---
    Gui, Settings:Tab
    ; [调整] 整体 y 坐标下移以适应更大的界面
    Gui, Settings:Add, Button, x110 y385 w100 h32 Default gSaveAndRestart, 保存并重启
    Gui, Settings:Add, Button, x220 y385 w80 h32 gApplyConfig, 应用
    Gui, Settings:Add, Button, x310 y385 w80 h32 gSettingsGuiClose, 取消

    Gui, Settings:Show, w480 h435, GhostSnap_v%CurrentToolVersion% 设置中心
return

ChooseColorBtn:
    Gui, Settings:Submit, NoHide
    NewColor := ChooseColor(Gui_GhostColor)
    if (NewColor != "") {
        GuiControl, Settings:, Gui_GhostColor, %NewColor%
        GuiControl, Settings:+Background%NewColor%, ColorPreview
    }
return

; 【应用配置 (不重启，即时生效)】
ApplyConfig:
    Gui, Settings:Submit, NoHide

    ; 保存到 INI：告别 true/false 转换，直接写入 1/0
    Var_Set(Gui_SnapDistance, "20", "SnapDistance", "基础配置", SettingsDir)
    Var_Set(Gui_BreakoutDistance, "30", "BreakoutDistance", "基础配置", SettingsDir)
    Var_Set(Gui_StrictSingle, "0", "StrictSingleAxisSnap", "基础配置", SettingsDir)
    Var_Set(Gui_GhostWin, "1", "EnableGhostWindow", "基础配置", SettingsDir)
    Var_Set(Gui_GhostColor, "0078D7", "GhostColor", "基础配置", SettingsDir)
    Var_Set(Gui_GhostOpacity, "80", "GhostOpacity", "基础配置", SettingsDir)
    Var_Set(Gui_EdgeSnap, "1", "EnableScreenEdgeSnap", "基础配置", SettingsDir)
    Var_Set(Gui_SmartSync, "1", "EnableSmartSync", "基础配置", SettingsDir)

    Var_Set(Gui_SmartSyncKey, "Alt", "SmartSyncKey", "基础配置", SettingsDir)
    Var_Set(Gui_SnapToggleKey, "Shift", "SnapToggleKey", "基础配置", SettingsDir)
    Var_Set(Gui_RequireKeyToSnap, "0", "RequireKeyToSnap", "基础配置", SettingsDir)

    Var_Set(Gui_DragModKey, "LWin", "DragModKey", "基础配置", SettingsDir)
    Var_Set(Gui_DragDirectKey, "XButton1", "DragDirectKey", "基础配置", SettingsDir)
    Var_Set(Gui_Chaining, "1", "EnableChaining", "基础配置", SettingsDir)
    Var_Set(Gui_ChainModKey, "Ctrl", "ChainModKey", "基础配置", SettingsDir)
    Var_Set(Gui_Blacklist, defaultBlacklist, "Blacklist", "基础配置", SettingsDir)
    Var_Set(Gui_DragBlacklist, "", "DragBlacklist", "基础配置", SettingsDir) ; [新增] 任意拖拽黑名单

    ; [新增] 写入系统级配置
    Var_Set(Gui_AdminLaunch, "0", "AdminLaunch", "基础配置", SettingsDir)
    Var_Set(Gui_AutoRun, "0", "AutoRun", "基础配置", SettingsDir)
    Var_Set(Gui_ShowTrayIcon, "1", "ShowTrayIcon", "基础配置", SettingsDir)

    ; 同步更新内存全局变量 (实现热更新)，直接接收 1/0
    SnapDistance := Gui_SnapDistance
    BreakoutDistance := Gui_BreakoutDistance
    StrictSingleAxisSnap := Gui_StrictSingle
    EnableGhostWindow := Gui_GhostWin
    GhostColor := Gui_GhostColor
    GhostOpacity := Gui_GhostOpacity
    EnableScreenEdgeSnap := Gui_EdgeSnap
    EnableSmartSync := Gui_SmartSync

    SmartSyncKey := Gui_SmartSyncKey
    SnapToggleKey := Gui_SnapToggleKey
    RequireKeyToSnap := Gui_RequireKeyToSnap

    DragModKey := Gui_DragModKey
    DragDirectKey := Gui_DragDirectKey
    EnableChaining := Gui_Chaining
    ChainModKey := Gui_ChainModKey
    Blacklist := Gui_Blacklist
    DragBlacklist := Gui_DragBlacklist

    ; [新增] 更新系统级变量
    AdminLaunch := Gui_AdminLaunch
    AutoRun := Gui_AutoRun
    ShowTrayIcon := Gui_ShowTrayIcon

    ; 更新托盘菜单 Check 状态
    Menu, Tray, % StrictSingleAxisSnap ? "Check" : "Uncheck", 单轴滑动微调模式 (防角落锁死)
    Menu, Tray, % EnableGhostWindow ? "Check" : "Uncheck", 启用幽灵窗口
    Menu, Tray, % EnableSmartSync ? "Check" : "Uncheck", 启用智能尺寸同步
    Menu, Tray, % EnableChaining ? "Check" : "Uncheck", 启用按键联动移动

    ; 即时更新幽灵窗口外观
    Gui, Ghost: Color, % GhostColor
    WinSet, Transparent, % GhostOpacity, ahk_id %GhostHwnd%
    if (!EnableGhostWindow && ghostVisible) {
        Gui, Ghost: Hide
        ghostVisible := false
    }

    ; 热更新：动态注销旧快捷键并注册新快捷键
    if (CurrentDragModKey != "" && CurrentDragModKey != DragModKey)
        Hotkey, %CurrentDragModKey% & LButton, Off, UseErrorLevel
    if (CurrentDragDirectKey != "" && CurrentDragDirectKey != DragDirectKey)
        Hotkey, %CurrentDragDirectKey%, Off, UseErrorLevel

    if (DragModKey != "")
        Hotkey, %DragModKey% & LButton, DoModDrag, On, UseErrorLevel
    if (DragDirectKey != "")
        Hotkey, %DragDirectKey%, DoDirectDrag, On, UseErrorLevel

    CurrentDragModKey := DragModKey
    CurrentDragDirectKey := DragDirectKey

    ; [新增] 热更新系统配置
    Label_AutoRun(AutoRun) ; 立刻写入/删除自启注册表
    if (ShowTrayIcon)
        Menu, Tray, Icon
    else
        Menu, Tray, NoIcon

    TrayTip, GhostSnap 设置, 配置已应用并即时生效！, 1.5
return

; 【保存并重启】
SaveAndRestart:
    GoSub, ApplyConfig
    Reload
return

SettingsGuiClose:
    Gui, Settings:Destroy
return

; ===========================================================
; 核心逻辑与钩子部分
; ===========================================================

Cleanup() {
    DllCall("UnhookWinEvent", "Ptr", hookStart)
    DllCall("UnhookWinEvent", "Ptr", hookEnd)
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

; [新增] 任意位置拖拽专属黑名单检测
IsDragBlacklisted(hwnd) {
    Loop, Parse, DragBlacklist, `n, `r
    {
        rule := Trim(A_LoopField)
        if (rule = "")
            continue
        if WinExist(rule " ahk_id " hwnd)
            return true
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

                target.isChained := true  ; 【新增代码】给加入了联动的窗口打上“已联动”标记
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

    movingHwnd := hwnd
    dragMode := "system"
    triggerKey := "LButton"
    isMoving := true

    Gosub, SetupMoveData

    if (isMoving)
        SetTimer, TrackMove, 15
}

OnMoveEnd(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    if (idObject != 0 or hwnd != movingHwnd)
        return
    if (dragMode = "manual")
        return
    SetTimer, TrackMove, Off
    Gosub, ForceEndMove
}

DoModDrag:
    triggerKey := "LButton"
    Gosub, StartManualDrag
return

DoDirectDrag:
    triggerKey := RegExReplace(A_ThisHotkey, "^[~*$]+")
    Gosub, StartManualDrag
return

StartManualDrag:
    CoordMode, Mouse, Screen
    MouseGetPos, mX, mY, hoverHwnd

    if (!hoverHwnd or hoverHwnd = GhostHwnd)
        return
    ; [修改] 这里增加了自定义快捷拖拽的黑名单拦截验证
    if IsBlacklisted(hoverHwnd) || IsDragBlacklisted(hoverHwnd)
        return

    WinGet, minMax, MinMax, ahk_id %hoverHwnd%
    if (minMax != 0)
        return

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
        Gosub, ForceEndMove
        return
    }

    ; ========================================================
    ; 新增逻辑：智能判断是否触发/暂停吸附
    ; ========================================================
    togglePressed := (SnapToggleKey != "") ? GetKeyState(SnapToggleKey, "P") : false

    ; 【修复】区分原生拖拽与快捷拖拽的反向模式响应规则
    if (dragMode = "manual") {
        ; 任意位置快捷拖拽时，无视反向模式 (RequireKeyToSnap)，强制保持默认吸附手感，按下 ToggleKey 时中断吸附
        suspendSnapping := togglePressed
    } else {
        ; 原生系统标题栏拖拽时，遵从反向模式设定
        suspendSnapping := RequireKeyToSnap ? !togglePressed : togglePressed
    }

    if (suspendSnapping) {
        willSnap := false
        if (ghostVisible) {
            Gui, Ghost: Hide
            ghostVisible := false
        }
        if (dragMode = "manual") {
            CoordMode, Mouse, Screen
            MouseGetPos, cmX, cmY
            WinMove, ahk_id %movingHwnd%, , % cmX + dragMouseOffsetX + diffX, % cmY + dragMouseOffsetY + diffY
        }
        return ; 跳过后续吸附计算逻辑
    }

    if (dragMode = "manual") {
        CoordMode, Mouse, Screen
        MouseGetPos, cmX, cmY
        mX := cmX + dragMouseOffsetX
        mY := cmY + dragMouseOffsetY
        WinMove, ahk_id %movingHwnd%, , % mX + diffX, % mY + diffY
        GetRealPos(movingHwnd, tempX, tempY, mW, mH)
    } else {
        GetRealPos(movingHwnd, mX, mY, mW, mH)
    }

    if (ChainedGroup.Length() > 0) {
        deltaX := mX - startMoveX
        deltaY := mY - startMoveY
        For index, child in ChainedGroup {
            WinMove, % "ahk_id " child.hwnd, , % child.sX + deltaX + child.dX, % child.sY + deltaY + child.dY
        }
    }

    mRight := mX + mW
    mBottom := mY + mH

    newX := mX, newY := mY
    snappedX := false, snappedY := false
    syncTargetX := 0, syncTargetY := 0

    currSnapDistX := (willSnap && snappedX) ? BreakoutDistance : SnapDistance
    currSnapDistY := (willSnap && snappedY) ? BreakoutDistance : SnapDistance
    minDx := currSnapDistX + 1
    minDy := currSnapDistY + 1

    For index, target in TargetWindows {

        if (target.isChained)      ; 【新增代码】如果是跟着一起联动的窗口，直接跳过吸附判定
            continue               ; 【新增代码】防自相吸附核心逻辑

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

            ; 应用自定义的 SmartSyncKey 替换写死的 Alt
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
        GetRealPos(movingHwnd, currX, currY, currW, currH)

        finalX := destX + diffX
        finalY := destY + diffY
        finalW := currW + diffW
        finalH := currH + diffH

        ; 应用自定义的 SmartSyncKey 替换写死的 Alt
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

        WinMove, ahk_id %movingHwnd%, , %finalX%, %finalY%, %finalW%, %finalH%

        if (ChainedGroup.Length() > 0) {
            GetRealPos(movingHwnd, finalRealX, finalRealY, tmpW, tmpH)
            finalDeltaX := finalRealX - startMoveX
            finalDeltaY := finalRealY - startMoveY

            For index, child in ChainedGroup {
                WinMove, % "ahk_id " child.hwnd, , % child.sX + finalDeltaX + child.dX, % child.sY + finalDeltaY + child.dY
            }
        }

        willSnap := false
    }

    movingHwnd := 0
return

GetRealPos(hwnd, ByRef x, ByRef y, ByRef w, ByRef h) {
    VarSetCapacity(rect, 16, 0)
    if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", &rect, "UInt", 16) = 0) {
        x := NumGet(rect, 0, "Int"), y := NumGet(rect, 4, "Int")
        w := NumGet(rect, 8, "Int") - x, h := NumGet(rect, 12, "Int") - y
        return true
    }
    WinGetPos, x, y, w, h, ahk_id %hwnd%
    return true  ; 【修改】改为 true，确保 fallback 后窗口仍能成为吸附目标
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

    ; 【新增】将默认值也统一转换为 [CRLF] 格式以供精准比对
    var_safe := StrReplace(var, "`r`n", "[CRLF]")
    var_safe := StrReplace(var_safe, "`n", "[CRLF]")

    if(vGui_safe != var_safe)
        IniWrite,%vGui_safe%,%Config%, %Section名%, %sz%
    Else
        IniDelete,%Config%,%Section名%, %sz%
    StringCaseSense, Off
}

; ==============================================================================
; 新增：开机自启逻辑处理
; ==============================================================================
Label_AutoRun(Auto_Launch:="0"){
    ; 使用 A_ScriptFullPath 兼容编译(.exe)与未编译(.ahk)环境
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