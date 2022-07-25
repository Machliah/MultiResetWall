# MultiResetWall
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/specnr)

## Instructions

Watch the [NEW Multi Instance & Wall Setup Video](https://youtu.be/0xAHMW93MQw)

## Usage

To use the macro, run TheWall.ahk and wait for it to say ready. Start up OBS, then start up a [Fullscreen projector](https://youtu.be/9YqZ6Ogv3rk).

On the Fullscreen projector, you have a few default hotkeys (You may customize these hotkeys in the hotkeys.ahk file): 
- (1-9): Will reset the instance with the corresponding number
- Shift + (1-9): Will play the instance with the corresponding number
- E: Will reset the instance which your mouse is hovering over
- R: Will play the instance which your mouse is hovering over
- F: Will play the instance which your mouse is hovering over, and reset all of the other ones
- T: Will reset all instances
- Shift + Left Mouse button: Lock instance so "blanket reset" functions skip over it

Other optional hotkey functions include (to use, put the quoted text after a hotkey and double colon in the hotkeys.ahk file):
- "ResetAll(true)": Reset all instances regardless of locked status
- "FocusReset(MousePosToInstNumber(), true)": Play the instance which your mouse is hovering over and reset all the rest regardless of locked status
- "UnlockInstance(MousePosToInstNumber())": Unlock the instance which your mouse is hovering over
- "LockAll()": Lock all instances
- "UnlockAll()": Unlock all instances

Use [this world deletion program](https://gist.github.com/Specnr/8a572ac5c5cfdb54eb0dc7d1eb2906a3) to delete worlds.

## OBS Locked Instance Indicators

Adds the media/lock.png on screen whenever you lock an instance (does NOT require OBS Websocket)

1) Set lockIndicators in settings.ahk to True
2) Start the macro, then lock all instances
3) This should create an image in each .minecraft folder, add an Image source to OBS and put it above the correct instance for each instance

After that it should be working. Open a ticket in the [Discord](https://discord.gg/tXxwrYw) if you have any issues or need clarification.

## OBS Websocket

1) Download [Python 3.7+](https://www.python.org/downloads/)
2) Install [OBS websocket](https://obsproject.com/forum/resources/obs-websocket-remote-control-obs-studio-from-websockets.466/)
3) Open up command prompt, and run this command in `pip install obs-websocket-py`
4) Now, open up obsSettings.py in whatever text editor you want. 
5) For scene_name_format you want to put in whatever the prefix of all your scenes are. 
6) For wall_scene_name, its pretty self explanetory, just put in the scene name of your wall.
7) Now, for the password, you can put in a password if you want, and if you use it you can go to `Tools -> WebSockets Server Settings -> Enable Authentication` and then put in whatever password you want. Then you can put the same password in the password variable quotes.

After that it should be working. Open a ticket in the [Discord](https://discord.gg/tXxwrYw) if you have any issues or need clarification.

## Single Scene OBS

This removes scene switching to lighten the load on OBS. It lowers lag also allows for the "Tinder" background resetting method

Note: If you don't want you use Tinder, ignore anything related to it below.

1) Follow the OBS websocket tutorial above
2) You need 2 scenes: one which is just the wall, and the other which is our main scene. Whatever you call these, make sure it reflects in obsSettings.py
3) The wall scene will be the same as usual, but if using Tinder, put your Tinder sources behind the wall sources so they match titles on startup.
4) The main scene will have three levels: The wall level, the instances level, and the Tinder level. Put your sources in order from top to bottom with those priorities in mind. 
5) Make sure your Tinder sources follow the bg_mc_source_format outlined in obsSettings.py, and are independant from your regular instance sources

After that it should be working. Open a ticket in the [Discord](https://discord.gg/tXxwrYw) if you have any issues or need clarification.

## Credit

- Me
- Mach for efficient reset manager & code optimizations
- Ravalle for a lot of great ideas and code
- Boyenn for the better lock indication idea
- The collaborators listed for minor enhancements
- PodX12 for some minor enchancements
- Sam Dao (real)
- jojoe77777 for making the original wall macro
