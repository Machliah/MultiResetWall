#NoEnv
#NoTrayIcon
#Include settings-Mach.ahk
#Include %A_ScriptDir%\functions.ahk
#SingleInstance, off

SetKeyDelay, 0
SetBatchLines, -1

global MSG_RESET := 0x04E20
global MSG_KILL := 0x04E21
global LOG_LEVEL_INFO = "INFO"
global LOG_LEVEL_WARNING = "WARN"
global LOG_LEVEL_ERROR = "ERR"

global idx := A_Args[1]
global pid := A_Args[2]
global doubleCheckUnexpectedLoads := A_Args[3]
global mcDir := A_Args[4]

global logFile := Format("{1}logs\latest.log", mcDir)
global idleFile := Format("{1}idle.tmp", mcDir)
global holdFile := Format("{1}hold.tmp", mcDir)
global previewFile := Format("{1}preview.tmp", mcDir)
global lockFile := Format("{1}lock.tmp", mcDir)
global killFile := Format("{1}kill.tmp", mcDir)

EnvGet, THREAD_COUNT, NUMBER_OF_PROCESSORS
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

global covered := false
global state := "unknown"
global lastImportantLine := GetLineCount(logFile)
global previewLoaded := true

FileDelete, %holdFile%
FileDelete, %killFile%
SendLog(LOG_LEVEL_INFO, Format("Instance {1} reset manager started: {2} {3} {4} {5} {6} {7} {8} {9} {10} {11} {12} {13} {14} {15}", idx, pid, logFile, idleFile, holdFile, previewFile, lockFile, killFile, playBitMask, lockBitMask, highBitMask, midBitMask, lowBitMask, bgLoadBitMask, doubleCheckUnexpectedLoads))

OnMessage(MSG_RESET, "Reset")
OnMessage(MSG_KILL, "Kill")

Reset() {
    if ((state == "resetting" && mode != "C") || state == "kill" || FileExist(killFile)) {
        FileDelete, %holdFile%
        SendLog(LOG_LEVEL_INFO, Format("Instance {1} discarding reset management, state: {2}", idx, state))
        return
    }
    state := "kill"
    previewLoaded := false
    covered := true
    FileAppend,, %holdFile%
    FileDelete, %previewFile%
    FileDelete, %idleFile%
    lastImportantLine := GetLineCount(logFile)
    ManageThisAffinity()
    SetTimer, ManageReset, -%manageResetAfter%
    if (sounds == "A" || sounds == "F" || sounds == "R") {
        SoundPlay, A_ScriptDir\..\media\reset.wav
        if obsResetMediaKey {
            send {%obsResetMediaKey% down}
            sleep, %obsDelay%
            send {%obsResetMediaKey% up}
        }
    }
}

Kill() {
    Critical, On
    SetAffinity(pid, GetBitMask(THREAD_COUNT))
    ExitApp
}

