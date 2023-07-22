; v1.0

#Include, %A_ScriptDir%\..\scripts\functions.ahk
#Include, %A_ScriptDir%\..\scripts\MCDirAndPidFunctions.ahk
#Include, %A_ScriptDir%\..\scripts\GlobalConstants.ahk
#SingleInstance, Force
#NoEnv

global mainPID := GetScriptPID()
global launching := 0
global launched := 0

path := A_ScriptDir . "\..\data\mcdirs.txt"
if !FileExist(path) {
    MsgBox, Missing cache, you need to run TheWall.ahk with all instances open at least once before using this script.
    ExitApp
}

FileReadLine, dirData, %path%, 1
mmc := StrSplit(StrSplit(dirData, "instances\")[1], "~")[2]

if !WinExist("MultiMC") {
    launchMmc := mmc . "MultiMC.exe"
    Run,%launchMmc%
    Sleep, 2000
}

namesPath := A_ScriptDir . "\..\data\names.txt"
doOffline := FileExist(namesPath)
names := []
if doOffline {
    Loop, Read, %namesPath%
    {
        names.Push(A_LoopReadLine)
    }
}

path := A_ScriptDir . "\..\data\mcdirs.txt"
Loop, Read, %path%
{
    mcdir := StrSplit(A_LoopReadLine, "~")[2]
    idx := StrSplit(A_LoopReadLine, "~")[1]
    if (GetPIDFromMcDir(mcdir) != -1)
        continue
    launching++
    instName := StrSplit(StrSplit(A_LoopReadLine, "instances\")[2], "\.minecraft")[1]
    cmd := mmc . "MultiMC.exe -l """ . instName . """"
    if doOffline {
        name := names[idx]
        cmd .= " -o -n """ . name . """"
    }
    Run,%cmd%,,Hide
    Sleep, 300
}
ForceLog(LOG_LEVEL_INFO, Format("Launching {1} instances", launching))

Sleep, 10000

while (true) {
    Sleep, 500
    open := 0
    WinGet, all, list
    Loop, %all%
    {
        WinGet, pid, PID, % "ahk_id " all%A_Index%
        WinGetTitle, title, ahk_pid %pid%
        if (InStr(title, "Minecraft* ")) {
            open++
        }
        if (open == launching) {
            ForceLog(LOG_LEVEL_INFO, Format("All instances open, starting launch checkers"))
            break 2
        }
    }
}

checkers := []
Loop, Read, %path%
{
    mcdir := StrSplit(A_LoopReadLine, "~")[2]
    RunWait, % Format("""{1}/scripts/confirmInstanceLaunch.ahk"" {2} ""{3}", A_WorkingDir, mainPID, mcDir), %A_WorkingDir%,, checkerPID
    checkers.Push(checkerPID)
}

DetectHiddenWindows, On

while (true) {
    Sleep, 500
    launched := 0
    WinGet, all, list
    Loop, %all%
    {
        WinGet, pid, PID, % "ahk_id " all%A_Index%
        checkers.RemoveAt(HasVal(checkers, pid))
        if (!checkers.Length()) {
            ExitApp
        }
    }
}

HasVal(haystack, needle) {
    for index, value in haystack
        if (value = needle)
            return index
    return 0
}