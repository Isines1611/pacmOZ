functor

import
    OS
    System
export
    'getPort': SpawnAgent
define

    % Helper => returns an integer between [0, N]
    fun {GetRandInt N} {OS.rand} mod N end
    
    % TODO: Complete this concurrent functional agent (PacmOz/GhOzt)
    fun {Agent State}
        fun {MovedTo Msg}
            NewDir
            NewState
        in
            case Msg of movedTo(Id Type X Y) then
                if Id == State.id then
                    if {IsCross X Y} == 1 then % Si pas de croissement, continuer
                        NewState = State
                        {Send State.gcport moveTo(State.id State.last)}
                    else
                        NewDir = {CheckPacgums X Y}

                        NewState = {Adjoin State state(
                            'last': NewDir 
                        )}
                        
                        {System.show moving(NewDir)}
                        {Send State.gcport moveTo(State.id NewDir)}
                    end
                end
            end

            {Agent NewState}
        end

        fun {PacgumSpawned Msg}
            NewState
        in
            case Msg of pacgumSpawned(X Y) then
                NewState = {Adjoin State state(
                    'pacgums': pacgum(X Y) | State.pacgums
                    'len': State.len + 1
                )}
            else NewState = State
            end

            {Agent NewState}
        end

        fun {PacgumDispawned Msg}
            Pacgums = State.pacgums
            NewPacgums
            NewState
        in
            case Msg of pacgumDispawned(X Y) then
                {List.subtract Pacgums pacgum(X Y) NewPacgums}
                NewState = {Adjoin State state(
                    'pacgums': NewPacgums
                    'len': State.len - 1
                )}
            end

            {Agent NewState}
        end

        fun {IsCross X Y} % 0 = true (il y a cross) / 1 = false
            if State.last == 'south' then
                if {CanMove X+1 Y} == 0 then
                    0
                elseif {CanMove X-1 Y} == 0 then
                    0
                else 
                    1
                end
            elseif State.last == 'north' then
                if {CanMove X+1 Y} == 0 then
                    0
                elseif {CanMove X-1 Y} == 0 then
                    0
                else 
                    1
                end
            else % East / West
                if {CanMove X Y+1} == 0 then
                    0
                elseif {CanMove X Y-1} == 0 then
                    0
                else
                    1
                end
            end
        end

        fun {CanMove X Y} % 0 = true / 1 = false (accepte vide + pacgums, pas mur)
            if {Nth State.maze (Y * 28 + X)+1} == 0 then
                0
            elseif {Nth State.maze (Y * 28 + X)+1} == 2 then
                0
            else
                1
            end
        end

        fun {CheckPacgums X Y} % Return une dir valid
            if State.last == 'south' then % En venant du haut vers le bas
                if {IsPacgums X Y+1} then
                    'south'
                elseif {IsPacgums X+1 Y} then
                    'east'
                elseif {IsPacgums X-1 Y} then
                    'west'
                else
                    {GetRandDir X Y X Y-1}
                end
            elseif State.last == 'north' then % En venant du haut vers le bas
                if {IsPacgums X Y-1} then
                    'north'
                elseif {IsPacgums X+1 Y} then
                    'east'
                elseif {IsPacgums X-1 Y} then
                    'west'
                else
                    {GetRandDir X Y X Y+1}
                end
            elseif State.last == 'east' then % En venant de gauche a droit
                if {IsPacgums X+1 Y} then
                    'east'
                elseif {IsPacgums X Y-1} then
                    'north'
                elseif {IsPacgums X Y+1} then
                    'south'
                else
                    {GetRandDir X Y X-1 Y}
                end
            elseif State.last == 'west' then
                if {IsPacgums X-1 Y} then
                    'west'
                elseif {IsPacgums X Y-1} then
                    'north'
                elseif {IsPacgums X Y+1} then
                    'south'
                else
                    {GetRandDir X Y X+1 Y}
                end
            end
        end

        fun {IsPacgums X Y} {Member pacgum(X Y) State.pacgums} end

        fun {GetRandDir X Y LastX LastY} % Aide de CheckPacgums
            L = {NewCell nil}

            Xs = [X X X+1 X-1]
            Ys = [Y+1 Y-1 Y Y]
            Dir = ['south' 'north' 'east' 'west']
        in
            for D in 1..4 do
                if {Nth Xs D} == LastX andthen {Nth Ys D} == LastY then skip
                else
                    if {CanMove {Nth Xs D} {Nth Ys D}} == 0 then
                        L := {Nth Dir D}|@L
                    end
                end
            end

            {Nth @L {GetRandInt {Length @L}} +1}
        end

    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'movedTo': MovedTo
                'pacgumSpawned': PacgumSpawned
                'pacgumDispawned': PacgumDispawned
            )
        in
            {Interface.Dispatch Msg}
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        if Msg \= shutdown() then {Handler Upcoming {Instance Msg}} end
    end

    fun {SpawnAgent init(Id GCPort Maze)}
        Stream
        Port = {NewPort Stream}

        Instance = {Agent state(
            'id': Id
            'maze': Maze
            'gcport': GCPort
            'pacgums': nil
            'len': 0
            'last': 'south'
        )}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
