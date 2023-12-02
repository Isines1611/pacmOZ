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
        % BRAIN FUNCTION 
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

        fun {GetRandDir X Y LastX LastY} % Aide de CheckPacgums
            L

            Xs = [X X X+1 X-1]
            Ys = [Y+1 Y-1 Y Y]
            Dir = ['south' 'north' 'east' 'west']

            fun {CheckDirection D} {Nth Xs D} \= LastX andthen {Nth Ys D} \= LastY andthen {CanMove {Nth Xs D} {Nth Ys D}} == 0 end
        in
            L = {List.filter [1 2 3 4] CheckDirection}
            {Nth Dir {Nth L {GetRandInt {Length L}} +1}}
        end

        fun {IsPacgums X Y} 
            Index = Y*28 + X
        in
            {HasFeature State.items Index} andthen State.items.Index.alive
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


        %%% MSG MANAGMENT
        fun {PacgumSpawned pacgumSpawned(X Y)}
            Index = Y*28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive': true) 'ngum': State.items.ngum + 1)}
        in
            {Agent {AdjoinAt State 'items' NewItems}}
        end

        fun {PacgumDispawned pacgumDispawned(X Y)}
            Index = Y*28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive':false) 'ngum': State.items.ngum-1)}
        in  
            {Agent {AdjoinAt State 'items' NewItems}}
        end
        
        
        fun {MovedTo movedTo(Id Type X Y)}
            NewDir  
            Cross
        in
            if State.id == Id then

                thread Cross = {IsCross X Y} end
                {Wait Cross}

                if Cross == 1 then
                    {Send State.gcport moveTo(State.id State.last)}
                else
                    thread NewDir = {CheckPacgums X Y} end
                    {Wait NewDir}
                    {Send State.gcport moveTo(State.id NewDir)}
                end

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
                'pacgumSpawned': PacgumSpawned
                'pacgumDispawned': PacgumDispawned
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
            'last': 'south'
            'items': items('ngum': 0)
        )}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
