; All methods here are only called by the Instance class and not called from outside the Instance class

UpdateTitle(time) {
    this.state := "title"
}

UpdateWaiting(time) {
    this.state := "waiting"
    
    ManageAffinity(this)
}

UpdateGenerating(time) {
    if (this.GetPreviewing()) {
        return
    }
    
    this.state := "generating"
    
    ManageAffinity(this)
}

UpdatePreview(time) {
    if (this.GetReset() || this.GetPreviewing()) {
        return
    }
    
    this.state := "preview"
    this.previewStart := A_TickCount
    
    SendOBSCmd(Format("Cover,0,{1}", this.idx))
    this.window.SendPauseInput(this)
    
    affinityFunc := Func("ManageAffinity").Bind(this)
    SetTimer, %affinityFunc%, -%burstLength%
}

UpdateUnpaused(time) {
    if (this.GetReset()) {
        return
    }
    
    if (this.GetResetting() && !this.GetPlaying()) {
        SendLog(LOG_LEVEL_WARNING, Format("Instance {1} safety cover uncover", this.idx))
        SendOBSCmd(Format("Cover,0,{1}", this.idx))
    }
    
    this.state := "unpaused"
    
    if (!this.GetIdle()) {
        this.idleStart := time
    }
    
    if (this.GetPlaying()) {
        return
    }
    
    this.window.SendPauseInput(this)
    
    affinityFunc := Func("ManageAffinity").Bind(this)
    SetTimer, %affinityFunc%, -%burstLength%
}

UpdatePaused(time) {
    if (this.GetReset()) {
        return
    }
    
    this.state := "paused"
}

UpdateGamescreen(time) {
    if (this.GetReset()) {
        return
    }
    
    this.state := "gamescreen"
}

SwitchFiles() {
    FileAppend,, % Format("{1}/sleepbg.lock", USER_PROFILE)
}

ExitFiles() {
    FileDelete, % Format("{1}/sleepbg.lock", USER_PROFILE)
}

LockOBS() {
    if (this.GetLocked()) {
        return
    }
    if (obsControl == "C" && mode != "I") {
        SendOBSCmd(GetCoverTypeObsCmd("Lock",true,[this]))
    }
}

UnlockOBS() {
    if (!this.GetLocked()) {
        return
    }
    if (obsControl == "C" && mode != "I") {
        SendOBSCmd(GetCoverTypeObsCmd("Lock",false,[this]))
    }
}