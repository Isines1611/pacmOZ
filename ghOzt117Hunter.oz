functor

export
    'getPort': SpawnAgent
define

    fun {Agent State}
        % BRAIN FUNCTIONS / move choice
        fun {CanMove X Y} % 0 = true / 1 = false (accepte vide + pacgums, pas mur)
            Tile = {Nth State.maze (Y * 28 + X)+1}
        in
            if Tile == 1 then 1 
            else 0
            end
        end

        fun {GetDir X Y}
            if {CanMove X+1 Y} == 0 then 'east'
            elseif {CanMove X-1 Y} == 0 then 'west'
            elseif {CanMove X Y+1} == 0 then 'south'
            else 'north' end
        end

        %%% HUNT
        fun {Abs N} if N < 0 then ~1*N else N end end

        fun {HuntDirection X Y TX TY Bonus}
            DX = TX - X
            DY = TY - Y

            NewX
            NewY
        in
            if Bonus then ODX ODY in
                ODX = DX * ~1
                ODY = DY * ~1


                if ODX \= 0 then % Match X
                    NewX = X + (ODX div {Abs ODX})
    
                    if {CanMove NewX Y} == 0 then
                        if ODX > 0 then 'east'
                        else 'west'
                        end
                    elseif ODY \= 0 then
                        NewY = Y + (ODY div {Abs ODY})
    
                        if {CanMove X NewY} == 0 then
                            if ODY > 0 then 'south'
                            else 'north'
                            end
                        else 'stay'
                        end
                    else 'stay'
                    end
                elseif ODY \= 0 then % Match Y
                    NewY = Y + (ODY div {Abs ODY})
    
                    if {CanMove X NewY} == 0 then
                        if ODY > 0 then 'south'
                        else 'north'
                        end
                    elseif ODX \= 0 then
                        NewX = X + (ODX div {Abs ODX})
    
                        if {CanMove NewX Y} == 0 then
                            if ODX > 0 then 'east'
                            else 'west'
                            end
                        else 'stay'
                        end
                    else 'stay'
                    end
                end
            else

                if DX \= 0 then % Match X
                    NewX = X + (DX div {Abs DX})

                    if {CanMove NewX Y} == 0 then
                        if DX > 0 then 'east'
                        else 'west'
                        end
                    elseif DY \= 0 then
                        NewY = Y + (DY div {Abs DY})

                        if {CanMove X NewY} == 0 then
                            if DY > 0 then 'south'
                            else 'north'
                            end
                        else 'stay'
                        end
                    else 'stay'
                    end
                elseif DY \= 0 then % Match Y
                    NewY = Y + (DY div {Abs DY})

                    if {CanMove X NewY} == 0 then
                        if DY > 0 then 'south'
                        else 'north'
                        end
                    elseif DX \= 0 then
                        NewX = X + (DX div {Abs DX})

                        if {CanMove NewX Y} == 0 then
                            if DX > 0 then 'east'
                            else 'west'
                            end
                        else 'stay'
                        end
                    else 'stay'
                    end
                else 'stay'
                end
            end
        end

        %%% MSG MANAGMENT
        fun {MovedTo movedTo(Id Type X Y)}
            NewDir
            NewState
        in
            if Type == 'pacmoz' then
        
                NewState = {Adjoin State state(
                    'pacmoz': pos(x:X y:Y)
                )}
                {Agent NewState}

            elseif State.id == Id then
                NewDir = {HuntDirection X Y State.pacmoz.x State.pacmoz.y State.pacpowActive}

                if NewDir == 'stay' then 
                    {Send State.gcport moveTo(State.id {GetDir X Y})} 
                    {Agent State}
                else
                    {Send State.gcport moveTo(State.id NewDir)}
                    {Agent State}
                end

            else {Agent State}
            end
        end

        fun {PacpowDispawned pacpowDispawned(X Y)}
            NewState
        in
            NewState = {Adjoin State state(
                'pacpowActive': true
            )}
            
            {Agent NewState}
        end

        fun {PacpowDown pacpowDown()}
            NewState
        in
            NewState = {Adjoin State state(
                'pacpowActive': false
            )}

            {Agent NewState}
        end
    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'movedTo': MovedTo
                'pacpowDown': PacpowDown
                'pacpowDispawned': PacpowDispawned
            )
        in
            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                %{System.show log('Unhandle message' Dispatch)}
                {Agent State}
            end
        end
    end

    proc {Handler Msg | Upcoming Instance}
        %{System.show gHandler(Msg|Upcoming)}
        {Handler Upcoming {Instance Msg}}
    end

    fun {SpawnAgent init(Id GCPort Maze)}
        Stream
        Port = {NewPort Stream}

        Instance = {Agent state(
            'id': Id
            'maze': Maze
            'gcport': GCPort
            'pacmoz': pos(x:1 y:1)
            'pacpowActive': false
        )}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
