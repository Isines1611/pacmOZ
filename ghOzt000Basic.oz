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
        % BRAIN FUNCTIONS / move choice
        fun {CanMove X Y} % 0 = true / 1 = false (accepte vide + pacgums, pas mur)
            Tile = {Nth State.maze (Y * 28 + X)+1}
        in
            if Tile == 1 then 1 
            else 0
            end
        end

        fun {IsCross X Y} % 0 = true (il y a cross) / 1 = false
            if State.last == 'south' orelse State.last == 'north' then
                if {CanMove X+1 Y} == 0 orelse {CanMove X-1 Y} == 0  then 0
                else  1
                end
            else % East / West
                if {CanMove X Y+1} == 0 orelse {CanMove X Y-1} == 0 then 0
                else 1
                end
            end
        end

        fun {GetOpposite Dir}
            if Dir == 'south' then 'north'
            elseif Dir == 'north' then 'south'
            elseif Dir == 'east' then 'west'
            else 'east'
            end
        end

        fun {GetNextDir X Y}
            DirValid

            Xs = [X X X+1 X-1]
            Ys = [Y+1 Y-1 Y Y]
            Dir = ['south' 'north' 'east' 'west']

            Opp = {GetOpposite State.last}

            fun {CheckMove D} Opp \= {Nth Dir D} andthen {CanMove {Nth Xs D} {Nth Ys D}} == 0 end 
        in
            DirValid = {List.filter [1 2 3 4] CheckMove}
            {Nth Dir {Nth DirValid {GetRandInt {Length DirValid}} +1}}
        end

        %%% MSG MANAGMENT
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
                    thread NewDir = {GetNextDir X Y} end
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
            Dispatch = {Label Msg} % Osef de pacgumSpawned, pacgumDispawned, pacpowSpawned, pacpowDispawned, pacpowDown
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
            'last': 'south'
        )}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
