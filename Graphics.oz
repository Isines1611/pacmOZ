functor

import
    OS
    % System
    Application
    QTk at 'x-oz://system/wp/QTk.ozf'
export
    'spawn': SpawnGraphics
define
    CD = {OS.getCWD}
    FONT = {QTk.newFont font('size': 18)}
    WALL_TILE = {QTk.newImage photo(file: CD # '/ress/wall.png')}
    GROUND_TILE = {QTk.newImage photo(file: CD # '/ress/ground.png')}
    PACMOZ_SPRITE = {QTk.newImage photo(file: CD # '/ress/pacmoz.png')}
    PACGUM_SPRITE = {QTk.newImage photo(file: CD # '/ress/pacgum.png')}
    PACPOW_SPRITE = {QTk.newImage photo(file: CD # '/ress/pacpow.png')}

    GHOST_UP_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_up.png')}
    GHOST_DOWN_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_down.png')}
    GHOST_RIGHT_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_right.png')}
    GHOST_LEFT_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_left.png')}

    SCARED_UP_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_up.png')}
    SCARED_DOWN_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_down.png')}
    SCARED_RIGHT_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_right.png')}
    SCARED_LEFT_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_left.png')}
    
    class GameObject
        attr 'id' 'type' 'sprite' 'x' 'y'

        meth init(Id Type Sprite X Y)
            'id' := Id
            'type' := Type
            'sprite' := Sprite
            'x' := X
            'y' := Y
        end

        meth getType($) @type end

        meth render(Buffer)
            {Buffer copy(@sprite 'to': o(@x @y))}
        end

        meth update(GCPort) skip end
    end

    class Bot from GameObject
        attr 'isMoving' 'moveDir' 'targetX' 'targetY'

        meth init(Id Type Sprite X Y)
            GameObject, init(Id Type Sprite X Y)
            'isMoving' := false
            'targetX' := X
            'targetY' := Y
        end

        meth setTarget(Dir)
            'isMoving' := true
            'moveDir' := Dir
            if Dir == 'north' then
                'targetY' := @y - 32
            elseif Dir == 'south' then
                'targetY' := @y + 32
            elseif Dir == 'east' then
                'targetX' := @x + 32
            elseif Dir == 'west' then
                'targetX' := @x - 32
            end
        end

        meth move(GCPort)
            if @moveDir == 'north' then
                'y' := @y - 4
            elseif @moveDir == 'south' then
                'y' := @y + 4
            elseif @moveDir == 'east' then
                'x' := @x + 4
            elseif @moveDir == 'west' then
                'x' := @x - 4
            end

            if @x == @targetX andthen @y == @targetY then
                NewX = @x div 32
                NewY = @y div 32
            in
                'isMoving' := false
                {Send GCPort movedTo(@id @type NewX NewY)}
            end
        end

        meth update(GCPort)
            if @isMoving then
                {self move(GCPort)}
            end
        end
    end

    class Ghost from Bot
        attr 'scared'

        meth init(Id X Y)
            Bot, init(Id 'ghost' GHOST_DOWN_SPRITE X Y)
            'scared' := false
        end

        meth setScared(Value)
            if Value then
                if @moveDir == 'north' then
                    'sprite' := SCARED_UP_SPRITE
                elseif @moveDir == 'south' then
                    'sprite' := SCARED_DOWN_SPRITE
                elseif @moveDir == 'east' then
                    'sprite' := SCARED_RIGHT_SPRITE
                elseif @moveDir == 'west' then
                    'sprite' := SCARED_RIGHT_SPRITE
                end
            else
                if @moveDir == 'north' then
                    'sprite' := GHOST_UP_SPRITE
                elseif @moveDir == 'south' then
                    'sprite' := GHOST_DOWN_SPRITE
                elseif @moveDir == 'east' then
                    'sprite' := GHOST_RIGHT_SPRITE
                elseif @moveDir == 'west' then
                    'sprite' := GHOST_RIGHT_SPRITE
                end
            end
            'scared' := Value
        end

        meth setTarget(Dir)
            'isMoving' := true
            'moveDir' := Dir
            if Dir == 'north' then
                'sprite' := if @scared then SCARED_UP_SPRITE  else GHOST_UP_SPRITE end
                'targetY' := @y - 32
            elseif Dir == 'south' then
                'sprite' := if @scared then SCARED_DOWN_SPRITE  else GHOST_DOWN_SPRITE end
                'targetY' := @y + 32
            elseif Dir == 'east' then
                'sprite' := if @scared then SCARED_RIGHT_SPRITE else GHOST_RIGHT_SPRITE end
                'targetX' := @x + 32
            elseif Dir == 'west' then
                'sprite' := if @scared then SCARED_LEFT_SPRITE else GHOST_LEFT_SPRITE end
                'targetX' := @x - 32
            end
        end
    end

    class Pacmoz from Bot
        meth init(Id X Y)
            Bot, init(Id 'pacmoz' PACMOZ_SPRITE X Y)
        end
    end

    class Graphics
        attr
            'buffer' 'buffered' 'canvas' 'window'
            'score' 'scoreHandle'
            'ids' 'gameObjects'
            'background'
            'running'
            'gcPort'
        
        meth init(GCPort)
            Height = 928
            Width = 896
        in
            'running' := true
            'gcPort' := GCPort

            'buffer' := {QTk.newImage photo('width': Width 'height': Height)}
            'buffered' := {QTk.newImage photo('width': Width 'height': Height)}

            'window' := {QTk.build td(
                canvas(
                    'handle': @canvas
                    'width': Width
                    'height': Height
                    'background': 'black'
                )
                button(
                    'text': "close"
                    'action' : proc {$} {Application.exit 0} end
                )
            )}

            'score' := 0
            {@canvas create('image' Width div 2 Height div 2 'image': @buffer)}
            {@canvas create('text' 128 16 'text': 'score: 0' 'fill': 'white' 'font': FONT 'handle': @scoreHandle)}
            'background' := {QTk.newImage photo('width': Width 'height': Height)}
            {@window 'show'}

            'gameObjects' := {Dictionary.new}
            'ids' := 0
        end

        meth isRunning($) @running end

        meth genId($)
            'ids' := @ids + 1
            @ids
        end

        meth spawnPacgum(X Y)
            {@background copy(PACGUM_SPRITE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacgumSpawned(X Y)}
        end

        meth dispawnPacgum(X Y)
            {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacgumDispawned(X Y)}
        end

        meth spawnPacpow(X Y)
            {@background copy(PACPOW_SPRITE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacpowSpawned(X Y)}
        end

        meth setAllScared(Value)
            GameObjects = {Dictionary.items @gameObjects}
        in
            for Gobj in GameObjects do
                if {Gobj getType($)} == 'ghost' then
                    {Gobj setScared(Value)}
                end
            end
        end

        meth dispawnPacpow(X Y)
            {self setAllScared(true)}
            thread
                {Delay 3000}
                {Send @gcPort pacpowDown()}
                {Delay 7000}
                {self spawnPacpow(X Y)}
            end
            {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacpowDispawned(X Y)}
        end

        meth buildMaze(Maze)
            Z = {NewCell 0}
        in
            for K in Maze do
                X = @Z mod 28
                Y = @Z div 28
            in
                if K == 0 then
                    {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
                    {self spawnPacgum(X Y)}
                elseif K == 1 then
                    {@background copy(WALL_TILE 'to': o(X * 32 Y * 32))}
                elseif K == 2 then
                    {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
                    {self spawnPacpow(X Y)}
                end
                Z := @Z + 1
            end
        end

        meth spawnBot(Type X Y $)
            Bot
            Id = {self genId($)}
        in
            if Type == 'pacmoz' then
                Bot = {New Pacmoz init(Id X * 32 Y * 32)}
            else
                Bot = {New Ghost init(Id X * 32 Y * 32)}
            end

            {Dictionary.put @gameObjects Id Bot}
            {Send @gcPort movedTo(Id Type X Y)}
            Id
        end

        meth dispawnBot(Id)
            {Dictionary.remove @gameObjects Id}
        end

        meth moveBot(Id Dir)
            Bot = {Dictionary.condGet @gameObjects Id 'null'}
        in
            if Bot \= 'null' then
                {Bot setTarget(Dir)}
            end
        end

        meth updateScore(Score)
            'score' := Score
            {@scoreHandle set('text': "score: " # @score)}
        end

        meth update()
            GameObjects = {Dictionary.items @gameObjects}
        in
            {@buffered copy(@background 'to': o(0 0))}
            for Gobj in GameObjects do
                {Gobj update(@gcPort)}
                {Gobj render(@buffered)}
            end
            {@buffer copy(@buffered 'to': o(0 0))}
        end
    end

    fun {NewActiveObject Class Init}
        Stream
        Port = {NewPort Stream}
        Instance = {New Class Init}
    in
        thread
            for Msg in Stream do {Instance Msg} end
        end

        proc {$ Msg} {Send Port Msg} end
    end

    fun {SpawnGraphics Port FpsMax}
        Active = {NewActiveObject Graphics init(Port)}
        FrameTime = 1000 div FpsMax
        
        proc {Ticker}
            if {Active isRunning($)} then
                {Active update()}
                {Delay FrameTime}
                {Ticker}
            end
        end
    in
        thread {Ticker} end
        Active
    end
end
