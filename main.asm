; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
.486                      ; create 32 bit code
.model flat, stdcall      ; 32 bit memory model
option casemap :none      ; case sensitive

; Wczytanie wszystkich standardowych bibliotek Win32 API
include \masm32\include\masm32rt.inc
include \masm32\include\dialogs.inc

atoi PROTO C :PTR BYTE
includelib msvcrt.lib

; --- PROTOTYPY FUNKCJI (Wymagane przez kompilator dla instrukcji invoke) ---
WndProc          PROTO :DWORD,:DWORD,:DWORD,:DWORD
TopXY            PROTO :DWORD,:DWORD
RegisterWinClass PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
MsgLoop          PROTO
dlgproc          PROTO :DWORD,:DWORD,:DWORD,:DWORD
calendarDlgProc  PROTO :DWORD,:DWORD,:DWORD,:DWORD
GetTextDialog    PROTO :DWORD,:DWORD,:DWORD

; Makro do wyświetlania okna
DisplayWindow MACRO handl, ShowStyle
    invoke ShowWindow,handl, ShowStyle
    invoke UpdateWindow,handl
ENDM

.data
userDate db 20 dup(0)    ; Buffer for string (up to 19 chars + null terminator) - VULNERABLE TO BUFFER OVERFLOW
szCalcPath  db "Calculator.exe", 0   ; calc pg in C

.data?

; Struktury wymagane przez CreateProcess do zarządzania nowym procesem
startInfo   STARTUPINFO <?>
procInfo    PROCESS_INFORMATION <?>

hInstance   dd ?
hInstance1  dd ?
hInstance3  dd ?
CommandLine dd ?
hIcon3      dd ?
hCursor     dd ?
sWid        dd ?
sHgt        dd ?
hWnd        dd ?
systemTime  SYSTEMTIME <>

.code
; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
start:
    mov hInstance,    FUNC(GetModuleHandle,NULL)
    mov hInstance1,   rv(GetModuleHandle,NULL)

    ; ------------------
    ; timer global values
    ; ------------------
    mov hInstance3,  FUNC(GetModuleHandle, NULL)
    mov CommandLine, FUNC(GetCommandLine)
    mov hIcon3,      FUNC(LoadIcon,NULL,IDI_ASTERISK)
    mov hCursor,     FUNC(LoadCursor,NULL,IDC_ARROW)
    mov sWid,        FUNC(GetSystemMetrics,SM_CXSCREEN)
    mov sHgt,        FUNC(GetSystemMetrics,SM_CYSCREEN)
    
    call main
    invoke ExitProcess,eax

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
main proc
    LOCAL Wwd:DWORD,Wht:DWORD,Wtx:DWORD,Wty:DWORD
    STRING szClassName,"Timer_Demo_Class"
    
    ; register class name for CreateWindowEx call
    invoke RegisterWinClass,ADDR WndProc,ADDR szClassName, hIcon3,hCursor,COLOR_BTNFACE+1
    
    mov Wwd, 450          ; window width
    mov Wht, 350
    invoke TopXY,Wwd,sWid
    mov Wtx, eax
    invoke TopXY,Wht,sHgt
    mov Wty, eax
    
    invoke CreateWindowEx,WS_EX_LEFT or WS_EX_ACCEPTFILES, \
        ADDR szClassName, \
        chr$("Display Local Time"), \
        WS_OVERLAPPEDWINDOW, \
        Wtx,Wty,Wwd,Wht, \
        NULL,NULL, \
        hInstance3,NULL
    mov hWnd,eax
    
    DisplayWindow hWnd,SW_SHOWNORMAL
    call MsgLoop

    ret
main endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
RegisterWinClass proc lpWndProc:DWORD, lpClassName:DWORD, Icon:DWORD, Cursor:DWORD, bColor:DWORD
    LOCAL wc:WNDCLASSEX
    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_BYTEALIGNCLIENT or CS_BYTEALIGNWINDOW
    m2m wc.lpfnWndProc,    lpWndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInstance3
    m2m wc.hbrBackground,  bColor
    mov wc.lpszMenuName,   NULL
    m2m wc.lpszClassName,  lpClassName
    m2m wc.hIcon,          Icon
    m2m wc.hCursor,        Cursor
    m2m wc.hIconSm,        Icon
    invoke RegisterClassEx, ADDR wc
    ret
RegisterWinClass endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
MsgLoop proc
    LOCAL msg:MSG
    jmp InLoop                              
StartLoop:
    invoke TranslateMessage, ADDR msg
    invoke DispatchMessage,  ADDR msg
InLoop:
    invoke GetMessage,ADDR msg,NULL,0,0
    test eax, eax
    jnz StartLoop
    mov eax, msg.wParam
    ret
