; v1.0

#Include %A_ScriptDir%\functions.ahk
#Include, %A_ScriptDir%\GlobalConstants.ahk
#SingleInstance off
#NoTrayIcon
#NoEnv

global mcDir := A_Args[2]
global mainPID := A_Args[3]

global logFile := Format("{1}logs\latest.log", mcDir)

while (true) {
    Sleep, 300
    Loop, Read, %logFile%
    {
        if (InStr(A_LoopReadLine, "[Render thread/INFO]: Sound engine started")) {
            ForceLog(LOG_LEVEL_INFO, Format("Detected instance launch from {1}", logFile))
            Break 2
        }
    }
}

ExitApp