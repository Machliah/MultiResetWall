Class Window {
    __New(idx, pid, mcDir) {
        this.idx := idx
        this.pid := pid
        this.mcDir := mcDir
        this.f1State := 0
        this.unpauseOnSwitch := true
        this.hwnd := this.GetHwnd()
        
        this.VerifyInstance()
        
        this.PrepareWindow()
    }
    
    GetHwnd() {
        WinGet, hwnd, ID, % Format("ahk_pid {1}", this.pid)
        return StrReplace(hwnd, "ffffffff")
    }
    
    PrepareWindow() {
        WinGetTitle, winTitle, % Format("ahk_pid {1}", this.pid)
        if !InStr(winTitle, " - ") {
            ControlClick, x0 y0, % Format("ahk_pid {1}", this.pid),, RIGHT
            ControlSend,, {Blind}{Esc}, % Format("ahk_pid {1}", this.pid)
            WinMinimize, % Format("ahk_pid {1}", this.pid)
            WinRestore, % Format("ahk_pid {1}", this.pid)
        }
        if (windowMode == "B") {
            WinSet, Style, -0xC40000, % Format("ahk_pid {1}", this.pid)
        } else {
            WinSet, Style, +0xC40000, % Format("ahk_pid {1}", this.pid)
        }
        this.Widen()
        WinSet, AlwaysOnTop, Off, % Format("ahk_pid {1}", this.pid)
        
        this.SetTitle()
    }
    
    SendResetInput() {
        ControlSend, ahk_parent, % Format("{Blind}{{1}}{{2}}", this.lpKey, this.resetKey), % Format("ahk_pid {1}", this.pid)
        resetsQueue++
    }
    
    SendPauseInput(instance) {
        ControlSend, ahk_parent, {Blind}{F3 Down}{Esc}{F3 Up}, % Format("ahk_pid {1}", instance.GetPID())
    }
    
    SwitchTo() {
        WinMinimize, % Format("ahk_id {1}", GetProjectorID())
        
        foreGroundWindow := DllCall("GetForegroundWindow")
        windowThreadProcessId := DllCall("GetWindowThreadProcessId", "uint", foreGroundWindow, "uint", 0)
        currentThreadId := DllCall("GetCurrentThreadId")
        DllCall("AttachThreadInput", "uint", windowThreadProcessId, "uint", currentThreadId, "int", 1)
        if (widthMultiplier && (windowMode == "W" || windowMode == "B"))
            DllCall("SendMessage", "uint", this.hwnd, "uint", 0x0112, "uint", 0xF030, "int", 0) ; fast maximize
        DllCall("SetForegroundWindow", "uint",this.hwnd) ; Probably only important in windowed, helps application take input without a Send Click
        DllCall("BringWindowToTop", "uint", this.hwnd)
        DllCall("AttachThreadInput", "uint", windowThreadProcessId, "uint", currentThreadId, "int", 0)
        
        if (windowMode == "F") {
            this.ToggleFullscreen(true)
        }
    }
    
    JoinInstance(special:=false) {
        ControlSend,, {Blind}{Esc}, % Format("ahk_pid {1}", this.pid)
        if (this.f1State == 2)
            ControlSend,, {Blind}{F1}, % Format("ahk_pid {1}", this.pid)
        if (special)
            this.OnJoinSettingsChange()
        if (coop)
            ControlSend,, {Blind}{Esc}{Tab 7}{Enter}{Tab 4}{Enter}{Tab}{Enter}, % Format("ahk_pid {1}", this.pid)
        if (!this.unpauseOnSwitch)
            ControlSend,, {Blind}{Esc}, % Format("ahk_pid {1}", this.pid)
    }
    
    OnJoinSettingsChange() {
        rdPresses := renderDistance - 2
        ControlSend,, {Blind}{Shift down}{F3 down}{f 30}{Shift up}{f %rdPresses%}{F3 up}, % Format("ahk_pid {1}", this.pid)
        if (toggleChunkBorders)
            ControlSend,, {Blind}{F3 down}{g}{F3 up}, % Format("ahk_pid {1}", this.pid)
        if (toggleHitBoxes)
            ControlSend,, {Blind}{F3 down}{b}{F3 up}, % Format("ahk_pid {1}", this.pid)
        FOVPresses := ceil((110-fov)*1.7875)
        entityPresses := (5 - (entityDistance*.01)) * 143 / 4.5
        ControlSend,, {Blind}{F3 down}{d}{F3 up}{Esc}{Tab 6}{Enter}{Tab 1}{Right 150}{Left %FOVPresses%}{Tab 5}{Enter}{Tab 17}{Right 150}{Left %entityPresses%}{Esc 2}, % Format("ahk_pid {1}", this.pid)
    }
    
    GhostPie() {
        if (this.state == "paused" || this.state == "gamescreen") {
            ControlSend,, {Blind}{Esc}, % Format("ahk_pid {1}", this.pid)
        }
        if this.f1State
            ControlSend,, {Blind}{F1}{F3}, % Format("ahk_pid {1}", this.pid)
        else
            ControlSend,, {Blind}{F3}, % Format("ahk_pid {1}", this.pid)
    }
    
    Restore() {
        WinRestore, % Format("ahk_pid {1}", this.pid)
    }
    
    Widen() {
        newHeight := Floor(A_ScreenHeight / widthMultiplier)
        if widthMultiplier {
            WinRestore, % Format("ahk_pid {1}", this.pid)
            WinMove, % Format("ahk_pid {1}", this.pid),,0,0,%A_ScreenWidth%,%newHeight%
        }
    }
    
    SendToBack() {
        Winset, Bottom,, % Format("ahk_pid {1}", this.pid)
    }
    
    ToggleFullscreen(switching) {
        isFs := CheckOptionsForValue(this.mcDir . "options.txt", "fullscreen:", "false") == "true"
        if (switching || (isFs && !switching)) {
            ControlSend, ahk_parent, % Format("{Blind}{{1}}", this.fsKey), % Format("ahk_pid {1}", this.pid)
            sleep, %fullscreenDelay%
        }
    }
    
    SetAffinity(mask) {
        hProc := DllCall("OpenProcess", "UInt", 0x0200, "Int", false, "UInt", this.pid, "Ptr")
        DllCall("SetProcessAffinityMask", "Ptr", hProc, "Ptr", mask)
        DllCall("CloseHandle", "Ptr", hProc)
    }
    
    SetTitle() {
        WinSetTitle, % Format("ahk_pid {1}", this.pid), , % Format("Minecraft* - Instance {1}", this.idx)
    }
    
    VerifyInstance() {
        SendLog(LOG_LEVEL_INFO, Format("Starting instance verification for directory: {1}", this.mcDir))
        moddir := this.mcDir . "mods\"
        optionsFile := this.mcDir . "options.txt"
        atum := false
        wp := false
        standardSettings := false
        fastReset := false
        sleepBg := false
        sodium := false
        srigt := false
        ; Check for mod dependencies
        Loop, Files, %moddir%*.jar
        {
            if InStr(A_LoopFileName, ".disabled")
                continue
            else if InStr(A_LoopFileName, "atum")
                atum := true
            else if InStr(A_LoopFileName, "worldpreview")
                wp := true
            else if InStr(A_LoopFileName, "standardsettings")
                standardSettings := true
            else if InStr(A_LoopFileName, "fast-reset")
                fastReset := true
            else if InStr(A_LoopFileName, "sleepbackground")
                sleepBg := true
            else if InStr(A_LoopFileName, "sodium")
                sodium := true
            else if InStr(A_LoopFileName, "SpeedRunIGT")
                srigt := true
        }
        
        ; Return early if missing either of the 2 required mods
        if !atum {
            SendLog(LOG_LEVEL_ERROR, Format("Instance {1} missing required mod: atum. Macro will not work. Download: https://modrinth.com/mod/atum/versions. (In directory: {2})", this.idx, moddir))
            MsgBox, % Format("Instance {1} missing required mod: atum. Macro will not work. Download: https://modrinth.com/mod/atum/versions.`n(In directory: {2})", this.idx, moddir)
            return
        }
        if !wp {
            SendLog(LOG_LEVEL_ERROR, Format("Instance {1} missing required mod: World Preview. Macro will not work. Download: https://github.com/Minecraft-Java-Edition-Speedrunning/mcsr-worldpreview-1.16.1/releases. (In directory: {2})", idx, moddir))
            MsgBox, % Format("Instance {1} missing required mod: World Preview. Macro will not work. Download: https://github.com/Minecraft-Java-Edition-Speedrunning/mcsr-worldpreview-1.16.1/releases.`n(In directory: {2})", this.idx, moddir)
            return
        }
        
        ; Read the atum.properties and set unpauseOnSwitch to false if a seed is set
        atumConfig := this.mcDir . "config\atum\atum.properties"
        Loop, Read, %atumConfig%
        {
            if (InStr(A_LoopReadLine, "seed=") && StrLen(A_LoopReadLine) > 5) {
                SendLog(LOG_LEVEL_INFO, "Found a set seed, setting 'unpauseOnSwitch' to False")
                this.unpauseOnSwitch := False
                break
            }
        }
        
        FileRead, options, %optionsFile%
        if !standardSettings {
            SendLog(LOG_LEVEL_WARNING, Format("Instance {1} missing highly recommended mod standardsettings. Download: https://github.com/KingContaria/StandardSettings/releases. (In directory: {2})", idx, moddir))
            MsgBox, % Format("Instance {1} missing highly recommended mod standardsettings. Download: https://github.com/KingContaria/StandardSettings/releases.`n(In directory: {2})", idx, moddir)
            ; Verify pauseOnLostFocus
            if InStr(options, "pauseOnLostFocus:true") {
                MsgBox, % Format("Instance {1} has required disabled setting pauseOnLostFocus enabled. Please FIRST disable it with f3+p and THEN press OK to continue", this.idx)
                SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had pauseOnLostFocus set true, macro requires it false. User was informed. (In file: {2})", this.idx, optionsFile))
            }
            
            ; Verify fullscreen users fullscreen key
            if (windowMode == "F") {
                if (InStr(options, "key_key.fullscreen:key.keyboard.unknown")) {
                    MsgBox, % Format("Instance {1} missing required hotkey for fullscreen mode: Fullscreen. Please FIRST set it in your hotkeys and THEN press OK to continue", this.idx)
                    SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Fullscreen key set. User was informed. (In file: {2})", this.idx, optionsFile))
                }
                this.fsKey := CheckOptionsForValue(optionsFile, "key_key.fullscreen", "F11")
                SendLog(LOG_LEVEL_INFO, Format("Found Fullscreen key: {1} for instance {2} from {3}", this.fsKey, this.idx, optionsFile))
            }
            
            ; Verify Create New World key
            if (InStr(options, "key_Create New World:key.keyboard.unknown")) {
                MsgBox, % Format("Instance {1} missing required hotkey: Create New World. Please FIRST set it in your hotkeys and THEN press OK to continue", this.idx)
                SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Create New World key set. User was informed. (In file: {2})", this.idx, optionsFile))
            }
            this.resetKey := CheckOptionsForValue(optionsFile, "key_Create New World", "F6")
            SendLog(LOG_LEVEL_INFO, Format("Found Create New World: {1} for instance {2} from {3}", this.resetKey, this.idx, optionsFile))
            
            ; Verify Leave Preview key
            if (InStr(options, "key_Leave Preview:key.keyboard.unknown")) {
                MsgBox, % Format("Instance {1} missing highly recommended hotkey: Leave Preview. Please FIRST set it in your hotkeys and THEN press OK to continue", this.idx)
                SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Leave Preview key set. User was informed. (In file: {2})", this.idx, optionsFile))
            }
            this.lpKey := CheckOptionsForValue(optionsFile, "key_Leave Preview", "h")
            SendLog(LOG_LEVEL_INFO, Format("Found Leave Preview key: {1} for instance {2} from {3}", this.lpKey, this.idx, optionsFile))
            
        } else {
            standardOptionsFile := this.mcDir . "config\standardoptions.txt"
            FileRead, standardOptions, %standardOptionsFile%
            
            ; Check for and use global standard options file
            if (RegExMatch(standardOptions, "[A-Z]:(\/|\\).+\.txt", globalPath)) {
                standardOptionsFile := globalPath
                SendLog(LOG_LEVEL_INFO, Format("Global standard options file detected, rereading standard options from {1}", standardOptionsFile))
                FileRead, standardOptions, %standardOptionsFile%
            }
            
            ; Fix fullscreen:true in standard options
            if (InStr(standardOptions, "fullscreen:true") && instances.Length() > 1) {
                standardOptions := StrReplace(standardOptions, "fullscreen:true", "fullscreen:false")
                SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had fullscreen set true, macro requires it false. Automatically fixed. (In file: {2})", this.idx, standardOptionsFile))
            }
            
            ; Fix pauseOnLostFocus:true in standard options
            if (InStr(standardOptions, "pauseOnLostFocus:true") && instances.Length() > 1) {
                standardOptions := StrReplace(standardOptions, "pauseOnLostFocus:true", "pauseOnLostFocus:false")
                SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had pauseOnLostFocus set true, macro requires it false. Automatically fixed. (In file: {2})", this.idx, standardOptionsFile))
            }
            
            ; Verify and set instance standard f1 state
            if (RegExMatch(standardOptions, "f1:.+", f1Match)) {
                SendLog(LOG_LEVEL_INFO, Format("Instance {1} f1 state '{2}' found. This will be used for ghost pie and instance join. (In file: {3})", this.idx, f1Match, standardOptionsFile))
                this.f1State := f1Match == "f1:true" ? 2 : 1
            }
            
            ; Verify Create New World key
            Loop, 1 {
                if (InStr(standardOptions, "key_Create New World:key.keyboard.unknown")) {
                    Loop, 1 {
                        MsgBox, 4, Create New World Key, % Format("Instance {1} has no Create New World hotkey set. Would you like to set this back to default (F6)?`n(In file: {2})", this.idx, standardOptionsFile)
                        IfMsgBox No
                            break
                        standardOptions := StrReplace(standardOptions, "key_Create New World:key.keyboard.unknown", "key_Create New World:key.keyboard.f6")
                        this.resetKey := "F6"
                        SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Create New World key set and chose to let it be automatically set to f6. (In file: {2})", this.idx, standardOptionsFile))
                        break 2
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Instance {1} has no Create New World key set, macro will not work. (In file: {2})", this.idx, standardOptionsFile))
                    MsgBox, % Format("Instance {1} has no Create New World key set, macro will not work.`n(In file: {2})", this.idx, standardOptionsFile)
                    return
                } else if (InStr(standardOptions, "key_Create New World:")) {
                    if (this.resetKey := CheckOptionsForValue(standardOptionsFile, "key_Create New World", "F6")) {
                        SendLog(LOG_LEVEL_INFO, Format("Found reset key: {1} for instance {2} from {3}", this.resetKey, this.idx, standardOptionsFile))
                        break
                    } else {
                        SendLog(LOG_LEVEL_WARNING, Format("Failed to read reset key for instance {1}, trying to read from {2} instead of {3}", this.idx, optionsFile, standardOptionsFile))
                        if (this.resetKey := CheckOptionsForValue(optionsFile, "key_Create New World", "F6")) {
                            SendLog(LOG_LEVEL_INFO, Format("Found reset key: {1} for instance {2} from {3}", this.resetKey, this.idx, optionsFile))
                            break
                        }
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Failed to find reset key in instance {1}, macro will not work. (Checked files: {2} and {3})", this.idx, standardOptionsFile, optionsFile))
                    MsgBox, % Format("Failed to find reset key in instance {1}, macro will not work. (Checked files: {2} and {3})", this.idx, standardOptionsFile, optionsFile)
                    return
                } else if (InStr(options, "key_Create New World:key.keyboard.unknown")) {
                    MsgBox, % Format("Instance {1} missing required hotkey: Create New World. Please FIRST set it in your hotkeys and THEN press OK to continue", this.idx)
                    SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Create New World key set. User was informed. (In file: {2})", this.idx, optionsFile))
                    if (this.resetKey := CheckOptionsForValue(optionsFile, "key_Create New World", "F6")) {
                        SendLog(LOG_LEVEL_INFO, Format("Found reset key: {1} for instance {2} from {3}", this.resetKey, this.idx, optionsFile))
                        break
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Failed to find reset key in instance {1}, macro will not work. (In file: {2})", this.idx, optionsFile))
                    MsgBox, % Format("Failed to find reset key in instance {1}, macro will not work.`n(In file: {2})", this.idx, optionsFile)
                    return
                } else if (InStr(options, "key_Create New World:")) {
                    if (this.resetKey := CheckOptionsForValue(optionsFile, "key_Create New World", "F6")) {
                        SendLog(LOG_LEVEL_INFO, Format("Found reset key: {1} for instance {2} from {3}", this.resetKey, this.idx, optionsFile))
                        break
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Failed to find reset key in instance {1}, macro will not work. (In file: {2})", this.idx, optionsFile))
                    MsgBox, % Format("Failed to find reset key in instance {1}, macro will not work.`n(In file: {2})", this.idx, optionsFile)
                    return
                } else {
                    SendLog(LOG_LEVEL_ERROR, Format("No Create New World hotkey found for instance {1} even though mod is installed.", this.idx))
                    MsgBox, No Create New World hotkey found even though you have the mod. You likely have an outdated version. Please update to the latest version.
                    return
                }
                break
            }
            
            ; Verify Leave Preview key
            Loop, 1 {
                if (InStr(standardOptions, "key_Leave Preview:key.keyboard.unknown")) {
                    Loop, 1 {
                        MsgBox, 4, Leave Preview Key, % Format("Instance {1} has no Leave Preview hotkey set. Would you like to set this back to default (h)?`n(In file: {2})", this.idx, standardOptionsFile)
                        IfMsgBox No
                            break
                        standardOptions := StrReplace(standardOptions, "key_Leave Preview:key.keyboard.unknown", "key_Leave Preview:key.keyboard.h")
                        this.lpKey := "h"
                        SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Leave Preview key set and chose to let it be automatically set to h. (In file: {2})", this.idx, standardOptionsFile))
                        break 2
                    }
                    SendLog(LOG_LEVEL_WARNING, Format("Instance {1} has no Leave Preview key set. (In file: {2})", this.idx, standardOptionsFile))
                    MsgBox, % Format("Instance {1} has no Leave Preview key set.`n(In file: {2})", this.idx, standardOptionsFile)
                    
                } else if (InStr(standardOptions, "key_Leave Preview:")) {
                    if (this.lpKey := CheckOptionsForValue(standardOptionsFile, "key_Leave Preview", "h")) {
                        SendLog(LOG_LEVEL_INFO, Format("Found Leave Preview key: {1} for instance {2} from {3}", this.lpKey, this.idx, standardOptionsFile))
                        break
                    } else {
                        SendLog(LOG_LEVEL_WARNING, Format("Failed to read Leave Preview key for instance {1}, trying to read from {2} instead of {3}", this.idx, optionsFile, standardOptionsFile))
                        if (this.lpKey := CheckOptionsForValue(optionsFile, "key_Leave Preview", "h")) {
                            SendLog(LOG_LEVEL_INFO, Format("Found Leave Preview key: {1} for instance {2} from {3}", this.lpKey, this.idx, optionsFile))
                            break
                        }
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Failed to find Leave Preview key in instance {1}. (Checked files: {2} and {3})", this.idx, standardOptionsFile, optionsFile))
                    MsgBox, % Format("Failed to find Leave Preview key in instance {1}. (Checked files: {2} and {3})", this.idx, standardOptionsFile, optionsFile)
                    
                } else if (InStr(options, "key_Leave Preview:key.keyboard.unknown")) {
                    MsgBox, % Format("Instance {1} missing required hotkey: Leave Preview. Please FIRST set it in your hotkeys and THEN press OK to continue", this.idx)
                    SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Leave Preview key set. User was informed. (In file: {2})", this.idx, optionsFile))
                    if (this.lpKey := CheckOptionsForValue(optionsFile, "key_Leave Preview", "h")) {
                        SendLog(LOG_LEVEL_INFO, Format("Found Leave Preview key: {1} for instance {2} from {3}", this.lpKey, this.idx, optionsFile))
                        break
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Failed to find Leave Preview key in instance {1}. (In file: {2})", this.idx, optionsFile))
                    MsgBox, % Format("Failed to find Leave Preview key in instance {1}.`n(In file: {2})", this.idx, optionsFile)
                    
                } else if (InStr(options, "key_Leave Preview:")) {
                    if (this.lpKey := CheckOptionsForValue(optionsFile, "key_Leave Preview", "h")) {
                        SendLog(LOG_LEVEL_INFO, Format("Found Leave Preview key: {1} for instance {2} from {3}", this.lpKey, this.idx, optionsFile))
                        break
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Failed to find Leave Preview key in instance {1}. (In file: {2})", this.idx, optionsFile))
                    MsgBox, % Format("Failed to find Leave Preview key in instance {1}.`n(In file: {2})", this.idx, optionsFile)
                    
                } else {
                    SendLog(LOG_LEVEL_ERROR, Format("No Leave Preview hotkey found for instance {1} even though mod is installed.", this.idx))
                    MsgBox, No Leave Preview hotkey found even though you have the mod. Please update to the latest version to try and fix the issue.
                    
                }
                break
            }
            
            ; Verify fullscreen key for fullscreen users (this key verification is much less detailed and precise than create new world and leave preview keys because these keys are far more likely to be set properly and im lazy)
            Loop, 1 {
                if (InStr(standardOptions, "key_key.fullscreen:key.keyboard.unknown") && windowMode == "F") {
                    Loop, 1 {
                        MsgBox, 4, Fullscreen Key, % Format("Instance {1} missing required hotkey for fullscreen mode: Fullscreen. Would you like to set this back to default (f11)?`n(In file: {2})", this.idx, standardOptionsFile)
                        IfMsgBox No
                            break
                        standardOptions := StrReplace(standardOptions, "key_key.fullscreen:key.keyboard.unknown", "key_key.fullscreen:key.keyboard.f11")
                        this.fsKey := "F11"
                        SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no Fullscreen key set and chose to let it be automatically set to 'f11'. (In file: {2})", this.idx, standardOptionsFile))
                        break 2
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Instance {1} has no Fullscreen key set, macro will probably not work super well. (In file: {2})", this.idx, standardOptionsFile))
                } else {
                    this.fsKey := CheckOptionsForValue(standardOptionsFile, "key_key.fullscreen", "F11")
                    SendLog(LOG_LEVEL_INFO, Format("Found Fullscreen key: {1} for instance {2} from {3}", this.fsKey, this.idx, standardOptionsFile))
                    break
                }
            }
            
            ; Verify command key (same as fullscreen key)
            Loop, 1 {
                if (InStr(standardOptions, "key_key.command:key.keyboard.unknown")) {
                    Loop, 1 {
                        MsgBox, 4, Command Key, % Format("Instance {1} missing recommended command hotkey. Would you like to set this back to default (/)?`n(In file: {2})", this.idx, standardOptionsFile)
                        IfMsgBox No
                            break
                        standardOptions := StrReplace(standardOptions, "key_key.command:key.keyboard.unknown", "key_key.command:key.keyboard.slash")
                        this.commandKey := "/"
                        SendLog(LOG_LEVEL_WARNING, Format("Instance {1} had no command key set and chose to let it be automatically set to '/'. (In file: {2})", this.idx, standardOptionsFile))
                        break 2
                    }
                    SendLog(LOG_LEVEL_ERROR, Format("Instance {1} has no command key set, macro will be missing some functions. (In file: {2})", this.idx, standardOptionsFile))
                } else {
                    this.commandKey := CheckOptionsForValue(standardOptionsFile, "key_key.command", "/")
                    SendLog(LOG_LEVEL_INFO, Format("Found Command key: {1} for instance {2} from {3}", this.commandKey, this.idx, standardOptionsFile))
                    break
                }
            }
            
            ; Replace auto fixed standard options file to fix automatic corrections
            FileDelete, %standardOptionsFile%
            FileAppend, %standardOptions%, %standardOptionsFile%
        }
        
        if !fastReset
            SendLog(LOG_LEVEL_WARNING, Format("Directory {1} missing recommended mod fast-reset. Download: https://github.com/jan-leila/FastReset/releases", moddir))
        if !sleepBg
            SendLog(LOG_LEVEL_WARNING, Format("Directory {1} missing recommended mod sleepbackground. Download: https://github.com/RedLime/SleepBackground/releases", moddir))
        if !sodium
            SendLog(LOG_LEVEL_WARNING, Format("Directory {1} missing recommended mod sodium. Download: https://github.com/jan-leila/sodium-fabric/releases", moddir))
        if !srigt
            SendLog(LOG_LEVEL_WARNING, Format("Directory {1} missing recommended mod SpeedRunIGT. Download: https://redlime.github.io/SpeedRunIGT/", moddir))
        
        if (InStr(options, "fullscreen:true")) {
            ControlSend, ahk_parent, % Format("{Blind}{{1}}", this.fsKey), % Format("ahk_pid {1}", this.pid)
        }
        SendLog(LOG_LEVEL_INFO, Format("Finished instance verification for directory: {1}", mcDir))
    }
}