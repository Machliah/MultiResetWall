; All Instance class basic setter methods, methods simply setting an instance variable are only called outside of the class

SetPlaying(playing) {
    if (playing) {
        this.playing := true
        ManageAffinity(this)
    } else {
        this.playing := false
    }
}

SetLocked(lock) {
    this.locked := lock
}