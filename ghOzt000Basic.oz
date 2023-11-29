functor

import
    OS
    System
export
    'getPort': SpawnAgent
define

    % Helper => returns an integer between [0, N[
    fun {GetRandInt N} {OS.rand} mod N end
    
    fun {Agent State}
        fun {CanMove X Y} % 0 = true / 1 = false (accepte vide + pacgums, pas mur)
            if {Nth State.maze (Y * 28 + X)+1} == 0 then
                0
            elseif {Nth State.maze (Y * 28 + X)+1} == 2 then
                0
            else
                1
            end
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

        fun {NextMove X Y}
            if State.last == 'south' then % En venant du haut vers le bas
                if {CanMove X Y+1} == 0 then
                    'south'
                else
                    {GetRandDir X Y X Y-1}
                end
            elseif State.last == 'north' then % En venant du haut vers le bas
                if {CanMove X Y-1} == 0 then
                    'north'
                else
                    {GetRandDir X Y X Y+1}
                end
            elseif State.last == 'east' then % En venant de gauche a droit
                if {CanMove X+1 Y} == 0 then
                    'east'
                else
                    {GetRandDir X Y X-1 Y}
                end
            elseif State.last == 'west' then
                if {CanMove X-1 Y} == 0 then
                    'west'
                else
                    {GetRandDir X Y X+1 Y}
                end
            end
        end

        fun {GetRandDir X Y LastX LastY} % Aide de NextMove
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

        fun {MovedTo movedTo(Id Type X Y)}
            NewDir
            NewState
        in
            if Id == State.id then
                if {IsCross X Y} == 1 then
                    NewState = State
                    {Send State.gcport moveTo(State.id State.last)}
                    {System.show gMoving(State.last)}
                else
                    NewDir = {NextMove X Y}

                    NewState = {Adjoin State state(
                        'last': NewDir 
                    )}
                    
                    {System.show gMoving(NewDir)}
                    {Send State.gcport moveTo(State.id NewDir)}
                end
            end

            {Agent NewState}
        end

    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            {System.show ghost(Msg)}
            Dispatch = {Label Msg}
            Interface = interface(
                'movedTo': MovedTo
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
        if Msg \= shutdown() then {Handler Upcoming {Instance Msg}} end
    end

    fun {SpawnAgent init(Id GCPort Maze)}
        Stream
        Port = {NewPort Stream}

        Instance = {Agent state(
            'id': Id
            'maze': Maze
            'gcport': GCPort
            'last': 'south'
        )}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
