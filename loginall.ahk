#NoTrayIcon                ; ����ʾ���� H ͼ��
#SingleInstance Force      ; ��ֹ�ظ�����

CoordMode, Mouse, Screen   ; ����������ȫ������ֵ
SetDefaultMouseSpeed, 0    ; ���˲��
SetKeyDelay, 50, 50        ; ����ģ���ӳ�

; ------------ �� �� ------------
loginExe  := "D:\idv\V5.5.exe"            ; ��¼��������·��
helperExe := "IdentityV Login Helper.exe"    ; ��¼����̨����
gameExe   := "dwrg.exe"                      ; ��Ϸ EXE
gameDir   := "D:\idv\dwrg"                   ; ��ϷĿ¼
highGUID  := "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  ; �����ܵ�Դ GUID
balGUID   := "381b4222-f694-41f0-9685-ff5bb260df2e"  ; ƽ���Դ GUID

; ------------ ��̨���������ã�Client���꣬��Window Spyʵ�⣩ ------------
escX := 54      ; ���� ESC ��ť Client ���� X
escY := 46      ; ���� ESC ��ť Client ���� Y
hallX := 656    ; ���������ť Client ���� X
hallY := 377    ; ���������ť Client ���� Y

; ------------ ��̨������� ------------
PostClick(hwnd, x, y) {
    ; �������������Ϣ
    lParam := (y << 16) | (x & 0xFFFF)
    PostMessage, 0x201, 1, lParam,, ahk_id %hwnd%    ; WM_LBUTTONDOWN
    Sleep, 30
    ; �������̧����Ϣ
    PostMessage, 0x202, 0, lParam,, ahk_id %hwnd%    ; WM_LBUTTONUP
}

; ------------ �� ʼ �� �� ------------

; 1) �л��������ܵ�Դ
Run, % "powercfg /s " highGUID,, Hide

; 2) �ر����з���ǽ����ֹɨ��/helper����ȫ���棩
Run, % "powershell -Command ""Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False""",, Hide

; 3) ������¼�����ٳ������ã�������������
Run, % loginExe,, Hide
Sleep, 12000   ; �ȴ���¼����ȫ��ʼ���ͽٳ���Ч

; 4) ������Ϸ���壨ȷ��helper��׼���ã�
Run, % gameExe, % gameDir, Hide, pidGame

; 5) �ȴ� V5 ��¼ɨ�봰�ڳ��֣�� 18 �룬��ǰ���־���ǰ������
loginTimeout := 18000
startTick    := A_TickCount
foundLogin   := 0

Loop
{
    ; ��� V5 ��¼�����Ƿ񵯳���Qt5152QWindowIcon + V5.4.1.exe��
    loginHwnd := WinExist("ahk_class Qt5152QWindowIcon ahk_exe V5.5.exe")
    if (loginHwnd) {
        foundLogin := 1
        break
    }
    if (A_TickCount - startTick > loginTimeout)
        break        ; ��ʱֱ�Ӽ���
    Sleep, 150
}

; 6) ��¼��ɨ��������µ��������Ļ���꣬�򴰿������ö���
Sleep, 3000                  ; ��֤ɨ�����Ͱ�ť��ȫ����
Click, 1525, 1189            ; ��һ��������˺ţ���ɨ������
Sleep, 200
Click, 1087, 651             ; �ڶ�������Ȩ����¼
Sleep, 2100                  ; ��ɨ��ҳ����ɺ������Ϸ������

; 7) [�¹���] ��̨������ ���� ������Ϸ����ǰ̨/����
gameHwnd := WinExist("ahk_exe dwrg.exe")    ; ʵʱ��ȡ��Ϸ���ھ��
if (!gameHwnd) {
    MsgBox, û�ҵ������˸񴰿ڣ��ű��˳���
    ExitApp
}
Sleep, 500                   ; ���յȴ����浯������

; 7.1) �㹫�� ESC����һ��������
PostClick(gameHwnd, escX, escY)
Sleep, 800

; 7.2) �㡰�����������ť
PostClick(gameHwnd, hallX, hallY)
Sleep, 10000

; 7.3) �ٴε㹫�� ESC���������й��棩
PostClick(gameHwnd, escX, escY)
Sleep, 800

; 8) �رյ�¼������̨���̣��ָ�����ǽ
RunWait, % "taskkill /F /IM V5.5.exe /T", , Hide
RunWait, % "taskkill /F /IM IdentityV Login Helper.exe /T", , Hide
Run, % "powershell -Command ""Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True""",, Hide

; 9) �ȴ���Ϸ�����˳������ֻ�����ˬ
Process, WaitClose, %pidGame%

; 10) �ָ�ƽ���Դ
Run, % "powercfg /s " balGUID,, Hide

MsgBox, ��Ϸ���������ǵ�����������Ŷ~
ExitApp
