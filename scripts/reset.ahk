#NoEnv
#NoTrayIcon
#Include settings-Mach.ahk
#Include %A_ScriptDir%\functions.ahk
#Include %A_ScriptDir%\GlobalConstants.ahk
#SingleInstance, off

SetKeyDelay, 0
SetBatchLines, -1
DetectHiddenWindows, On

global idx := A_Args[1]
global mainPID := A_Args[2]
global wpStateFile := A_Args[3]
global rmPID := GetScriptPID()

global playThreads := playThreadsOverride > 0 ? playThreadsOverride : THREAD_COUNT ; total threads unless override
global lockThreads := lockThreadsOverride > 0 ? lockThreadsOverride : THREAD_COUNT ; total threads unless override
global highThreads := highThreadsOverride > 0 ? highThreadsOverride : affinityType != "N" ? Ceil(THREAD_COUNT * 0.95) : THREAD_COUNT ; 95% or 2 less than max threads, whichever is higher unless override or none
global midThreads := midThreadsOverride > 0 ? midThreadsOverride : affinityType == "A" ? Ceil(THREAD_COUNT * 0.8) : highThreads ; 80% if advanced otherwise high unless override
global lowThreads := lowThreadsOverride > 0 ? lowThreadsOverride : affinityType != "N" ? Ceil(THREAD_COUNT * 0.7) : THREAD_COUNT ; 70% if advanced otherwise high unless override
global bgLoadThreads := bgLoadThreadsOverride > 0 ? bgLoadThreadsOverride : affinityType != "N" ? Ceil(THREAD_COUNT * 0.4) : THREAD_COUNT ; 40% unless override or none

global playBitMask := GetBitMask(playThreads)
global lockBitMask := GetBitMask(lockThreads)
global highBitMask := GetBitMask(highThreads)
global midBitMask := GetBitMask(midThreads)
global lowBitMask := GetBitMask(lowThreads)
global bgLoadBitMask := GetBitMask(bgLoadThreads)

global previousWPState := "unknown"

OnMessage(MSG_PLAY, "SetPlay")
OnMessage(MSG_LOCK, "SetLock")
OnMessage(MSG_RESET, "ResetSound")
OnMessage(MSG_KILL, "Kill")

SendLog(LOG_LEVEL_INFO, Format("Instance {1} reset manager started, PID: {2} state file: {3}", idx, rmPID, wpStateFile))

PostMessage, MSG_ASSIGN_RMPID, idx, rmPID,, % Format("ahk_pid {1}", mainPID)

SendLog(LOG_LEVEL_INFO, Format("Instance {1} starting reset management", idx))

SetTimer, CheckMain, 5000
SetTimer, ManageReset, %resetManagementLoopDelay%

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

ManageThisAffinity(activeInstance) {
    if (idx == activeInstance) { ; this is active instance
        SendLog(LOG_LEVEL_INFO, Format("instance {1} is the active instance", idx))
        SetAffinity(pid, playBitMask)
    } else if activeInstance { ; there is another active instance
        if (state == "inworld") { ; if loading
            SetAffinity(pid, lowBitMask)
        } else {
            SetAffinity(pid, bgLoadBitMask)
        }
    } else { ; there is no active instance
        if locked { ; if locked
            SetAffinity(pid, lockBitMask)
        } else if (state == "previewing") { ; if resetting
            affinityQueue := Func("SetAffinity").Bind(pid, lowBitMask)
            SetTimer, %affinityQueue%, -%previewBurstLength%
        } else if (state == "pre-preview") { ; if preview gen not reached
            SetAffinity(pid, midBitMask)
        } else if (state == "inworld") { ; if idle
            SetAffinity(pid, lowBitMask)
        } else {
            SetAffinity(pid, highBitMask)
        }
    }
}

Pause() {
    ControlSend,, {Blind}{F3 Down}{Esc}{F3 Up}, ahk_pid %pid%
}

Kill() {
    ExitApp
}

ResetSound() {
    if (sounds == "A" || sounds == "F" || sounds == "R") {
        SoundPlay, A_ScriptDir\..\media\reset.wav
        if obsResetMediaKey {
            send {%obsResetMediaKey% down}
            sleep, %obsDelay%
            send {%obsResetMediaKey% up}
        }
    }
}

CheckMain() {
    if (!WinExist(Format("ahk_pid {1}", mainPID))) {
        SendLog(LOG_LEVEL_INFO, Format("rm {1} didnt find {2}, killing", idx, mainPID))
        Kill()
    }
}