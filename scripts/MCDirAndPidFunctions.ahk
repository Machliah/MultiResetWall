CreateInstanceArray() {
    SendLog(LOG_LEVEL_INFO, "Populating Minecraft instance data")
    rawPIDs := GetRawPIDs()
    
    if (!rawPIDs.Length()) {
        LaunchInstances()
    }
    
    mcdirs := []
    if (rawPIDs.Length() == GetLineCount("data/mcdirs.txt") && FileExist("data/mcdirs.txt"))
        mcdirs := GetMcDirsFromCache(rawPIDs.Length())
    else
        mcdirs := GetMcDirsFromPids(rawPIDs)
    
    instArray := []
    for idx, mcDir in mcdirs {
        instArray.Push(new Instance(idx, GetPIDFromMcDir(mcDir), mcDir))
    }
    return instArray
}

GetMcDir(pid) {
    command := Format("powershell.exe $x = Get-WmiObject Win32_Process -Filter \""ProcessId = {1}\""; $x.CommandLine", pid)
    rawOut := RunHide(command)
    if (InStr(rawOut, "--gameDir")) {
        strStart := RegExMatch(rawOut, "P)--gameDir (?:""(.+?)""|([^\s]+))", strLen, 1)
        mcdir := SubStr(rawOut, strStart+10, strLen-10) . "\"
        SendLog(LOG_LEVEL_INFO, Format("Got {1} from pid: {2}", mcdir, pid))
        return mcdir
    } else {
        strStart := RegExMatch(rawOut, "P)(?:-Djava\.library\.path=(.+?) )|(?:\""-Djava\.library.path=(.+?)\"")", strLen, 1)
        if (SubStr(rawOut, strStart+20, 1) == "=") {
            strLen -= 1
            strStart += 1
        }
        mcdir := StrReplace(SubStr(rawOut, strStart+20, strLen-28) . ".minecraft\", "/", "\")
        SendLog(LOG_LEVEL_INFO, Format("Got {1} from pid: {2}", mcdir, pid))
        return mcdir
    }
}

GetRawInstanceNumberFromMcDir(mcDir) {
    cfg := Format("{1}instance.cfg", SubStr(mcDir, 1, StrLen(mcDir) - 11))
    total := 0
    loop, Read, %cfg%
    {
        if (!InStr(A_LoopReadLine, "name=")) {
            Continue
        }
        
        pos := 1
        While pos := RegExMatch(A_LoopReadLine, "\d+", number, pos + StrLen(number)) {
            total += number
        }
    }
    return total
}

CheckOnePIDFromMcDir(proc, mcdir) {
    cmdLine := proc.Commandline
    if (RegExMatch(cmdLine, "-Djava\.library\.path=(?P<Dir>[^\""]+?)(?:\/|\\)natives", instDir)) {
        StringTrimRight, rawInstDir, mcdir, 1
        thisInstDir := SubStr(StrReplace(instDir, "/", "\"), 21, StrLen(instDir)-28) . "\.minecraft"
        if (rawInstDir == thisInstDir)
            return proc.ProcessId
    }
    return -1
}

GetPIDFromMcDir(mcdir) {
    for proc in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ExecutablePath like ""%jdk%javaw.exe%""") {
        if ((pid := CheckOnePIDFromMcDir(proc, mcdir)) != -1) {
            SendLog(LOG_LEVEL_INFO, Format("Got PID: {1} from {2}", pid, mcdir))
            return pid
        }
    }
    ; Broader search if some people use java.exe or some other edge cases
    for proc in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ExecutablePath like ""%java%""") {
        if ((pid := CheckOnePIDFromMcDir(proc, mcdir)) != -1) {
            SendLog(LOG_LEVEL_INFO, Format("Got PID: {1} using broader search from {2}", pid, mcdir))
            return pid
        }
    }
    SendLog(LOG_LEVEL_ERROR, Format("Failed to get PID from {1}", mcdir))
    return -1
}

GetRawPIDs() {
    rawPIDs := []
    WinGet, all, list
    Loop, %all%
    {
        WinGet, pid, PID, % Format("ahk_id {1}", all%A_Index%)
        WinGetTitle, title, % Format("ahk_pid {1}", pid)
        if (InStr(title, "Minecraft*")) {
            rawPIDs.Push(pid)
        }
    }
    return rawPIDs
}

GetMcDirFromFile(idx) {
    Loop, Read, data/mcdirs.txt
    {
        split := StrSplit(A_LoopReadLine,"~")
        if (idx == split[1]) {
            mcdir := split[2]
            StringReplace,mcdir,mcdir,`n,,A
            if FileExist(mcdir) {
                SendLog(LOG_LEVEL_INFO, Format("Got {1} from cache for instance {2}", mcdir, idx))
                return mcdir
            } else {
                SendLog(LOG_LEVEL_ERROR, Format("Didn't find mcdir file in GetMcDirFromFile. mcdir: {1}, idx: {2}", mcdir, idx))
                FileDelete, data/mcdirs.txt
                Reload
            }
        }
    }
}

GetMcDirsFromPids(rawPIDs) {
    SendLog(LOG_LEVEL_INFO, "Getting MC directories from raw pid array")
    rawNumToMcDir := {}
    if (rawPIDs.Length() == 1) {
        SendLog(LOG_LEVEL_INFO, "Only 1 instance detected, macro will adjust its usage")
        return [GetMcDir(rawPIDs[1])]
    }
    for i, rawPID in rawPIDs {
        mcDir := GetMcDir(rawPID)
        rawNum := GetRawInstanceNumberFromMcDir(mcDir)
        rawNumToMcDir[rawNum] := mcDir
    }
    fixedMcDirs := []
    for i, mcDir in rawNumToMcDir {
        if (mcDir) {
            fixedMcDirs.Push(mcDir)
        }
    }
    CreateMcDirCache(fixedMcDirs)
    return fixedMcDirs
}

GetMcDirsFromCache(instCount){
    SendLog(LOG_LEVEL_INFO, "Getting MC directories from cache file")
    mcdirs := []
    loop % instCount {
        mcdirs.Push(GetMcDirFromFile(A_Index))
    }
    return mcdirs
}

CreateMcDirCache(rawNumToMcDir) {
    SendLog(LOG_LEVEL_INFO, "Creating MC directories cache file")
    FileDelete, data/mcdirs.txt
    for i, mcdir in rawNumToMcDir {
        FileAppend,%i%~%mcdir%`n,data/mcdirs.txt
    }
}