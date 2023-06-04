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

SendLog(LOG_LEVEL_INFO, Format("Instance {1} reset manager started, MainPID: {2} state file: {3}", idx, mainPID, wpStateFile))

SetTimer, CheckMain, 5000
SetTimer, ManageReset, 0

ManageReset() {
    ; title
    ; waiting
    ; generating,%
    ; previewing,%
    ; inworld,unpaused/paused/gamescreenopen
    
    FileRead, wpState, %wpStateFile%
    
    ; if nothing changed or if its generating after previewing (it should be waiting before it can be generating again)
    if (wpState == previousWPState || (InStr(previousWPState, "previewing") && InStr(wpState, "generating"))) {
        return
    }
    
    if (InStr(wpState, "previewing")) {
        PostMessage, MSG_PREVIEW, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "inworld")) {
        PostMessage, MSG_LOAD, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "waiting") || InStr(wpState, "generating")) {
        PostMessage, MSG_RESET, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    }
    
    previousWPState := wpState
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

Kill() {
    ExitApp
}

CheckMain() {
    if (!WinExist(Format("ahk_pid {1}", mainPID))) {
        SendLog(LOG_LEVEL_INFO, Format("Reset manager {1} didnt find main script pid {2}, ending process", idx, mainPID))
        Kill()
    }
}