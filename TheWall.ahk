; A Wall-Style Multi-Instance macro for Minecraft
; By Specnr
; v1.0

#NoEnv
#SingleInstance Force
#Include %A_ScriptDir%\scripts\functions.ahk
#Include settings.ahk

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

; Don't configure these
global McDirectories := []
global instances := 0
global rawPIDs := []
global PIDs := []
global RM_PIDs := []
global hwnds := []
global locked := []
global resetKeys := []
global lpKeys := []
global fsKeys := []
global commandkeys := []
global f1States := []
global resets := 0
global doubleCheckUnexpectedLoads := True

EnvGet, threadCount, NUMBER_OF_PROCESSORS
global playThreads := playThreadsOverride > 0 ? playThreadsOverride : threadCount ; total threads unless override
global lockThreads := lockThreadsOverride > 0 ? lockThreadsOverride : threadCount ; total threads unless override
global highThreads := highThreadsOverride > 0 ? highThreadsOverride : affinityType != "N" ? Ceil(threadCount * 0.95) : threadCount ; 95% or 2 less than max threads, whichever is higher unless override or none
global midThreads := midThreadsOverride > 0 ? midThreadsOverride : affinityType == "A" ? Ceil(threadCount * 0.8) : highThreads ; 80% if advanced otherwise high unless override
global lowThreads := lowThreadsOverride > 0 ? lowThreadsOverride : affinityType != "N" ? Ceil(threadCount * 0.7) : threadCount ; 70% if advanced otherwise high unless override
global bgLoadThreads := bgLoadThreadsOverride > 0 ? bgLoadThreadsOverride : affinityType != "N" ? Ceil(threadCount * 0.4) : threadCount ; 40% unless override or none

global playBitMask := GetBitMask(playThreads)
global lockBitMask := GetBitMask(lockThreads)
global highBitMask := GetBitMask(highThreads)
global midBitMask := GetBitMask(midThreads)
global lowBitMask := GetBitMask(lowThreads)
global bgLoadBitMask := GetBitMask(bgLoadThreads)

global instWidth := Floor(A_ScreenWidth / cols)
global instHeight := Floor(A_ScreenHeight / rows)
if (widthMultiplier)
  global newHeight := Floor(A_ScreenHeight / widthMultiplier)
global isWide := False

global MSG_RESET := 0x04E20
global LOG_LEVEL_INFO = "INFO"
global LOG_LEVEL_WARNING = "WARN"
global LOG_LEVEL_ERROR = "ERR"
global hasMcDirCache := FileExist("data/mcdirs.txt")
global themeLockCount := -1

FileDelete, data/log.log
FileDelete, %dailyAttemptsFile%

SendLog(LOG_LEVEL_INFO, "Wall launched", A_TickCount)

Loop, Files, %A_ScriptDir%\media\lock*.png
{
  FileDelete, %A_LoopFileFullPath%
}

SetTheme(theme)
GetAllPIDs()

if (obsControl == "C") {
  EnvGet, userProfileDir, USERPROFILE
  obsIni = %userProfileDir%\AppData\Roaming\obs-studio\global.ini
  IniRead, pyDir, %obsIni%, Python, Path64bit, N
  if (!FileExist(Format("{1}\python.exe", pyDir))) {
    pyPath := RegExReplace(ComObjCreate("WScript.Shell").Exec("python -c ""import sys; print(sys.executable)""").StdOut.ReadAll(), " *(\n|\r)+","")
    if (!FileExist(pyPath)) {
      SendLog(LOG_LEVEL_WARNING, "Couldn't find Python path", A_TickCount)
    } else {
      SplitPath, pyPath,, pyDir
      IniWrite, %pyDir%, %obsIni%, Python, Path64bit
      SendLog(LOG_LEVEL_INFO, Format("Automatically set OBS Python install path to {1}", pyDir), A_TickCount)
    }
  }
}

