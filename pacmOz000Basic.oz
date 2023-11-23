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
    
    % Agent object with data
    fun {Agent}
        ID = {NewCell 0}
        MAZE = {NewCell 0}
        PORT = {NewCell 0}

        X = {NewCell 0}
        Y = {NewCell 0}

        proc {SetID N} ID := N end
        fun {GetID} @ID end
        proc {SetMAZE N} MAZE := N end
        fun {GetMAZE} @MAZE end
        proc {SetPORT N} PORT := N end
        fun {GetPORT} @PORT end

        proc {SetX N} X := N end
        fun {GetX} @X end
        proc {SetY N} Y := N end
        fun {GetY} @Y end
    in
        ag(setID:SetID setMAZE:SetMAZE setPORT:SetPORT getID:GetID getMAZE:GetMAZE getPORT:GetPORT setX:SetX setY:SetY getX:GetX getY:GetY)
    end

    % All usefull functions/proc
    proc {Sum X Y}
        Res = X+Y
    in
        {System.show log('Sum result = ' Res)}
    end

    proc {InfSouth Instance}
        {Send {Instance.getPORT} moveTo({Instance.getID} 'south')}
        {Delay 2000}
        {InfSouth Instance}
    end

    proc {BotMoved ID Instance X Y}
        if {Instance.getID} == ID then 
            {Instance.setX X}
            {Instance.setY Y}
            
            {System.show maze(X Y '->' Y*29+X)}
            {System.show {Nth {Instance.getMAZE} Y * 29 + X}}
        end
    end

    % Handler
    proc {Handler Msg | Upcoming Instance}
        case Msg of shutdown() then
            {System.show 'Message Shutdown'}
        [] sum(X Y) then
            {Sum X Y}

        [] movedTo(ID Type X Y) then
            {System.show 'new movedTo'}
            thread {BotMoved ID Instance X Y} end

        [] rand(X) then
            {System.show {GetRandInt X}}

        [] inf then 
            thread {InfSouth Instance} end

        [] increaseScore then 
            {Send {Instance.getPORT} increaseScore}

        [] test then
            {System.show {Instance.getMAZE}}
            {System.show {Nth {Instance.getMAZE} (1 * 29 + 1)}}
            %{Nth {Instance.getMAZE} {Instance.getY} * 29 + {Instace.getX}}

        
        else 
            {System.show log('PacmOZ Unknown Message:' Msg)}
        end

        {Handler Upcoming Instance}
    end

    fun {SpawnAgent init(Id GCPort Maze)}
        Stream
        Port = {NewPort Stream}
        Instance

        Instance = {Agent}
        {Instance.setID Id}
        {Instance.setMAZE Maze}
        {Instance.setPORT GCPort}
    in
        thread {Handler Stream Instance} end
        Port
    end
end