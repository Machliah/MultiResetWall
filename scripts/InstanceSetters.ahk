; All Instance class basic setter methods, methods simply setting an instance variable are only called outside of the class

SetPlaying(playing) {
    if (playing) {
        this.playing := true
    } else {
        this.playing := false
    }
    ManageAffinity(this)
}

SetLocked(lock) {
    this.locked := lock
}