for i, mcdir in McDirectories {
  pid := PIDs[i]
  logs := mcdir . "logs\latest.log"
  idle := mcdir . "idle.tmp"
  hold := mcdir . "hold.tmp"
  preview := mcdir . "preview.tmp"
  lock := mcdir . "lock.tmp"
  kill := mcdir . "kill.tmp"
  VerifyInstance(mcdir, pid, i)
  resetKey := resetKeys[i]
  lpKey := lpKeys[i]
  SendLog(LOG_LEVEL_INFO, Format("Running a reset manager: {1} {2} {3} {4} {5} {6} {7} {8} {9} {10} {11} {12} {13} {14} {15} {16} {17}", pid, logs, idle, hold, preview, lock, kill, resetKey, lpKey, i, playBitMask, lockBitMask, highBitMask, midBitMask, lowBitMask, bgLoadBitMask, doubleCheckUnexpectedLoads), A_TickCount)
  Run, "%A_ScriptDir%\scripts\reset.ahk" %pid% "%logs%" "%idle%" "%hold%" "%preview%" "%lock%" "%kill%" %resetKey% %lpKey% %i% %playBitMask% %lockBitMask% %highBitMask% %midBitMask% %lowBitMask% %bgLoadBitMask% %doubleCheckUnexpectedLoads%, %A_ScriptDir%,, rmpid
  DetectHiddenWindows, On
  WinWait, ahk_pid %rmpid%
  DetectHiddenWindows, Off
  RM_PIDs[i] := rmpid
  hwnds[i] := getHwndForPid(pid)
  UnlockInstance(i, False)
  if (!FileExist(idle))
    FileAppend, %A_TickCount%, %idle%
  if FileExist(hold)
    FileDelete, %hold%
  if FileExist(kill)
    FileDelete, %kill%
  if FileExist(preview)
    FileDelete, %preview%
  WinGetTitle, winTitle, ahk_pid %pid%
  if !InStr(winTitle, " - ") {
    ControlClick, x0 y0, ahk_pid %pid%,, RIGHT
    ControlSend,, {Blind}{Esc}, ahk_pid %pid%
    WinMinimize, ahk_pid %pid%
    WinRestore, ahk_pid %pid%
  }
  if (windowMode == "B") {
    WinSet, Style, -0xC40000, ahk_pid %pid%
  } else {
    WinSet, Style, +0xC40000, ahk_pid %pid%
  }
  if (widthMultiplier) {
    pid := PIDs[i]
    WinMove, ahk_pid %pid%,,0,0,%A_ScreenWidth%,%newHeight%
  } else {
    WinMaximize, ahk_pid %pid%
  }
  WinSet, AlwaysOnTop, Off, ahk_pid %pid%
  SendLog(LOG_LEVEL_INFO, Format("Instance {1} ready for resetting", i), A_TickCount)
}

SetTitles()

SendLog(LOG_LEVEL_INFO, Format("All instances ready for resetting", i), A_TickCount)

for i, tmppid in PIDs {
  SetAffinity(tmppid, highBitMask)
}

if audioGui {
  Gui, New
  Gui, Show,, The Wall Audio
}

WinGet, obsPid, PID, OBS
if IsProcessElevated(obsPid) {
  MsgBox, Your OBS was run as admin which may cause wall hotkeys to not work. If this happens restart OBS and launch it normally.
    SendLog(LOG_LEVEL_WARNING, "OBS was run as admin which may cause wall hotkeys to not work", A_TickCount)
}

Menu, Tray, Add, Delete Worlds, WorldBop

Menu, Tray, Add, Close Instances, CloseInstances

Menu, Tray, Add, Launch Instances, LaunchInstances

ToWall(0)

SendLog(LOG_LEVEL_INFO, "Wall setup done", A_TickCount)
if (!disableTTS)
  ComObjCreate("SAPI.SpVoice").Speak("Ready")

#Persistent
OnExit, ExitSub
SetTimer, CheckScripts, 20
return

ExitSub:
  if A_ExitReason not in Logoff,Shutdown
  {
    DetectHiddenWindows, On
    loop, %instances% {
      kill := McDirectories[A_Index] . "kill.tmp"
      pid := RM_PIDs[A_Index]
      WinClose, ahk_pid %pid%
      WinWaitClose, ahk_pid %pid%
    }
    for i, tmppid in PIDs {
      SetAffinity(tmppid, playBitMask)
    }
    DetectHiddenWindows, Off
  }
ExitApp

CheckScripts:
  Critical
  if resets
    CountAttempts()
return

#Include hotkeys.ahk