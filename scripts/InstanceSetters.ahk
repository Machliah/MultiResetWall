; All Instance class basic setter methods, methods simply setting an instance variable are only called outside of the class

SetPlaying(playing) {
    if (playing) {
        this.state := "playing"
    } else {
        this.state := "idle"
    }
    ManageAffinity(this)
}

SetLocked(lock) {
    this.locked := lock
}

SetRMPID(rmPID) {
    this.rmPID := rmPID
}