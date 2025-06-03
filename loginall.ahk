#NoTrayIcon                ; 不显示托盘 H 图标
#SingleInstance Force      ; 防止重复运行

CoordMode, Mouse, Screen   ; 鼠标坐标采用全屏绝对值
SetDefaultMouseSpeed, 0    ; 鼠标瞬移
SetKeyDelay, 50, 50        ; 键盘模拟延迟

; ------------ 配 置 ------------
loginExe  := "D:\idv\V5.5.exe"            ; 登录器主程序路径
helperExe := "IdentityV Login Helper.exe"    ; 登录器后台进程
gameExe   := "dwrg.exe"                      ; 游戏 EXE
gameDir   := "D:\idv\dwrg"                   ; 游戏目录
highGUID  := "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  ; 高性能电源 GUID
balGUID   := "381b4222-f694-41f0-9685-ff5bb260df2e"  ; 平衡电源 GUID

; ------------ 后台点击相关配置（Client坐标，需Window Spy实测） ------------
escX := 54      ; 公告 ESC 按钮 Client 坐标 X
escY := 46      ; 公告 ESC 按钮 Client 坐标 Y
hallX := 656    ; 进入大厅按钮 Client 坐标 X
hallY := 377    ; 进入大厅按钮 Client 坐标 Y

; ------------ 后台点击函数 ------------
PostClick(hwnd, x, y) {
    ; 发送左键按下消息
    lParam := (y << 16) | (x & 0xFFFF)
    PostMessage, 0x201, 1, lParam,, ahk_id %hwnd%    ; WM_LBUTTONDOWN
    Sleep, 30
    ; 发送左键抬起消息
    PostMessage, 0x202, 0, lParam,, ahk_id %hwnd%    ; WM_LBUTTONUP
}

; ------------ 开 始 逻 辑 ------------

; 1) 切换到高性能电源
Run, % "powercfg /s " highGUID,, Hide

; 2) 关闭所有防火墙（防止扫码/helper弹安全警告）
Run, % "powershell -Command ""Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False""",, Hide

; 3) 启动登录器（劫持流量用，必须先启动）
Run, % loginExe,, Hide
Sleep, 12000   ; 等待登录器完全初始化和劫持生效

; 4) 启动游戏本体（确保helper已准备好）
Run, % gameExe, % gameDir, Hide, pidGame

; 5) 等待 V5 登录扫码窗口出现（最长 18 秒，提前出现就提前继续）
loginTimeout := 18000
startTick    := A_TickCount
foundLogin   := 0

Loop
{
    ; 检测 V5 登录窗口是否弹出（Qt5152QWindowIcon + V5.4.1.exe）
    loginHwnd := WinExist("ahk_class Qt5152QWindowIcon ahk_exe V5.5.exe")
    if (loginHwnd) {
        foundLogin := 1
        break
    }
    if (A_TickCount - startTick > loginTimeout)
        break        ; 超时直接继续
    Sleep, 150
}

; 6) 登录器扫码界面两下点击（用屏幕坐标，因窗口总是置顶）
Sleep, 3000                  ; 保证扫码界面和按钮完全加载
Click, 1525, 1189            ; 第一步：填充账号（或扫码区域）
Sleep, 200
Click, 1087, 651             ; 第二步：授权并登录
Sleep, 2100                  ; 等扫码页面完成后进入游戏主界面

; 7) [新功能] 后台三连击 —— 无需游戏窗口前台/激活
gameHwnd := WinExist("ahk_exe dwrg.exe")    ; 实时获取游戏窗口句柄
if (!gameHwnd) {
    MsgBox, 没找到第五人格窗口，脚本退出！
    ExitApp
}
Sleep, 500                   ; 保险等待公告弹窗弹出

; 7.1) 点公告 ESC（第一个弹窗）
PostClick(gameHwnd, escX, escY)
Sleep, 800

; 7.2) 点“进入大厅”按钮
PostClick(gameHwnd, hallX, hallY)
Sleep, 10000

; 7.3) 再次点公告 ESC（清理所有公告）
PostClick(gameHwnd, escX, escY)
Sleep, 800

; 8) 关闭登录器及后台进程，恢复防火墙
RunWait, % "taskkill /F /IM V5.5.exe /T", , Hide
RunWait, % "taskkill /F /IM IdentityV Login Helper.exe /T", , Hide
Run, % "powershell -Command ""Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True""",, Hide

; 9) 等待游戏进程退出，保持环境清爽
Process, WaitClose, %pidGame%

; 10) 恢复平衡电源
Run, % "powercfg /s " balGUID,, Hide

MsgBox, 游戏结束啦，记得忘掉不开心哦~
ExitApp
