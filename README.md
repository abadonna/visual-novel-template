# Visual Novel project template for Defold

This project template is based on [Ink scripting language](https://www.inklestudios.com/ink/) and lua runtime [defold-ink](https://github.com/abadonna/defold-ink). The purpose of this template was to simplify use of [DefSceneManager](https://github.com/abadonna/DefSceneManager), which I believe has too much legacy stuff now.

## Structure
**manager.script** is the main script to control the flow

**controller.script** performs actions on game objects inside collection

**bridge.lua** connects ink tags with Defold entities, each tag is a specific command defined in this script

**story.gui** UI from DefSceneManager to display text and choice buttons, gui file should be modified to suit your game art stule.

**hud.gui** main gui for the game, expand with any aditional ui elements you need. Also used for fadein\fadeout effects.

**demo.gui** just a sample of using custom UI controls as choice buttons

**frames.script** script for animated scenes, see intro.collection

## Ink-to-Defold actions
The project contains number of predefined actions (ink tags), but you can add your own by modifying bridge.lua
It's convinient to create single tag to perform mutiple actions (e.g. move and show object and when wait for duration of time)

* SCENE name [fadein\fadeout\fadeinout] [keep] - loads defold collection
* SHOW obj,[obj2,..] [duration] - shows game object in loaded collection
* HIDE obj,[obj2,..] [duration] - hides game object in loaded collection
* MOVE obj,[obj2,..] x [y] - moves game object to x,y
* Z obj,[obj2,..] z - moves game object to z
* FADE_IN
* FADE_OUT
* DELETE obj,[obj2,..]
* DELAY time
* NOTEXT - hides text and waits for user click
* ZOOM_IN obj,[obj2,..] - slightly scales object, e.g. for scaling backgrounds in dialog mode
* ZOOM_OUT
* SHOW_CHAR_RIGHT obj - shows and moves object from right, e.g. as new character appears
* SHOW_CHAR_LEFT - shows and moves object from left, e.g. as new character appears
* HIDE_CHAR - hides and move object (moved by SHOW_CHAR_RIGHT\SHOW_CHAR_LEFT) back
* LOAD_IMAGE obj fname.ext - loads image "fname.ext" from resources and assigns to texture of obj 
* LOAD_ANIM obj fname count - loads images for animation frames, fname should be name of files fname1.jpg ... fnamecount.jpg 
* PLAY obj - plays animation on object
* STOP obj - stops animation
* MSG reciever message
* SOUND sfx - plays sound in /sound#sfx component
* MUTE sfx - mutes sound

There is also a sample of character direct speech template.


## Runtime image loading
The template has 2 formats for textures. If texture has no alpha channel it should be added in atlas with suffix "\_bg" so it will be compressed in RGB format. Other atlases will be RGBA.

But! If VN contains hundrends of hi-res images it becomes too big in size (not convinient for HTML5 builds) and requires long time to build (to compress textures). 

So there is an alternative way - put already compressed image files in /assets folder (subfolders) and load these images in runtime with the help of [imageloader](https://github.com/Lerg/extension-imageloader) native extension. 

See LOAD_IMAGE\LOAD_ANIM actions as example. Special atlases for setting textures is placed in /textures/runtime folder and sprites should have the right size in Manual Size Mode.


## Save\Load state
Save\load in this project implemented as binding of external functions to ink script. Functions are executed during processing ink script, so it will be called before processing any tags. Alternatively it can be done as tag actions, but we need to check if the script in restore mode or not in this case. External functions are disabled while restoring ink state in the story by default.


## Custom buttons
Sometimes we don't want text button, but something more advanced (e.g. special markers or hotspots). In this case we need to register text patterns for those actions and manager won't create buttons and just will pass message to controller object in current collection. See demo.gui

---

Happy Defolding!