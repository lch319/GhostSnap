; 编译exe文件信息及版本号设置
当前工具版本:="1.1.2"                  ;设置版本号
;@Ahk2Exe-Obey U_bits, = "%A_PtrSize%>4" ? "-64bit" : "-32bit"  ;判断位数
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%  ;读取版本号以编译
;@Ahk2Exe-SetMainIcon GhostSnap图标.ico          ;指定托盘图标文件
;@Ahk2Exe-AddResource GhostSnap图标.ico, 160      ;替换自带的'蓝色H'图标
;@Ahk2Exe-AddResource GhostSnap图标.ico, 206      ;替换为 '绿色 S'
;@Ahk2Exe-AddResource GhostSnap图标.ico, 207      ;替换自带的'红色H'图标
;@Ahk2Exe-AddResource GhostSnap图标.ico, 208      ;替换为 '红色 S'
;@Ahk2Exe-ExeName %A_ScriptDir%\GhostSnap%U_version%.exe  ;打包后的exe文件路径
;@Ahk2Exe-SetCompanyName 逍遥xiaoyao        ;企业信息
;@Ahk2Exe-SetCopyright 逍遥xiaoyao          ;版权信息
;@Ahk2Exe-SetDescription 把窗口拖拽变成磁铁吸附，靠近边缘自动对齐  ;文件说明
;@Ahk2Exe-SetFileVersion %U_version%        ;文件版本
;@Ahk2Exe-SetInternalName GhostSnap        ;文件内部名
;@Ahk2Exe-SetLanguage 0x0804            ;区域语言
;@Ahk2Exe-SetName GhostSnap          ;名称
;@Ahk2Exe-SetProductName GhostSnap        ;产品名称
;@Ahk2Exe-SetOrigFilename GhostSnap.exe      ;原始文件名称
;@Ahk2Exe-SetProductVersion %U_version%        ;产品版本号
;@Ahk2Exe-SetVersion %U_version%          ;版本号

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
global CurrentToolVersion := "1.1.2"
global SettingsDir := A_ScriptDir "\GhostSnap.ini" ;配置文件路径

global SnapDistance := Var_Read("SnapDistance","20","基础配置",SettingsDir,"否")    ;触发吸附的距离（像素）
global BreakoutDistance := Var_Read("BreakoutDistance","30","基础配置",SettingsDir,"否")  ; 挣脱距离(阻尼感)

global StrictSingleAxisSnap := Var_Read("StrictSingleAxisSnap","0","基础配置",SettingsDir,"否")  ;默认吸附模式
global EnableGhostWindow := Var_Read("EnableGhostWindow","1","基础配置",SettingsDir,"否")    ;启用幽灵窗口特效
global EnableScreenEdgeSnap := Var_Read("EnableScreenEdgeSnap","1","基础配置",SettingsDir,"否")    ;屏幕边缘吸附
global EnableSmartSync := Var_Read("EnableSmartSync","1","基础配置",SettingsDir,"否")   ;智能尺寸同步
global SmartSyncKey := Var_Read("SmartSyncKey","Alt","基础配置",SettingsDir,"否")   ;触发智能尺寸同步的按键

global EnableChaining := Var_Read("EnableChaining","1","基础配置",SettingsDir,"否")    ;窗口联动移动
global GhostColor := Var_Read("GhostColor","0078D7","基础配置",SettingsDir,"否")    ;幽灵窗口颜色
global GhostOpacity := Var_Read("GhostOpacity","80","基础配置",SettingsDir,"否")  ;幽灵窗口透明度

global EnableSnapAnimation := Var_Read("EnableSnapAnimation","1","基础配置",SettingsDir,"否") ;是否启用吸附动画
global SnapAnimSteps := Var_Read("SnapAnimSteps","4","基础配置",SettingsDir,"否")             ;动画过渡帧数
global SnapAnimSleep := Var_Read("SnapAnimSleep","10","基础配置",SettingsDir,"否")            ;动画每帧延迟(毫秒)

global SnapToggleKey := Var_Read("SnapToggleKey","Shift","基础配置",SettingsDir,"否") ;临时停止/触发吸附的按键
global RequireKeyToSnap := Var_Read("RequireKeyToSnap","0","基础配置",SettingsDir,"否") ; 反向吸附

global DragModKey := Var_Read("DragModKey","LWin","基础配置",SettingsDir,"否","否")  ;任意位置拖拽修饰键
global DragDirectKey := Var_Read("DragDirectKey","XButton1","基础配置",SettingsDir,"否","否")   ;任意位置拖拽直接键
global ChainModKey := Var_Read("ChainModKey","Ctrl","基础配置",SettingsDir,"否")   ;触发联动的修饰键

