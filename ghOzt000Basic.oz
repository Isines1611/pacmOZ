functor

import
    OS
    System
export
    'getPort': SpawnAgent
define

    % Feel free to modify it as much as you want to build your own agents :) !

    % Helper => returns an integer between [0, N]
    fun {GetRandInt N} {OS.rand} mod N end
    
    % TODO: Complete this concurrent functional agent (PacmOz/GhOzt)
    fun {Agent State}
        fun {CanMove X Y Maze} % 0 = true / 1 = false
            if {Nth Maze (Y * 28 + X)+1} == 0 then
                0
            elseif {Nth Maze (Y * 28 + X)+1} == 2 then
                0
            else
                1
            end
        end

        fun {NextMove X Y Maze}
            RandDir = {GetRandInt 4}
        in
            if RandDir == 0 then % south
                if {CanMove X Y+1 Maze} == 0 then % Fine
                    'south'
                else % MUR
                    {NextMove X Y Maze}
                end
            elseif RandDir == 1 then % north
                if {CanMove X Y-1 Maze} == 0 then % Fine
                    'north'
                else
                    {NextMove X Y Maze}
                end
            elseif RandDir == 2 then % east
                if {CanMove X+1 Y Maze} == 0 then % Fine
                    'east'
                else
                    {NextMove X Y Maze}
                end
            else % west
                if {CanMove X-1 Y Maze} == 0 then % Fine
                    'west'
                else
                    {NextMove X Y Maze}
                end
            end
        end

        fun {MovedTo Msg}
            Dir
        in
            case Msg of movedTo(Id Type X Y) then
                if Id == State.id then
                    Dir = {NextMove X Y State.maze}
                    {Send State.gcport moveTo(State.id Dir)}
                end
            end

            {Agent State}
        end

    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'movedTo': MovedTo
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
        )}

        {System.show {Nth Maze (13 * 28 + 2)+1}}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
