#NoEnv
#NoTrayIcon
#Include settings-Mach.ahk
#Include %A_ScriptDir%\functions.ahk
#Include %A_ScriptDir%\GlobalConstants.ahk
#SingleInstance, off

SetBatchLines, -1
DetectHiddenWindows, On

EnvGet, NUMBER_OF_PROCESSORS, NUMBER_OF_PROCESSORS
EnvGet, USERPROFILE, USERPROFILE
global THREAD_COUNT := NUMBER_OF_PROCESSORS
global USER_PROFILE := USERPROFILE

global idx := A_Args[1]
global mainPID := A_Args[2]
global wpStateFile := A_Args[3]

OnMessage(MSG_RESET, "ResetSound")
OnMessage(MSG_LOCK, "LockSound")
OnMessage(MSG_UNLOCK, "UnlockSound")
OnMessage(MSG_KILL, "Kill")

ForceLog(LOG_LEVEL_INFO, Format("Instance {1} reset manager started, MainPID: {2} state file: {3}", idx, mainPID, wpStateFile))

SetTimer, CheckMain, 500
SetTimer, ManageReset, 0

ManageReset() {
    ; title
    ; waiting
    ; generating,%
    ; previewing,%
    ; inworld,unpaused/paused/gamescreenopen
    
    static previousWPState := "unknown"
    
    FileRead, wpState, %wpStateFile%
    
    ; if nothing changed or if its generating after previewing (it should be waiting before it can be generating again)
    if (wpState == previousWPState) {
        return
    }
    
    if (InStr(wpState, "title")) {
        PostMessage, MSG_TITLE, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "waiting")) {
        PostMessage, MSG_WAITING, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "generating")) {
        PostMessage, MSG_GENERATING, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "previewing")) {
        PostMessage, MSG_PREVIEW, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "inworld,unpaused")) {
        PostMessage, MSG_UNPAUSED, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "inworld,paused")) {
        PostMessage, MSG_PAUSED, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
    } else if (InStr(wpState, "inworld,gamescreenopen")) {
        PostMessage, MSG_GAMESCREEN, idx, A_TickCount,, % Format("ahk_pid {1}", mainPID)
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

LockSound() {
    if (sounds == "A" || sounds == "F" || sounds == "L") {
        SoundPlay, A_ScriptDir\..\media\lock.wav
    }
    if obsLockMediaKey {
        send {%obsLockMediaKey% down}
        sleep, %obsDelay%
        send {%obsLockMediaKey% up}
    }
}

UnlockSound() {
    if (sounds == "A" || sounds == "F" || sounds == "L") {
        SoundPlay, A_ScriptDir\..\media\unlock.wav
    }
    if obsUnlockMediaKey {
        send {%obsUnlockMediaKey% down}
        sleep, %obsDelay%
        send {%obsUnlockMediaKey% up}
    }
}

Kill() {
    ExitApp
}

CheckMain() {
    if (!WinExist(Format("ahk_pid {1}", mainPID))) {
        ForceLog(LOG_LEVEL_WARNING, Format("Reset manager {1} didnt find main script pid {2}, ending process", idx, mainPID))
        Kill()
    }
}