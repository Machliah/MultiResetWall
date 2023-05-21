; All methods here are only called by the Instance class and not called from outside the Instance class

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