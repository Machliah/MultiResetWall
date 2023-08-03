; A Wall-Style Multi-Instance macro for Minecraft
; By Specnr and Machliah

#NoEnv
#Persistent
#SingleInstance Force
#MaxHotkeysPerInterval, 150
#Include %A_ScriptDir%\scripts\functions.ahk
#Include %A_ScriptDir%\scripts\MCDirAndPidFunctions.ahk
#Include %A_ScriptDir%\scripts\Instance.ahk
#Include %A_ScriptDir%\scripts\GlobalConstants.ahk
#Include <Addons>
#Include settings-Mach.ahk

SetKeyDelay, -1
SetWinDelay, 1
SetTitleMatchMode, 2
SetBatchLines, -1
CoordMode, Mouse, Screen
Thread, NoTimers, True

EnvGet, NUMBER_OF_PROCESSORS, NUMBER_OF_PROCESSORS
EnvGet, USERPROFILE, USERPROFILE
global THREAD_COUNT := NUMBER_OF_PROCESSORS
global USER_PROFILE := USERPROFILE

FileDelete, data/log.log
global logMsgQueue := ""
global resetsQueue := 0

OnMessage(MSG_TITLE, "UpdateInstanceState")
OnMessage(MSG_WAITING, "UpdateInstanceState")
OnMessage(MSG_GENERATING, "UpdateInstanceState")
OnMessage(MSG_PREVIEW, "UpdateInstanceState")
OnMessage(MSG_UNPAUSED, "UpdateInstanceState")
OnMessage(MSG_PAUSED, "UpdateInstanceState")
OnMessage(MSG_GAMESCREEN, "UpdateInstanceState")

CheckAHKVersion()

ForceLog(LOG_LEVEL_INFO, "Starting MultiResetWall v1.2")

global playThreads := playThreadsOverride > 0 ? playThreadsOverride : THREAD_COUNT ; total threads unless override
global lockThreads := lockThreadsOverride > 0 ? lockThreadsOverride : THREAD_COUNT ; total threads unless override
global highThreads := highThreadsOverride > 0 ? highThreadsOverride : affinityType != "N" ? Ceil(THREAD_COUNT * 0.95) : THREAD_COUNT ; 95% if advanced otherwise total threads unless override
global midThreads := midThreadsOverride > 0 ? midThreadsOverride : affinityType == "A" ? Ceil(THREAD_COUNT * 0.7) : highThreads ; 70% if advanced otherwise high unless override
global lowThreads := lowThreadsOverride > 0 ? lowThreadsOverride : affinityType != "N" ? Ceil(THREAD_COUNT * 0.5) : THREAD_COUNT ; 50% if advanced otherwise high unless override
global bgLoadThreads := bgLoadThreadsOverride > 0 ? bgLoadThreadsOverride : affinityType != "N" ? Ceil(THREAD_COUNT * 0.4) : THREAD_COUNT ; 40% unless override or none

global playBitMask := GetBitMask(playThreads)
global lockBitMask := GetBitMask(lockThreads)
global highBitMask := GetBitMask(highThreads)
global midBitMask := GetBitMask(midThreads)
global lowBitMask := GetBitMask(lowThreads)
global bgLoadBitMask := GetBitMask(bgLoadThreads)

Critical, On
UnsuspendEverythingMinecraft()
global mainPID := GetScriptPID()
global instances := CreateInstanceArray()
Critical, Off

SetTheme(theme)

CheckOBSPython()

UnlockAll(false)

CheckLaunchAudioGUI()

CheckOBSRunLevel()

BindTrayIconFunctions()

SendOBSCmd(GetCoverTypeObsCmd("Cover", false, instances))

ToWall(0)

FileAppend,,data/macro.reload
SendLog(LOG_LEVEL_INFO, "Wall setup done")
if (!disableTTS)
  ComObjCreate("SAPI.SpVoice").Speak(readyTTS)

SetTimer, CheckOverall, 2000
OnExit("Shutdown")

#Include hotkeys-Mach.ahk