ManageReset() {
    start := A_TickCount
    state := "resetting"
    ManageThisAffinity()
    SendLog(LOG_LEVEL_INFO, Format("Instance {1} starting reset management", idx))
    while (True) {
        if (state == "kill" || FileExist(killFile)) {
            SendLog(LOG_LEVEL_INFO, Format("Instance {1} killing reset management from loop", idx))
            FileDelete, %killFile%
            return
        }
        sleep, %resetManagementLoopDelay%
        Loop, Read, %logFile%
        {
            if (A_Index <= lastImportantLine)
                Continue
            if (state == "resetting" && InStr(A_LoopReadLine, "Starting Preview")) {
                SetTimer, Pause, -%beforePauseDelay%
                state := "preview"
                lastImportantLine := GetLineCount(logFile)
                FileDelete, %holdFile%
                FileDelete, %previewFile%
                FileAppend, %A_TickCount%, %previewFile%
                SendLog(LOG_LEVEL_INFO, Format("Instance {1} found preview on log line: {2}", idx, A_Index))
                SetTimer, ManageThisAffinity, -%previewBurstLength% ; turn down previewBurstLength after preview detected
                Continue 2
            } else if (state != "idle" && InStr(A_LoopReadLine, "advancements") && !InStr(A_LoopReadLine, "927 advancements")) {
                SetTimer, Pause, -%beforePauseDelay%
                lastImportantLine := GetLineCount(logFile)
                FileDelete, %holdFile%
                if !FileExist(previewFile)
                    FileAppend, %A_TickCount%, %previewFile%
                FileDelete, %idleFile%
                FileAppend, %A_TickCount%, %idleFile%
                if (state == "resetting" && doubleCheckUnexpectedLoads) {
                    SendLog(LOG_LEVEL_INFO, Format("Instance {1} line dump: {2}", idx, A_LoopReadLine))
                    SendLog(LOG_LEVEL_WARNING, Format("Instance {1} found save while looking for preview, restarting reset management. (No World Preview/resetting right as world loads/lag)", idx))
                    state := "unknown"
                    SetTimer, ManageReset, -%resetManagementLoopDelay%
                } else {
                    SendLog(LOG_LEVEL_INFO, Format("Instance {1} found save on log line: {2}", idx, A_Index))
                    state := "idle"
                    FileRead, activeInstance, data/instance.txt
                    if (idx == activeInstance || !activeInstance)
                        SetTimer, ManageThisAffinity, -%previewBurstLength%
                }
                return
            } else if (InStr(A_LoopReadLine, "%")) {
                loadPercent := StrSplit(StrSplit(A_LoopReadLine, ": ")[3], "%")[1]
                if (state == "preview" && covered) {
                    covered := false
                    SendOBSCmd(Format("Cover,0,{1}", idx))
                }
                if (loadPercent > previewLoadPercent && !previewLoaded) {
                    previewLoaded := true
                    SendLog(LOG_LEVEL_INFO, Format("Instance {1} {2}% loading finished", idx, previewLoadPercent))
                    ManageThisAffinity()
                } else if (!previewLoaded && state == "preview") {
                    SendLog(LOG_LEVEL_INFO, Format("Instance {1} loaded {2}% out of {3}%", idx, loadPercent, previewLoadPercent))
                    lastImportantLine := GetLineCount(logFile)
                }
            }
        }
        if (resetManagementTimeout > 0 && A_TickCount - start > resetManagementTimeout) {
            SendLog(LOG_LEVEL_ERROR, Format("Instance {1} {2} millisecond timeout reached, ending reset management. May have left instance unpaused. (Lag/world load took too long/something else went wrong)", idx, resetManagementTimeout))
            state := "unknown"
            lastImportantLine := GetLineCount(logFile)
            FileDelete, %holdFile%
            FileAppend,, %previewFile%
            FileAppend,, %idleFile%
            return
        }
    }
}

ManageThisAffinity() {
    FileRead, activeInstance, data/instance.txt
    if (idx == activeInstance) { ; this is active instance
        SetAffinity(pid, playBitMask)
    } else if activeInstance { ; there is another active instance
        if (state != "idle") { ; if loading
            SetAffinity(pid, bgLoadBitMask)
        } else {
            SetAffinity(pid, lowBitMask)
        }
    } else { ; there is no active instance
        if FileExist(lockFile) ; if locked
            SetAffinity(pid, lockBitMask)
        else if (state == "resetting") ; if resetting
            SetAffinity(pid, highBitMask)
        else if (state == "preview" && !previewLoaded) ; if preview gen not reached
            SetAffinity(pid, midBitMask)
        else if (state == "preview" && previewLoaded) ; if preview gen reached
            SetAffinity(pid, lowBitMask)
        else if (state == "idle") ; if idle
            SetAffinity(pid, lowBitMask)
        else
            SetAffinity(pid, highBitMask)
    }
}

Pause() {
    if (state == "kill" || state == "resetting")
        return
    ControlSend,, {Blind}{F3 Down}{Esc}{F3 Up}, ahk_pid %pid%
}