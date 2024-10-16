//  https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md

#SCENE menu

-(menu)

+ [New game #WIDTH 300] ->start    
+ [Load game #WIDTH 300]
    #FADE_OUT
    #LOAD 1
    No saved data. #FADE_IN
    ->menu
    
//-----------------------------------------------------

=== start
#SCENE intro
#HIDE woman,tv,man

Once upon a time...

-(demo)
+ [::touch::]
    #ZOOM_IN room
    #CHR_SHOW_LEFT man
    Hans: Don't touch my wife, punk!
    #ZOOM_OUT room
    #HIDE_CHAR man
    ->demo
    
+ [Talk to her]
    #ZOOM_IN room
    #HIDE crawl .5
    #CHR_SHOW_RIGHT woman
    Marin: Start to make your own game already!
    #ZOOM_OUT room
    #HIDE_CHAR woman
    #SHOW crawl .5
    ->demo
    
* [Change TV channel] #X 850 #Y 720
    #LOAD_IMAGE tv sample.png
    #SHOW tv .5
    ->demo
    
+ [Animation test]
    #LOAD_ANIM test anim 10
    #PLAY test
    #Z test 0.5
    Frames are loaded in runtime. It's not practical to keep fullhd frames in atlas - in terms of size and build time.
    #NOTEXT
    #STOP test
    #Z test -100
    ->demo
    
+ [Start to make you own game]
+ [Save progress]
    
     Game saved. #SAVE 1
     ->demo

- Finally!

    -> END


