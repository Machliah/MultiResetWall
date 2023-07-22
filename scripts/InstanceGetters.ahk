; All Instance class basic getter methods, methods simply returning an instance variable are only called outside of the class

GetIdx() {
    return this.idx
}

GetPID() {
    return this.pid
}

GetMcDir() {
    return this.mcDir
}

GetLocked() {
    return this.locked
}

GetPlaying() {
    return this.playing
}

GetReset() {
    return this.state == "reset"
}

GetResetting() {
    return this.state == "waiting" || this.state == "generating"
}

GetFocus() {
    return this.focus
}

GetIdle() {
    return (this.state == "paused" || this.state == "unpaused" || this.state == "gamescreen") && !this.playing
}

GetPreviewing() {
    return this.state == "preview"
}

GetPreviewTime() {
    return A_TickCount - this.previewStart
}

GetIdleTime() {
    return A_TickCount - this.idleStart
}

GetTimeSinceReset() {
    return A_TickCount - this.lastReset
}

GetIsOpen() {
    return WinExist(Format("ahk_pid {1}", this.pid))
}

GetCanPlay() {
    if (this.GetIdle() || mode == "C")
        return true
    
    return false
}

GetCanReset(bypassLock:=true, extraProt:=0, force:=false) {
    
    if (!this.rmPID)
        return false
    
    if (force)
        return true
    
    if (this.locked && !bypassLock)
        return false
    
    if (this.GetPreviewTime() < spawnProtection + extraProt)
        return false
    
    if (this.GetPlaying() || this.GetResetting() || this.GetReset())
        return false
    
    return true
}
