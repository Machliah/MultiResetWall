#NoEnv
#NoTrayIcon
#Include settings-Mach.ahk
#Include %A_ScriptDir%\functions.ahk
#Include %A_ScriptDir%\GlobalConstants.ahk
#SingleInstance, off

SetBatchLines, -1
DetectHiddenWindows, On

global idx := A_Args[1]
global mainPID := A_Args[2]
global wpStateFile := A_Args[3]

global previousWPState := "unknown"

OnMessage(MSG_RESET, "ResetSound")
OnMessage(MSG_KILL, "Kill")

SendLog(LOG_LEVEL_INFO, Format("Instance {1} reset manager started, MainPID: {2} state file: {4}", idx, mainPID, wpStateFile))

SetTimer, CheckMain, 5000
SetTimer, ManageReset, 0

ManageReset() {
    ; title
    ; waiting
    ; generating,%
    ; previewing,%
    ; inworld,unpaused/paused/gamescreenopen
    
    FileRead, wpState, %wpStateFile%
    
    if (wpState == previousWPState) {
        return
    }
    
    if (InStr(wpState, "previewing")) {
        PostMessage, MSG_PREVIEW, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
        ; SendOBSCmd(Format("Cover,0,{1}", idx))
    } else if (InStr(wpState, "inworld")) {
        PostMessage, MSG_LOAD, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    }
    
    previousWPState := wpState
}

Kill() {
    ExitApp
}

ResetSound() {
    if (sounds == "A" || sounds == "F" || sounds == "R") {
        SoundPlay, A_ScriptDir\..\media\reset.wav
    }
    if obsResetMediaKey {
        send {%obsResetMediaKey% down}
        sleep, %obsDelay%
        send {%obsResetMediaKey% up}
    }
}

CheckMain() {
    if (!WinExist(Format("ahk_pid {1}", mainPID))) {
        SendLog(LOG_LEVEL_INFO, Format("Reset manager {1} didnt find main script pid {2}, ending process", idx, mainPID))
        Kill()
    }
}