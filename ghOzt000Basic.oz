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
        fun {ChooseRandDir} 
            Dir = ['south' 'north' 'east' 'west']
            R
        in
            R = {GetRandInt 2}+1 
            {Nth Dir R}
        end

        fun {CanMove X Y} % 0 = true / 1 = false (accepte vide + pacgums, pas mur)
            Tile = {Nth State.maze (Y * 28 + X)+1}
        in
            if Tile == 1 then 1 
            else 0
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
            else {System.show went(State.last)}
            end
        end

        fun {GetRandDir X Y LastX LastY} % Aide de NextMove
            L 
            
            Xs = [X X X+1 X-1]
            Ys = [Y+1 Y-1 Y Y]
            Dir = ['south' 'north' 'east' 'west']

            fun {CheckDirection D}
                {Nth Xs D} \= LastX andthen {Nth Ys D} \= LastY andthen {CanMove {Nth Xs D} {Nth Ys D}} == 0
            end
        in
            L = {List.filter [1 2 3 4] CheckDirection}

            {Nth Dir {Nth L {GetRandInt {Length L}} +1}}
        end

        fun {MovedTo movedTo(Id Type X Y)}
            NewDir
            NewState
            Cross
        in
            if State.id == Id then

                thread Cross = {IsCross X Y} end
                {Wait Cross}

                if Cross == 1 then
                    {Send State.gcport moveTo(State.id State.last)}
                else
                    thread NewDir = {NextMove X Y} end
                    {Wait NewDir} 
                    {Send State.gcport moveTo(State.id NewDir)}
                end

                

            /*if Id == State.id then
                thread Cross = {IsCross X Y} end
                {Wait Cross}

                if Cross == 1 then
                    NewState = State
                    {Send State.gcport moveTo(State.id State.last)}
                else
                    thread NewDir = {ChooseRandDir} end
                    {Wait NewDir}

                    NewState = {Adjoin State state(
                        'last': NewDir 
                    )}
                    
                    {Send State.gcport moveTo(State.id NewDir)}
                end
            end */
            end
            {Agent State}
        end

        fun {MoveTo moveTo(Id Dir)}
            NewState
        in
            if State.id == Id andthen State.last \= Dir then
                NewState = {Adjoin State state(
                    'last': Dir 
                )}
                {Agent NewState}
            else
                {Agent State}
            end
        end

    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'movedTo': MovedTo
                'moveTo': MoveTo
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
        {System.show gHandler(Msg|Upcoming)}
        {Handler Upcoming {Instance Msg}}
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
