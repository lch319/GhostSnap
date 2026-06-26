#NoTrayIcon ;~不显示托盘图标
#SingleInstance Off

global 参数1 := A_Args[1]
global 参数2 := A_Args[2]

ChangeWindowTitleAndIcon(参数1, 参数2)
ExitApp

; ═══════════════════════════════════════════════════════════════════════════════════════════
; 函数：修改指定窗口的标题和图标
; 参数：
;   TargetTitle - 标准的 AHK 窗口标题，例如 "A" (当前活动窗口), "ahk_exe notepad.exe" 等。
;   Mode        - 1: 仅改标题 | 2: 仅改图标 | 3: 同时修改 (默认)
; ═══════════════════════════════════════════════════════════════════════════════════════════
ChangeWindowTitleAndIcon(TargetTitle := "A", Mode := 3) {
    ; 1. 获取窗口句柄 (HWND)
    hwnd := WinExist(TargetTitle)
    if (!hwnd) {
        MsgBox, 16, 错误, 找不到指定的窗口！
        return
    }

    ; 2. 系统保护机制：拦截桌面和任务栏底层类名
    WinGetClass, winClass, ahk_id %hwnd%
    if (winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd") {
        MsgBox, 16, 错误, 保护机制触发：禁止修改桌面或任务栏！
        return
    }

    ; 3. 修改窗口标题
    if (Mode & 1) {
        WinGetTitle, Title, ahk_id %hwnd%

        InputBox, NewTitle, 更改窗口标题, 请输入新的窗口标题：,, 400, 150,,,,, %Title%
        if (!ErrorLevel) {
            WinSetTitle, ahk_id %hwnd%,, %NewTitle%
            ToolTip, 标题已修改为: %NewTitle%
            Sleep, 1500
            ToolTip
        }
    }

    ; 4. 修改窗口图标
    if (Mode & 2) {
        FileSelectFile, SelectedFile, 3,, 选择图标文件, 图标文件 (*.ico; *.exe; *.dll)
        if (SelectedFile = "")
            return

        SplitPath, SelectedFile,,, ext
        if ext not in ico,exe,dll
        {
            MsgBox, 16, 错误, 请选择 .ico、.exe 或 .dll 文件！
            return
        }

        hIcon := 0
        iconIndex := 0

        ; 【退回你原本正确的分支提取逻辑】
        if (ext = "ico") {
            ; 纯 ICO 文件：恢复使用 LoadImage。
            ; 加上了 0x8000 (LR_SHARED)，交由系统管理句柄，防止图标意外变空白
            hIcon := DllCall("LoadImage", "UInt", 0, "Str", SelectedFile, "UInt", 1, "Int", 0, "Int", 0, "UInt", 0x10 | 0x8000)
            if !hIcon {
                MsgBox, 16, 错误, 无法加载 ICO 文件！
                return
            }
        }
        else {
            ; EXE/DLL 文件：恢复使用你的 PrivateExtractIcons
            iconCount := DllCall("PrivateExtractIcons", "Str", SelectedFile, "Int", -1, "Int", 0, "Int", 0, "Ptr", 0, "Ptr", 0, "UInt", 0, "UInt", 0)

            if (iconCount <= 0) {
                MsgBox, 16, 错误, 文件中未找到图标资源！
                return
            }

            if (iconCount > 1) {
                iconCount2 := iconCount - 1
                InputBox, iconIndex, 选择图标索引, 该文件包含 %iconCount% 个图标`n请输入索引号 (0-%iconCount2%) : , , 300, 200, , , , , 0
                if ErrorLevel
                    return
                if iconIndex is not integer
                {
                    MsgBox, 16, 错误, 请输入有效的数字索引！
                    return
                }
                if (iconIndex < 0 || iconIndex >= iconCount) {
                    MsgBox, 16, 错误, 索引超出范围 (有效范围：0-%iconCount2%)
                    return
                }
            }

            VarSetCapacity(phicon, 8, 0)
            success := DllCall("PrivateExtractIcons"
                , "Str", SelectedFile
                , "Int", iconIndex
                , "Int", 32    ; 宽
                , "Int", 32    ; 高
                , "Ptr*", phicon
                , "Ptr*", 0
                , "UInt", 1
                , "UInt", 0)

            if (success <= 0 || phicon == 0) {
                MsgBox, 16, 错误, 无法提取索引为 %iconIndex% 的图标！
                return
            }
            hIcon := phicon
        }

        ; 5. 发送消息设置图标 (保留了修复后的双端发送)
        if (hIcon) {
            WM_SETICON := 0x80
            SendMessage, %WM_SETICON%, 0, %hIcon%,, ahk_id %hwnd%  ; 设置标题栏/任务栏小图标
            SendMessage, %WM_SETICON%, 1, %hIcon%,, ahk_id %hwnd%  ; 设置 Alt+Tab 大图标

            ToolTip, 操作成功，已应用索引 %iconIndex% 的图标
            Sleep, 1500
            ToolTip
        }
    }
}