defaultBlacklist := "FloatingBall悬浮球 ahk_class AutoHotkeyGUI`nahk_exe PixPin.exe`nahk_exe Snipaste.exe`nahk_class Progman`nahk_class WorkerW`nahk_class Shell_TrayWnd`nahk_class TopLevelWindowForOverflow`nahk_class Shell_SecondaryTrayWnd"
global Blacklist := Var_Read("Blacklist", defaultBlacklist, "基础配置", SettingsDir, "否", "是")      ;窗口黑名单
global DragModBlacklist := Var_Read("DragModBlacklist", "", "基础配置", SettingsDir, "否", "是")      ;修饰键拖拽黑名单
global DragDirectBlacklist := Var_Read("DragDirectBlacklist", "", "基础配置", SettingsDir, "否", "是")   ;直接键拖拽黑名单

global AdminLaunch := Var_Read("AdminLaunch","0","基础配置",SettingsDir,"否") ;是否管理员运行
global AutoRun := Var_Read("AutoRun","0","基础配置",SettingsDir,"否") ; 是否开机自启
global ShowTrayIcon := Var_Read("ShowTrayIcon","1","基础配置",SettingsDir,"否") ; 是否显示托盘图标

; --- 贴边隐藏新增配置 ---
global AutoHideModKey := Var_Read("AutoHideModKey","CapsLock","贴边隐藏",SettingsDir,"否") ; 触发按键
global AutoHideProtrude := Var_Read("AutoHideProtrude","8","贴边隐藏",SettingsDir,"否")  ; 边缘凸出长度
global AutoHideShowDelay := Var_Read("AutoHideShowDelay","150","贴边隐藏",SettingsDir,"否") ;悬停显示延迟
global AutoHideHideDelay := Var_Read("AutoHideHideDelay","350","贴边隐藏",SettingsDir,"否") ; 移出隐藏延迟
global AutoHideTolerance := Var_Read("AutoHideTolerance","5","贴边隐藏",SettingsDir,"否")  ; 移出判定容差
global AutoHideEdgePriority := Var_Read("AutoHideEdgePriority","0","贴边隐藏",SettingsDir,"否") ; 优先级: 0=上下, 1=左右
global AutoHideTopmost := Var_Read("AutoHideTopmost","0","贴边隐藏",SettingsDir,"否")   ;是否置顶
global AutoHideFocus := Var_Read("AutoHideFocus","1","贴边隐藏",SettingsDir,"否")     ; 呼出时是否获取焦点
global AutoHideFullscreenHide := Var_Read("AutoHideFullscreenHide","1","贴边隐藏",SettingsDir,"否") ; 全屏时是否完全隐藏凸出部分

; 独立动画配置
global EnableAutoHideAnim := Var_Read("EnableAutoHideAnim","1","贴边隐藏",SettingsDir,"否")
global AutoHideAnimSteps := Var_Read("AutoHideAnimSteps","5","贴边隐藏",SettingsDir,"否")
global AutoHideAnimSleep := Var_Read("AutoHideAnimSleep","8","贴边隐藏",SettingsDir,"否")
global HiddenWindows := {} ; 用于存储正在贴边隐藏的窗口信息字典
global wasHiddenHwnd := 0  ; 用于存储被拖拽出的贴边隐藏窗口ID

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
iconFile := A_ScriptDir "\GhostSnap图标.ico"
if FileExist(iconFile)
    Menu, Tray, Icon, %iconFile%

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

; --- 初始化幽灵窗口 ---
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
; 全局鼠标事件双保险 (防止拖拽状态卡死)
; ===========================================================
~LButton Up::
    if (isMoving && dragMode == "manual") {
        SetTimer, TrackMove, Off
        SetTimer, ExecEndMove, -1  ;【关键修复】使用异步定时器脱钩执行
    }
return

; 【关键修复】异步中转器，脱离系统的 Hook 线程保护操作
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

