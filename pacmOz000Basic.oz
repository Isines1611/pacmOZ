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

        proc {SetID X} ID := X end
        fun {GetID} @ID end
        proc {SetMAZE X} MAZE := X end
        fun {GetMAZE} @MAZE end
        proc {SetPORT X} PORT := X end
        fun {GetPORT} @PORT end
    in
        ag(setID:SetID setMAZE:SetMAZE setPORT:SetPORT getID:GetID getMAZE:GetMAZE getPORT:GetPORT)
    end

    % All usefull functions/proc
    proc {Sum X Y}
        Res = X+Y
    in
        {System.show Res}
    end

    proc {Print Msg}
        {System.show Msg}
    end

    proc {Moving Dir Instance}
        {Send {Instance.getMAZE} moveTo({Instance.getID} Dir)}
    end

    % Handler
    proc {Handler Msg | Upcoming Instance}
        case Msg of shutdown() then
            {System.show 'Message Shutdown'}
        [] sum(X Y) then
            {Sum X Y}

        [] print(M) then
            {Print M}

        [] movedTo(Dir) then
            {System.show Dir}
            {Moving Dir Instance}

        [] getID() then
            {System.show {Instance.getMAZE}}

        [] rand(X) then
            {System.show {GetRandInt X}}


        else 
            {System.show 'Unknown Message'}
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
