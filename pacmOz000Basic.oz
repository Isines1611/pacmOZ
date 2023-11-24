functor

import
    OS
    System
    Application
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

        MOVE = {NewCell true}

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

        proc {SetMOVE N} MOVE := N end
        fun {GetMOVE} @MOVE end
    in
        ag(setID:SetID setMAZE:SetMAZE setPORT:SetPORT getID:GetID getMAZE:GetMAZE getPORT:GetPORT setX:SetX setY:SetY getX:GetX getY:GetY setMOVE:SetMOVE getMOVE:GetMOVE)
    end

    % All usefull functions/proc
    proc {Sum X Y}
        Res = X+Y
    in
        {System.show log('Sum result = ' Res)}
    end

    proc {InfSouth Instance}
        if {GetTile {Instance.getX} {Instance.getY}+1 Instance} == 0 then
            {Send {Instance.getPORT} moveTo({Instance.getID} 'south')}
            {Delay 2000}
        end
        
        {InfSouth Instance}
    end

    proc {BotMoved ID Instance X Y}
        if {Instance.getID} == ID then 
            {Instance.setX X}
            {Instance.setY Y}
            {Instance.setMOVE true}
            
            %{System.show maze(X Y '->' (Y*28+X)+1)}
            %{System.show {Nth {Instance.getMAZE} (Y * 28 + X)+1}}
        end
    end

    fun {GetTile X Y Instance}
        if X < 0 then
            ~1
        elseif Y < 0 then
            {Application.exit 0}
            ~1
        else
            {Nth {Instance.getMAZE} (Y * 28 + X)+1}
        end
    end

    

    % Handler
    proc {Handler Msg | Upcoming Instance}
        case Msg of shutdown() then
            {System.show 'Message Shutdown'}
        [] sum(X Y) then
            {Sum X Y}

        [] movedTo(ID Type X Y) then
            {BotMoved ID Instance X Y}

        [] rand(X) then
            {System.show {GetRandInt X}}

        [] inf then 
            thread {InfSouth Instance} end
        
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