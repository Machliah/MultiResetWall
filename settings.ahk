; General settings
global rows := 3 ; Number of row on the wall scene, or focus grid if instance moving
global cols := 3 ; Number of columns on the wall scene, or focus grid if instance moving
global mode := "W" ; W = Normal wall, I = Instance Moving (Requires additional setup), B = Wall bypass (skip to next locked), M = Modern multi (send to wall when none loaded), C = Classic original multi (always force to next instance)
global windowMode := "W" ; W = windowed mode, F = fullscreen mode, B = borderless windowed

; Extra features
global widthMultiplier := 2.5 ; How wide your instances go to maximize visibility :) (set to 0 for no width change)
global coop := False ; Automatically opens to LAN when you load in a world
global sounds := "A" ; A = all, F = everything but tts, R = only resets, T = only tts, L = only locks, N = no sounds
global audioGui := False ; A simple GUI so the OBS application audio plugin can capture sounds
global autoIdleFreezing := False ; Automatically suspend and freeze background instances while playing an instance, good for long categories (configure delay in delays section)
global smartSwitch := False ; Find an instance to switch to if current one is unloaded
global theme := "default" ; the name of the folder you wish to use as your macro theme in the global themes folder
global readyTTS := "Ready" ; What the text-to-speach says to you when the macro is ready

; Delays (Defaults are probably fine)
global spawnProtection := 300 ; Prevent a new instance from being reset for this many milliseconds after the preview is visible
global fullscreenDelay := 50 ; Increase if fullscreening issues
global freezeWaitTime := 300000 ; How long before background instances are automatically suspended, enable with autoIdleFreezing

; Super advanced settings (Read about these settings on the README before changing)

; Instance Moving
global focusGridWidthPercent := 0.8 ; Horizontal % of the focus grid. Setting this to 1 hides the passive instances.
global focusGridHeightPercent := 0.8 ; Vertical % of the focus grid. Setting this to 1 hides the locked instances.
global maxLockedRows := 2 ; Specifies how many rows have to be reached in the locked section to start a new column.
global pixelsBetweenInstances := 0 ; The number of pixels to be between instances (for visual effect)
global bypassThreshold := -1 ; The maximum number of fully loaded instances where PlayNextLock(true) will not play next lock (-1 = always play next lock)

; Affinity
; -1 == use macro math to determine thread counts
global affinityType := "A" ; N = no affinity management, B = basic affinity management, A = advanced affinity mangement (best if used with locking+resetAll)
global playThreadsOverride := -1 ; Thread count for instance you are playing
global lockThreadsOverride := -1 ; Thread count for locked instances loading on wall
global highThreadsOverride := -1 ; Thread count for instances still resetting while on wall
global midThreadsOverride := -1 ; Thread count for instances loading a preview (burstLength) after detecting it
global lowThreadsOverride := -1 ; Thread count for all fully loaded instances
global bgLoadThreadsOverride := -1 ; Thread count for loading or locked instances in bg
global burstLength := 600 ; The delay before switching from high to mid while on wall or from bgLoad to low while in bg

; OBS
global obsControl := "C" ; C = Controller, N = Numpad keys (<10 inst), F = Function keys (f13-f24), ARR = advanced array (see customKeyArray)
global obsWallSceneKey := "" ; Wall hotkey used for all obsControl types except Controller
global obsCustomKeyArray := [] ; Must be used with advanced array control type. Add keys in quotes separated by commas. The index in the array corresponds to the scene
global obsResetMediaKey := "" ; Key pressed on any instance reset with sound (used for playing reset media file in obs for recordable/streamable resets and requires addition setup to work)
global obsLockMediaKey := "" ; Key pressed on any lock instance with sound (used for playing lock media file in obs for recordable/streamable lock sounds and requires addition setup to work)
global obsUnlockMediaKey := "" ; Key pressed on any unlock instance with sound (used for playing unlock media file in obs for recordable/streamable unlock sounds and requires addition setup to work)
global obsDelay := 50 ; delay between hotkey press and release, increase if not changing scenes in obs and using a hotkey form of control

; Special on join settings
; Optional alternate settings to use when joining an instance. Set this function as a hotkey with 'SwitchInstance(MousePosToInstNumber(), True)'
global renderDistance := 18
global entityDistance := 500
global fov := 110
global toggleChunkBorders := True
global toggleHitBoxes := False

; Attempts
global overallAttemptsFile := "data/ATTEMPTS.txt" ; File to write overall attempt count to
global dailyAttemptsFile := "data/ATTEMPTS_DAY.txt" ; File to write daily attempt count to