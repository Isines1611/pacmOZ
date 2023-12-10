functor

import
    OS
    System
export
    'getPort': SpawnAgent
define

    % Helper => returns an integer between [0, N]
    fun {GetRandInt N} {OS.rand} mod N end
    
    fun {Agent State}
        % BRAIN FUNCTION / Move choice
        fun {CanMove X Y} % 0 = true / 1 = false (accepte vide + pacgums, pas mur)
            Tile = {Nth State.maze (Y * 28 + X)+1}  
        in
            if Tile == 1 then 1
            else 0
            end
        end
        
        fun {IsCross X Y} % 0 = true (il y a cross) / 1 = false
            if State.last == 'south' orelse State.last == 'north' then
                if {CanMove X+1 Y} == 0 orelse {CanMove X-1 Y} == 0 then 0
                else 1
                end
            else % East / West
                if {CanMove X Y+1} == 0 orelse {CanMove X Y-1} == 0 then 0
                else 1
                end
            end
        end

        fun {IsPacgums X Y} 
            Index = Y*28 + X
        in
            {HasFeature State.items Index} andthen State.items.Index.alive
        end

        fun {GetOpposite Dir}
            if Dir == 'south' then 'north'
            elseif Dir == 'north' then 'south'
            elseif Dir == 'east' then 'west'
            else 'east'
            end
        end

        fun {CheckCrossPacgum X Y} % return valid dir
            DirValid
            DirPacgum

            Xs = [X X X+1 X-1]
            Ys = [Y+1 Y-1 Y Y]
            Dir = ['south' 'north' 'east' 'west']
            
            Opp = {GetOpposite State.last}

            fun {CheckMove D} Opp \= {Nth Dir D} andthen {CanMove {Nth Xs D} {Nth Ys D}} == 0 end
            fun {CheckPacgum D} Opp \= {Nth Dir D} andthen {IsPacgums {Nth Xs D} {Nth Ys D}} end
        in
            DirValid = {List.filter [1 2 3 4] CheckMove}
            DirPacgum = {List.filter [1 2 3 4] CheckPacgum}

            if {Length DirPacgum} =< 0 then % Vide
                {Nth Dir {Nth DirValid {GetRandInt {Length DirValid}} +1}}
            else % Pacgum
                {Nth Dir {Nth DirPacgum {GetRandInt {Length DirPacgum}} +1}}
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
            NewState
        in
            if State.id == Id then

                thread Cross = {IsCross X Y} end
                {Wait Cross}

                if Cross == 1 then
                    {Send State.gcport moveTo(State.id State.last)} {Agent State}
                else
                    thread NewDir = {CheckCrossPacgum X Y} end
                    {Wait NewDir}
                    {Send State.gcport moveTo(State.id NewDir)}

                    NewState = {Adjoin State state(
                        'last': NewDir
                    )}

                    {Agent NewState}
                end
            else {Agent State}
            end
        end
    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg} % Osef de pacpowSpawned, pacpowDispawned, pacpowDown
            Interface = interface(
                'movedTo': MovedTo
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