; ==========================================
; 设置中心 GUI 界面逻辑
; ==========================================
OpenSettingsGui:
    Gui, Settings:Destroy
    Gui, Settings:Font, s9, Microsoft YaHei
    Gui, Settings:Add, Tab3, x10 y10 w460 h380, 基础吸附|外观与动画|拖拽与联动|贴边隐藏|黑名单|系统与高级|关于

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

    ; --- 标签页 2: 外观与动画 ---
    Gui, Settings:Tab, 2
    Gui, Settings:Add, Checkbox, x30 y40 w300 h20 vGui_GhostWin Checked%EnableGhostWindow%, 启用幽灵窗口特效

    Gui, Settings:Add, Text, x30 y75 w100 h20, 幽灵窗口颜色:
    Gui, Settings:Add, Edit, x130 y73 w70 h20 vGui_GhostColor Limit6, %GhostColor%
    Gui, Settings:Add, Progress, x210 y73 w20 h20 Background%GhostColor% vColorPreview
    Gui, Settings:Add, Button, x240 y71 w80 h24 gChooseColorBtn, 选择颜色

    Gui, Settings:Add, Text, x30 y115 w100 h20, 幽灵透明度 (0-255):
    Gui, Settings:Add, Slider, x125 y115 w200 h30 vGui_GhostOpacity Range0-255 TickInterval25 ToolTip, %GhostOpacity%

    ; --- 动画配置 ---
    Gui, Settings:Add, GroupBox, x25 y160 w410 h140, 磁吸释放平滑过渡动画
    Gui, Settings:Add, Checkbox, x40 y185 w350 h20 vGui_EnableAnim Checked%EnableSnapAnimation% gToggleAnimGuiState, 启用释放吸附时的平滑过渡动画 (关闭则为生硬瞬移)

    Gui, Settings:Add, Text, x40 y225 w110 h20 vGui_TextSteps, 动画过渡帧数 (组):
    Gui, Settings:Add, Edit, x155 y223 w60 h20 vGui_AnimSteps Number, %SnapAnimSteps%
    Gui, Settings:Add, UpDown, Range1-30, %SnapAnimSteps%
    Gui, Settings:Add, Text, x225 y225 w200 h20 cGray vGui_DescSteps, (帧数越多，过渡动作分解越细)

    Gui, Settings:Add, Text, x40 y260 w110 h20 vGui_TextSleep, 每帧延迟时间 (ms):
    Gui, Settings:Add, Edit, x155 y258 w60 h20 vGui_AnimSleep Number, %SnapAnimSleep%
    Gui, Settings:Add, UpDown, Range1-100, %SnapAnimSleep%
    Gui, Settings:Add, Text, x225 y260 w200 h20 cGray vGui_DescSleep, (延迟越低帧率越高，动画结算越快)

    GoSub, ToggleAnimGuiState

    ; --- 标签页 3: 拖拽与联动 ---
    Gui, Settings:Tab, 3
    Gui Settings:Add, Text, x30 y50 w140 h20, 任意位置拖拽修饰键:
    Gui, Settings:Add, Edit, x170 y48 w100 h20 vGui_DragModKey, %DragModKey%
    Gui, Settings:Add, Text, x280 y50 w150 h20 cGray, (如:LWin 留空则禁用)

    Gui, Settings:Add, Text, x30 y90 w140 h20, 任意位置拖拽直接键:
    Gui, Settings:Add, Edit, x170 y88 w100 h20 vGui_DragDirectKey, %DragDirectKey%
    Gui, Settings:Add, Text, x280 y90 w150 h20 cGray, (如: XButton1 MButton)

    Gui, Settings:Add, Checkbox, x30 y145 w300 h20 vGui_Chaining Checked%EnableChaining%, 启用窗口联动移动
    Gui, Settings:Add, Text, x30 y185 w140 h20, 触发联动修饰键:
    Gui, Settings:Add, Edit, x170 y183 w100 h20 vGui_ChainModKey, %ChainModKey%
    Gui, Settings:Add, Text, x280 y185 w150 h20 cGray, (如: Ctrl, Alt)

    ; --- 标签页 4: 贴边隐藏 ---
    Gui, Settings:Tab, 4
    Gui, Settings:Add, Text, x30 y45 w140 h20, 触发贴边隐藏按键:
    Gui, Settings:Add, Edit, x180 y43 w100 h20 vGui_AutoHideModKey, %AutoHideModKey%
    Gui, Settings:Add, Text, x290 y45 w150 h20 cGray, (默认: CapsLock, 留空禁用)

    Gui, Settings:Add, Text, x30 y75 w140 h20, 边缘凸出长度 (像素):
    Gui, Settings:Add, Edit, x180 y73 w50 h20 vGui_AutoHideProtrude Number, %AutoHideProtrude%

    Gui, Settings:Add, Text, x250 y75 w140 h20, 移出判定容差 (像素):
    Gui, Settings:Add, Edit, x380 y73 w50 h20 vGui_AutoHideTolerance Number, %AutoHideTolerance%

    Gui, Settings:Add, Text, x30 y105 w140 h20, 悬停显示延迟 (毫秒):
    Gui, Settings:Add, Edit, x180 y103 w50 h20 vGui_AutoHideShowDelay Number, %AutoHideShowDelay%

    Gui, Settings:Add, Text, x250 y105 w140 h20, 移出隐藏延迟 (毫秒):
    Gui, Settings:Add, Edit, x380 y103 w50 h20 vGui_AutoHideHideDelay Number, %AutoHideHideDelay%

    Gui, Settings:Add, Text, x30 y135 w100 h20, 角落隐藏优先:
    edgeChoice := (AutoHideEdgePriority == "1") ? 2 : 1
    Gui, Settings:Add, DropDownList, x130 y133 w100 vGui_AutoHideEdgePriority AltSubmit Choose%edgeChoice%, 上下优先|左右优先

    Gui, Settings:Add, Checkbox, x250 y135 w200 h20 vGui_AutoHideTopmost Checked%AutoHideTopmost%, 隐藏/显示时保持置顶

    Gui, Settings:Add, Checkbox, x30 y165 w200 h20 vGui_AutoHideFocus Checked%AutoHideFocus%, 呼出时获取焦点，隐藏时失去

    ; 独立动画配置
    Gui, Settings:Add, GroupBox, x25 y195 w410 h110, 贴边隐藏平滑过渡动画
    Gui, Settings:Add, Checkbox, x40 y215 w350 h20 vGui_EnableAutoHideAnim Checked%EnableAutoHideAnim% gToggleAutoHideAnimGuiState, 启用贴边隐藏/呼出时的平滑过渡动画

    Gui, Settings:Add, Text, x40 y245 w110 h20 vGui_TextAHSteps, 动画过渡帧数 (组):
    Gui, Settings:Add, Edit, x155 y243 w60 h20 vGui_AHAnimSteps Number, %AutoHideAnimSteps%
    Gui, Settings:Add, UpDown, Range1-30, %AutoHideAnimSteps%

    Gui, Settings:Add, Text, x235 y245 w110 h20 vGui_TextAHSleep, 每帧延迟时间 (ms):
    Gui, Settings:Add, Edit, x350 y243 w60 h20 vGui_AHAnimSleep Number, %AutoHideAnimSleep%
    Gui, Settings:Add, UpDown, Range1-100, %AutoHideAnimSleep%

    ; 新增：全屏是否自动完全隐藏
    Gui, Settings:Add, Checkbox, x30 y315 w350 h20 vGui_AutoHideFullscreen Checked%AutoHideFullscreenHide%, 全屏时自动完全隐藏凸出部分 (防打扰)
    Gui, Settings:Add, Text, x30 y340 w400 h40 cGray, 提示：按住指定修饰键移动到边缘即可触发。贴边隐藏的窗口再次拖拽可记忆原状态。

    GoSub, ToggleAutoHideAnimGuiState

    ; --- 标签页 5: 黑名单 ---
    Gui, Settings:Tab, 5
    Gui, Settings:Add, Text, x25 y45 w400 h20, 全局窗口黑名单 (吸附与拖拽均无效):
    Gui, Settings:Add, Edit, x25 y65 w410 h80 vGui_Blacklist Multi WantReturn, %Blacklist%

    Gui, Settings:Add, Text, x25 y155 w400 h20, 修饰键拖拽黑名单 (仅限修饰键拖拽无效):
    Gui, Settings:Add, Edit, x25 y175 w410 h70 vGui_DragModBlacklist Multi WantReturn, %DragModBlacklist%

    Gui, Settings:Add, Text, x25 y255 w400 h20, 直接键拖拽黑名单 (仅限直接键拖拽无效):
    Gui, Settings:Add, Edit, x25 y275 w410 h70 vGui_DragDirectBlacklist Multi WantReturn, %DragDirectBlacklist%

    ; --- 标签页 6: 系统与高级 ---
    Gui, Settings:Tab, 6
    Gui, Settings:Add, Checkbox, x30 y50 w300 h20 vGui_AdminLaunch Checked%AdminLaunch%, 以管理员权限运行 (需重启脚本生效)
    Gui, Settings:Add, Checkbox, x30 y85 w300 h20 vGui_AutoRun Checked%AutoRun%, 开机自启动
    Gui, Settings:Add, Checkbox, x30 y120 w350 h20 vGui_ShowTrayIcon Checked%ShowTrayIcon%, 显示托盘图标 (若隐藏需手动修改 ini 文件恢复)

    ; --- 标签页 7: 关于 ---
    Gui, Settings:Tab, 7
    Gui, Settings:Add, GroupBox, x25 y45 w410 h270, 关于软件
    Gui, Settings:Add, Text, x45 y75 w80 h20, 软件名称:
    Gui, Settings:Add, Text, x120 y75 w200 h20 c0078D7, GhostSnap
    Gui, Settings:Add, Text, x45 y110 w80 h20, 当前版本:
    Gui, Settings:Add, Text, x120 y110 w200 h20, v%CurrentToolVersion%
    Gui, Settings:Add, Text, x45 y145 w80 h20, 软件作者:
    Gui, Settings:Add, Text, x120 y145 w200 h20, 逍遥
    Gui, Settings:Add, Text, x45 y180 w80 h20, 开源地址:
    Gui, Settings:Add, Link, x120 y180 w300 h20, <a href="https://github.com/lch319/GhostSnap">github.com/lch319/GhostSnap</a>
    Gui, Settings:Add, Text, x45 y225 w370 h60 cGray, 声明与提示:`n本软件为开源窗口增强工具，提供智能吸附、尺寸同步、幽灵窗口、贴边隐藏及窗口移动联动等功能。感谢您的使用与支持！

    ; --- 底部按钮区 ---
    Gui, Settings:Tab
    Gui, Settings:Add, Button, x110 y400 w100 h32 Default gSaveAndRestart, 保存并重启
    Gui, Settings:Add, Button, x220 y400 w80 h32 gApplyConfig, 应用
    Gui, Settings:Add, Button, x310 y400 w80 h32 gSettingsGuiClose, 取消

    Gui, Settings:Show, w480 h445, GhostSnap_v%CurrentToolVersion% 设置中心
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

    Var_Set(Gui_DragModKey, "LWin", "DragModKey", "基础配置", SettingsDir)
    Var_Set(Gui_DragDirectKey, "XButton1", "DragDirectKey", "基础配置", SettingsDir)
    Var_Set(Gui_Chaining, "1", "EnableChaining", "基础配置", SettingsDir)
    Var_Set(Gui_ChainModKey, "Ctrl", "ChainModKey", "基础配置", SettingsDir)
    Var_Set(Gui_Blacklist, defaultBlacklist, "Blacklist", "基础配置", SettingsDir)
    Var_Set(Gui_DragModBlacklist, "", "DragModBlacklist", "基础配置", SettingsDir)
    Var_Set(Gui_DragDirectBlacklist, "", "DragDirectBlacklist", "基础配置", SettingsDir)

    Var_Set(Gui_AdminLaunch, "0", "AdminLaunch", "基础配置", SettingsDir)
    Var_Set(Gui_AutoRun, "0", "AutoRun", "基础配置", SettingsDir)
    Var_Set(Gui_ShowTrayIcon, "1", "ShowTrayIcon", "基础配置", SettingsDir)

    ; 保存贴边隐藏配置
    Var_Set(Gui_AutoHideModKey, "CapsLock", "AutoHideModKey", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideProtrude, "8", "AutoHideProtrude", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideShowDelay, "150", "AutoHideShowDelay", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideHideDelay, "350", "AutoHideHideDelay", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideTolerance, "5", "AutoHideTolerance", "贴边隐藏", SettingsDir)

    newEdgePriority := (Gui_AutoHideEdgePriority == 2) ? "1" : "0"
    Var_Set(newEdgePriority, "0", "AutoHideEdgePriority", "贴边隐藏", SettingsDir)

    Var_Set(Gui_AutoHideTopmost, "0", "AutoHideTopmost", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideFocus, "1", "AutoHideFocus", "贴边隐藏", SettingsDir)
    Var_Set(Gui_EnableAutoHideAnim, "1", "EnableAutoHideAnim", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AHAnimSteps, "5", "AutoHideAnimSteps", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AHAnimSleep, "8", "AutoHideAnimSleep", "贴边隐藏", SettingsDir)
    Var_Set(Gui_AutoHideFullscreen, "1", "AutoHideFullscreenHide", "贴边隐藏", SettingsDir)

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
    EnableChaining := Gui_Chaining
    ChainModKey := Gui_ChainModKey
    Blacklist := Gui_Blacklist
    DragModBlacklist := Gui_DragModBlacklist
    DragDirectBlacklist := Gui_DragDirectBlacklist

    AdminLaunch := Gui_AdminLaunch
    AutoRun := Gui_AutoRun
    ShowTrayIcon := Gui_ShowTrayIcon

    AutoHideModKey := Gui_AutoHideModKey
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

    Menu, Tray, % StrictSingleAxisSnap ? "Check" : "Uncheck", 单轴滑动微调模式 (防角落锁死)
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

    if (DragModKey != "")
        Hotkey, %DragModKey% & LButton, DoModDrag, On, UseErrorLevel
    if (DragDirectKey != "")
        Hotkey, %DragDirectKey%, DoDirectDrag, On, UseErrorLevel

    CurrentDragModKey := DragModKey
    CurrentDragDirectKey := DragDirectKey

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
        ; 根据新的宽高，重新计算应该隐藏缩进去的坐标系 (已修复左右向缩放错位问题)
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
    SetTimer, ExecEndMove, -1  ;【关键修复】使用异步定时器脱钩执行，防止 Hook 线程阻塞
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

    if (dragTriggerType := "Mod" && CheckWindowInList(hoverHwnd, DragModBlacklist))
        return

    if (dragTriggerType = "Direct" && CheckWindowInList(hoverHwnd, DragDirectBlacklist))
        return

    WinGet, minMax, MinMax, ahk_id %hoverHwnd%
    if (minMax != 0)
        return

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
        SetTimer, ExecEndMove, -1  ;【关键修复】同步改为异步执行
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

    ; 【逻辑变更】识别是否需要触发贴边隐藏（含记忆贴边判定）
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

    ; 【关键修复】如果用户触发了贴边隐藏意图，则无视反向模式的挂起，强制进行边缘计算
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

    currSnapDistX := (willSnap && snappedX) ? BreakoutDistance : SnapDistance
    currSnapDistY := (willSnap && snappedY) ? BreakoutDistance : SnapDistance
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

        ; 【清理冗余计算】保留原生标准宽高即可
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
                edgeT := (Abs(finalY - diffY - monTop) <= 2)
                edgeB := (Abs(finalY - diffY + realFinalH - monBottom) <= 2)
                edgeL := (Abs(finalX - diffX - monLeft) <= 2)
                edgeR := (Abs(finalX - diffX + realFinalW - monRight) <= 2)

                ; 判定逻辑：优先检查设置内的边缘角优先级
                if (AutoHideEdgePriority == "1") { ; 左右优先
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

                ; 【智能兼容】动态检测当前显示器的任务栏位置，只对无任务栏的一侧强制置顶
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

            ; 隐藏状态：鼠标移入“凸出部分”（如果完全隐藏则不响应悬停呼出）
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

            ; --- 【关键修复：防调整大小/防误触异常隐藏】 ---
            ; 1. info.isResizing: 由系统钩子判断出用户正在拖拽边框调整大小
            ; 2. GetKeyState("LButton", "P") && WinActive: 用户正在按住左键操作这个激活的窗口（比如拖拽滚动条，框选文字等）
            ; 满足任一条件时，直接重置移出倒计时，暂停隐藏动作！
            if (info.isResizing || (GetKeyState("LButton", "P") && WinActive("ahk_id " hw))) {
                info.leaveTime := 0
                continue
            }

            ; 【关键修复】显示状态：计算离开区域的边界。如果是贴边隐藏，离开判定框必须向屏幕外围无限延伸，解决经过任务栏疯狂来回隐藏/抽搐的Bug
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

                    ; 【智能兼容】动态检测当前显示器的任务栏位置，只对无任务栏的一侧强制置顶
                    tbEdge := GetTaskbarEdgeByPos(info.shownX + info.w/2, info.shownY + info.h/2)
                    if (AutoHideTopmost || info.edge != tbEdge)
                        WinSet, Topmost, On, ahk_id %hw%
                    else if (!info.origTopmost)
                        WinSet, Topmost, Off, ahk_id %hw%

                    ; --- 失去焦点逻辑处理 ---
                    if (AutoHideFocus && WinActive("ahk_id " hw)) {
                        ; 尝试将焦点平滑移交给当前鼠标指向的其他窗口，否则降级回桌面
                        MouseGetPos,,, underHwnd
                        if (underHwnd && underHwnd != hw)
                            WinActivate, ahk_id %underHwnd%
                        else
                            WinActivate, ahk_class Progman
                    }

                    DoAnimateWindow(hw, info.shownX, info.shownY, info.hiddenX, info.hiddenY, info.w, info.h)
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