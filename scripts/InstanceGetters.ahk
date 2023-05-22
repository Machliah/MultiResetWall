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
    return this.state == "playing"
}

GetResetting() {
    return this.state == "resetting"
}

GetFocus() {
    return this.focus
}

GetIdle() {
    return this.state == "idle"
}

GetPreviewing() {
    return this.state == "previewing"
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
    
    if (this.GetPlaying() || this.GetResetting())
        return false
    
    return true
}
