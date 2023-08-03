class Instance {
    
    #Include %A_ScriptDir%\scripts\Window.ahk
    #Include %A_ScriptDir%\scripts\InstanceGetters.ahk
    #Include %A_ScriptDir%\scripts\InstanceSetters.ahk
    #Include %A_ScriptDir%\scripts\InstanceMethods.ahk
    
    __New(idx, pid, mcDir) {
        this.idx := idx
        this.pid := pid
        this.mcDir := mcDir
        
        this.state := "paused"
        
        this.playing := false
        this.locked := false
        this.focus := true
        this.suspended := false
        
        this.previewStart := 0
        this.idleStart := 0
        this.playStart := 0
        this.lastReset := 0
        
        this.lockImage := Format("{1}lock.png", mcDir)
        
        this.LaunchResetManager()
        
        this.window := New this.Window(this.idx, this.pid, this.mcDir)
        
        this.window.SetAffinity(highBitMask)
    }
    
    __Delete() {
        this.ResumeInstance()
        this.KillResetManager()
    }
    
    Reset(bypassLock:=true, extraProt:=0, force:=false) {
        if (!this.GetCanReset(bypassLock, extraProt, force))
            Return
        
        this.Unlock(false)
        
        this.SendReset()
        
        ManageAffinity(this)
        
        if (mode == "I")
            MoveResetInstance(this.idx)
        else if (obsControl == "C")
            SendOBSCmd(GetCoverTypeObsCmd("Cover",true,[this]))
    }
    
    Switch(special:=false) {
        if (!this.locked) {
            this.Lock(false, false)
        }
        
        if (!this.GetCanPlay() && smartSwitch && mode != "C") {
            SwitchInstance(FindBypassInstance())
            return
        } else if (!this.GetCanPlay() && mode != "C") {
            return
        }
        
        this.playing := true
        this.playStart := A_TickCount
        
        this.SwitchFiles()
        
        ManageAffinities()
        
        this.window.SwitchTo()
        
        this.window.JoinInstance(special)
        
        this.SwitchToInstanceObs()
    }
    
    Exit(nextInst:=-1) {
        this.playing := false
        
        this.window.GhostPie()
        
        this.state := "reset"
        
        this.window.ToggleFullscreen(false)
        
        this.ExitFiles()
        
        this.window.Restore()
        
        this.Reset(,,true)
        
        UnsuspendAll()
        ManageAffinities()
        
        nextInst := GetNextInstance(this.idx, nextInst)
        if (nextInst <= 0) {
            ToWall(this.idx)
        } else {
            SwitchInstance(nextInst)
        }
        
        this.window.Widen()
        
        this.window.SendToBack()
    }
    
    UpdateState(time, msg) {
        switch msg
        {
        case MSG_TITLE:
            this.UpdateTitle(time)
        case MSG_WAITING:
            this.UpdateWaiting(time)
        case MSG_GENERATING:
            this.UpdateGenerating(time)
        case MSG_PREVIEW:
            this.UpdatePreview(time)
        case MSG_UNPAUSED:
            this.UpdateUnpaused(time)
        case MSG_PAUSED:
            this.UpdatePaused(time)
        case MSG_GAMESCREEN:
            this.UpdateGamescreen(time)
        }
    }
    
    Lock(sound:=true, affinityChange:=true) {
        this.LockFiles()
        
        this.LockOBS()
        
        this.locked := true
        
        if affinityChange {
            ManageAffinity(this)
        }
        
        if (!sound) {
            return
        }
        DetectHiddenWindows, On
        PostMessage, MSG_LOCK,,,, % Format("ahk_pid {1}", this.rmPID)
        DetectHiddenWindows, Off
    }
    
    Unlock(sound:=true) {
        this.UnlockFiles()
        
        this.UnlockOBS()
        
        this.locked := false
        
        if (!sound) {
            return
        }
        DetectHiddenWindows, On
        PostMessage, MSG_UNLOCK,,,, % Format("ahk_pid {1}", this.rmPID)
        DetectHiddenWindows, Off
    }
    
    LockFiles() {
        if (this.locked) {
            return
        }
        FileCopy, % GetLockImage(), % this.lockImage, 1
        FileSetTime,, % this.lockImage, M
    }
    
    UnlockFiles() {
        if (!this.locked || obsControl == "C") {
            return
        }
        FileCopy, A_ScriptDir\..\media\unlock.png, % this.lockImage, 1
        FileSetTime,, % this.lockImage, M
    }
    
    SendReset() {
        if (!this.rmPID) {
            return
        }
        
        this.state := "reset"
        this.lastReset := A_TickCount
        
        this.window.SendResetInput()
        
        DetectHiddenWindows, On
        PostMessage, MSG_RESET,,,, % Format("ahk_pid {1}", this.rmPID)
        DetectHiddenWindows, Off
    }
    
    SwitchToInstanceObs() {
        obsKey := ""
        if (obsControl == "C") {
            SendOBSCmd("Play," . this.idx)
            return
        } else if (obsControl == "N") {
            obsKey := "Numpad" . this.idx
        } else if (obsControl == "F") {
            obsKey := "F" . (this.idx+12)
        } else if (obsControl == "ARR") {
            obsKey := obsCustomKeyArray[this.idx]
        }
        Send {%obsKey% down}
        Sleep, %obsDelay%
        Send {%obsKey% up}
    }
    
    FreeMemory() {
        h := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", this.pid)
        DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
        DllCall("CloseHandle", "Int", h)
    }
    
    SuspendInstance() {
        if (this.playing) {
            return
        }
        this.suspended := true
        hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", this.pid)
        If (hProcess) {
            DllCall("ntdll.dll\NtSuspendProcess", "Int", hProcess)
            DllCall("CloseHandle", "Int", hProcess)
        }
        this.FreeMemory()
    }
    
    ResumeInstance() {
        hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", this.pid)
        If (hProcess) {
            DllCall("ntdll.dll\NtResumeProcess", "Int", hProcess)
            DllCall("CloseHandle", "Int", hProcess)
        }
        this.suspended := false
    }
    
    CloseInstance() {
        this.ResumeInstance()
        WinClose, % Format("ahk_pid {1}", this.pid)
        this.KillResetManager()
    }
    
    LaunchResetManager() {
        stateFile := Format("{1}wpstateout.txt", this.mcDir)
        SendLog(LOG_LEVEL_INFO, Format("Running a reset manager: {1} {2} {3}", this.idx, mainPID, stateFile))
        Run, % Format("""{1}`\scripts`\reset.ahk"" {2} {3} ""{4}", A_ScriptDir, this.idx, mainPID, stateFile), %A_ScriptDir%,, rmPID
        this.rmPID := rmPID
    }
    
    KillResetManager() {
        DetectHiddenWindows, On
        PostMessage, MSG_KILL,,,, % Format("ahk_pid {1}", this.rmPID)
        WinWaitClose, % Format("ahk_pid {1}", this.rmPID)
        DetectHiddenWindows, Off
        this.window.SetAffinity(GetBitMask(THREAD_COUNT))
    }
}
