class Instance {
    
    #Include %A_ScriptDir%\scripts\Window.ahk
    #Include %A_ScriptDir%\scripts\InstanceGetters.ahk
    #Include %A_ScriptDir%\scripts\InstanceSetters.ahk
    #Include %A_ScriptDir%\scripts\InstanceMethods.ahk
    
    __New(idx, pid, mcDir) {
        this.idx := idx
        this.pid := pid
        this.mcDir := mcDir
        
        this.locked := false
        this.state := "idle"
        this.previewStart := 0
        this.idleStart := 0
        this.focus := true
        
        this.lockImage := Format("{1}lock.png", mcDir)
        
        this.LaunchResetManager()
        
        this.window := New this.Window(this.idx, this.pid, this.mcDir)
        
        this.window.SetAffinity(highBitMask)
        
        SendLog(LOG_LEVEL_INFO, Format("Instance {1} ready for resetting", this.idx))
    }
    
    __Delete() {
        this.KillResetManager()
    }
    
    Reset(bypassLock:=true, extraProt:=0, force:=false) {
        if (!this.GetCanReset(bypassLock, extraProt, force))
            Return
        
        SendLog(LOG_LEVEL_INFO, Format("Instance {1} valid reset triggered", this.idx))
        
        this.SendReset()
        
        if (mode == "I")
            MoveResetInstance(this.idx)
        else if (obsControl == "C")
            SendOBSCmd(GetCoverTypeObsCmd("Cover",true,[this]))
        
        this.Unlock(false)
    }
    
    Switch(special:=false) {
        if (!this.locked) {
            this.Lock(false, false)
        }
        
        if (!this.GetCanPlay() && smartSwitch) {
            SwitchInstance(FindBypassInstance())
            return
        } else if !this.GetCanPlay() {
            return
        }
        
        this.state := "playing"
        
        this.SwitchFiles()
        
        ManageAffinities()
        
        this.window.SwitchTo()
        
        this.window.JoinInstance(special)
        
        this.SwitchToInstanceObs()
    }
    
    Exit(nextInst:=-1) {
        this.state := "resetting"
        
        this.window.GhostPie()
        
        this.window.ToggleFullscreen(false)
        
        this.ExitFiles()
        
        this.window.Restore()
        
        this.Reset(,,true)
        
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
    
    Lock(sound:=true, affinityChange:=true) {
        this.LockFiles()
        
        this.LockOBS()
        
        this.locked := true
        
        if affinityChange {
            ManageAffinity(this)
        }
        
        LockSound(sound)
    }
    
    Unlock(sound:=true) {
        this.UnlockFiles()
        
        this.UnlockOBS()
        
        this.locked := false
        
        UnlockSound(sound)
    }
    
    LockFiles() {
        if (this.locked) {
            return
        }
        FileCopy, % GetLockImage(), % this.lockImage, 1
        FileSetTime,, % this.lockImage, M
    }
    
    UnlockFiles() {
        if (!this.locked) {
            return
        }
        if (obsControl != "C") {
            FileCopy, A_ScriptDir\..\media\unlock.png, % this.lockImage, 1
            FileSetTime,, % this.lockImage, M
        }
    }
    
    SendReset() {
        if (!this.rmPID) {
            return
        }
        
        this.state := "resetting"
        
        ManageAffinity(this)
        
        this.window.SendResetInput()
        
        DetectHiddenWindows, On
        PostMessage, MSG_RESET,,,, % Format("ahk_pid {1}", this.rmPID)
        DetectHiddenWindows, Off
    }
    
    UpdatePreview(time) {
        if (this.GetPreviewing() || this.GetPlaying()) {
            return
        }
        
        this.state := "previewing"
        this.previewStart := time
        pauseFunc := Func("SendPauseInput").Bind(this.pid)
        SetTimer, %pauseFunc%, -%beforePauseDelay%
        affinityFunc := Func("ManageAffinity").Bind(this)
        SetTimer, %affinityFunc%, -%previewBurstLength%
    }
    
    UpdateLoad(time) {
        if (this.GetIdle() || this.GetPlaying()) {
            return
        }
        
        this.state := "idle"
        this.idleStart := time
        pauseFunc := Func("SendPauseInput").Bind(this.pid)
        SetTimer, %pauseFunc%, -%beforePauseDelay%
        affinityFunc := Func("ManageAffinity").Bind(this)
        SetTimer, %affinityFunc%, -%previewBurstLength%
    }
    
    CloseInstance() {
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