MsgLoop endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
WndProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
    LOCAL buffer1[260]:BYTE
    
    Switch uMsg
        Case WM_CREATE
            ; set the timer with a 1000 MS (1 second) update rate
            invoke SetTimer,hWin,222,1000,NULL

            ; button creation
            invoke CreateWindowEx, 0, chr$("BUTTON"), chr$("Calculator"), WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON, \
                30, 40, 70, 24, hWin, 2002, hInstance, NULL ; Nowy ID: 2002
            invoke CreateWindowEx, 0, chr$("BUTTON"), chr$("Calendar"), WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON, \
                110, 40, 70, 24, hWin, 2000, hInstance, NULL
            invoke CreateWindowEx, 0, chr$("BUTTON"), chr$("Option"), WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON, \
                190, 40, 70, 24, hWin, 2001, hInstance, NULL
            invoke CreateWindowEx, 0, chr$("BUTTON"), chr$("Exit"), WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON, \
                270, 40, 70, 24, hWin, IDCANCEL, hInstance, NULL

        Case WM_COMMAND
            mov eax, wParam
            and eax, 0FFFFh     ; Extract ID from LOWORD(wParam)

            .if eax == 2002
                ; --- IMPLEMENTACJA PROCESS MANAGEMENT ---
                ; 1. Przygotowanie struktury STARTUPINFO (wymagane przez system)
                invoke GetStartupInfo, addr startInfo
                
                ; 2. Wywołanie CreateProcess - odpowiednik Linuxowego fork+exec
                invoke CreateProcess, NULL, addr szCalcPath, NULL, NULL, FALSE, \
                                     NORMAL_PRIORITY_CLASS, NULL, NULL, \
                                     addr startInfo, addr procInfo
                
                .if eax == 0
                    invoke MessageBox, hWin, chr$("Failed to launch Calculator.exe"), chr$("Process Error"), MB_ICONERROR
                .else
                    ; 3. Dobra praktyka: zamykamy uchwyty, jeśli nie zamierzamy kontrolować procesu
                    invoke CloseHandle, procInfo.hProcess
                    invoke CloseHandle, procInfo.hThread
                .endif
                ; ---------------------------------------
            .elseif eax == 2000
                call popinfo
            .elseif eax == 2001
                invoke MessageBox, hWin, chr$("Option clicked"), chr$("Info"), MB_OK
            .elseif eax == IDCANCEL
                invoke PostMessage, hWin, WM_CLOSE, 0, 0
            .endif
            
        Case WM_TIMER
            invoke GetTimeFormat,LOCALE_USER_DEFAULT,NULL,NULL,NULL,ADDR buffer1,260
            fn SetWindowText,hWnd,ADDR buffer1
            return 0
            
        Case WM_CLOSE
            invoke KillTimer,hWin,222
            
        Case WM_DESTROY
            invoke PostQuitMessage,NULL
            return 0
    Endsw
    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret
WndProc endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
TopXY proc wDim:DWORD, sDim:DWORD
    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension
    return sDim
TopXY endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
calendarMain proc
    LOCAL ptxt  :DWORD
    LOCAL hIcon :DWORD
    LOCAL liczba :DWORD    
    
    invoke InitCommonControls
    mov hIcon, rv(LoadIcon,hInstance1 ,10)
    mov ptxt, rv(GetTextDialog," date format text here"," Enter date to check ",hIcon)
    
    .if ptxt != 0
        invoke lstrcpy, addr userDate, ptxt     ; Copy date to global variable (VULNERABLE)
        fn MessageBox,0,ptxt,"Title",MB_OK
        call ShowCalendar
    .else
        fn MessageBox,0,"Cancel was pressed","your date",MB_OK
    .endif
    
    invoke GlobalFree,ptxt
    ret
calendarMain endp

; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
GetTextDialog proc dgltxt:DWORD,grptxt:DWORD,iconID:DWORD
    LOCAL arg1[4]:DWORD
    LOCAL parg  :DWORD
    lea eax, arg1
    mov parg, eax
    ; load the array with the stack arguments
    mov ecx, dgltxt
    mov [eax], ecx
    mov ecx, grptxt
    mov [eax+4], ecx
    mov ecx, iconID
    mov [eax+8], ecx
    
    Dialog "enter date ", \               ; caption
           "Arial",8, \                     ; font,pointsize
           WS_OVERLAPPED or \              ; styles for
           WS_SYSMENU or DS_CENTER, \      ; dialog window
           5, \                            ; number of controls
           50,50,292,80, \                 ; x y co-ordinates
           4096                            ; memory buffer size
           
    DlgIcon   0,250,12,299
    DlgGroup  0,8,4,231,31,300
    DlgEdit   ES_LEFT or WS_BORDER or WS_TABSTOP,17,16,212,11,301
    DlgButton "OK",WS_TABSTOP,172,42,50,13,IDOK
    DlgButton "Cancel",WS_TABSTOP,225,42,50,13,IDCANCEL
    
    CallModalDialog hInstance1 ,0,dlgproc,parg
    ret
GetTextDialog endp

; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
ShowCalendar proc
    LOCAL icce:INITCOMMONCONTROLSEX
    mov icce.dwSize, SIZEOF INITCOMMONCONTROLSEX
    mov icce.dwICC, ICC_DATE_CLASSES
    invoke InitCommonControlsEx,ADDR icce
    
    Dialog "twoja data" ,"MS Sans Serif",10, \        ; caption,font,pointsize
           WS_OVERLAPPED or DS_CENTER, \       ; style
           2, \                                ; control count
           50,50,189,125, \                    ; x y co-ordinates
           1024                                ; memory buffer size
           
    DlgMonthCal MCS_WEEKNUMBERS,5,5,129,100,101
    DlgButton   "Close",WS_TABSTOP,141,5,40,12,IDCANCEL
    
    CallModalDialog hInstance, 0, calendarDlgProc,NULL
    ret
ShowCalendar endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
calendarDlgProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
    LOCAL hMonthCal:HWND
    LOCAL day:WORD
    LOCAL month:WORD
    LOCAL year:WORD

    .if uMsg == WM_INITDIALOG
        ; Get handle to MonthCal (ID = 101)
        invoke GetDlgItem, hWin, 101
        mov hMonthCal, eax
        
        ; Parse userDate, assuming format "dd.mm.yyyy"
        
        ; Parse day
        invoke atoi, addr userDate
        mov day, ax
        
        ; Parse month - skip to the first dot
        lea esi, userDate
        mov ecx, 20
    find_month:
        lodsb
        cmp al, '.'
        je parse_month
        loop find_month
        jmp skip_parse
        
    parse_month:
        ; Now esi points to MM.yyyy
        invoke atoi, esi
        mov month, ax
        
        ; Look for the second dot
        mov ecx, 20
    find_year:
        lodsb
        cmp al, '.'
        je parse_year
        loop find_year
        jmp skip_parse
        
    parse_year:
        ; esi points to YYYY
        invoke atoi, esi
        mov year, ax
        
        ; Now set SYSTEMTIME
        mov ax, day
        mov systemTime.wDay, ax
        mov ax, month
        mov systemTime.wMonth, ax
        mov ax, year
        mov systemTime.wYear, ax
        xor eax, eax
        mov systemTime.wHour, ax
        mov systemTime.wMinute, ax
        mov systemTime.wSecond, ax
        mov systemTime.wMilliseconds, ax
        
        ; Set date in the control
        invoke SendMessage, hMonthCal, MCM_SETCURSEL, 0, addr systemTime
        
    skip_parse:
    .elseif uMsg == WM_COMMAND
        .if wParam == IDCANCEL
            jmp dlg_end
        .endif
    .elseif uMsg == WM_CLOSE
    dlg_end:
        invoke EndDialog,hWin,0
    .endif
    xor eax, eax
    ret
calendarDlgProc endp

; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
dlgproc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
    LOCAL tlen  :DWORD
    LOCAL hMem  :DWORD
    LOCAL hIcon :DWORD
    switch uMsg
      case WM_INITDIALOG
        ; get the arguments from the array passed in lParam
        push esi
        mov esi, lParam
        fn SetWindowText,hWin,[esi]                         ; title text address
        fn SetWindowText,rv(GetDlgItem,hWin,300),[esi+4]    ; groupbox text address
        mov eax, [esi+8]                                    ; icon handle
        .if eax == 0
          mov hIcon, rv(LoadIcon,NULL,IDI_ASTERISK)         ; use default system icon
        .else
          mov hIcon, eax                                    ; load user icon
        .endif
        pop esi
        fn SendMessage,hWin,WM_SETICON,1,hIcon
        invoke SendMessage,rv(GetDlgItem,hWin,299),STM_SETIMAGE,IMAGE_ICON,hIcon
        xor eax, eax
        ret
      case WM_COMMAND
        switch wParam
          case IDOK
            mov tlen, rv(GetWindowTextLength,rv(GetDlgItem,hWin,301))
            .if tlen == 0
              invoke SetFocus,rv(GetDlgItem,hWin,301)
              ret
            .endif
            add tlen, 1
            mov hMem, alloc(tlen)
            fn GetWindowText,rv(GetDlgItem,hWin,301),hMem,tlen
            invoke EndDialog,hWin,hMem
          case IDCANCEL
            invoke EndDialog,hWin,0
        endsw
      case WM_CLOSE
        invoke EndDialog,hWin,0
    endsw
    xor eax, eax
    ret
dlgproc endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
popinfo proc
     jmp @F
     szDlgTitle    db "Minimum MASM",0
     szMsg db "      Enter your date only in format of",13,10,\
              " ---  dd.mm.yyyy --- ",13,10,\
              "      else won't work ",0
    @@:
    push MB_OK
    push offset szDlgTitle
    push offset szMsg
    push 0
    call MessageBox
    push 0 
    
    call calendarMain
    ret
popinfo endp
; #########################################################################
end start