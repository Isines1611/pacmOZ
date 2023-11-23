functor

import
    Input
    System
    Graphics
    AgentManager
    Application
define
     % Check the Adjoin and AdjoinAt function, documentation: (http://mozart2.org/mozart-v1/doc-1.4.0/base/record.html#section.records.records)

    proc {Broadcaster Tracker Msg}
        {Record.forAll Tracker proc {$ Tracked} if Tracked.alive then {Send Tracked.port Msg} end end}
    end

    % Send MSG to all PORTS
    proc {Broadcast PORTS Msg}
        case PORTS of H|T then
            {Send H Msg} 
            {Broadcast T Msg}
        [] nil then skip
        end
    end
    % TODO: define here any auxiliary functions or procedures you may need

    fun {GC}
        GUI = {NewCell 0}
        MAZE = {NewCell 0}
        SCORE = {NewCell 0}

        PORTS = {NewCell nil}

        proc {SetGUI X} GUI := X end
        fun {GetGUI} @GUI end
        proc {SetMAZE X} MAZE := X end
        fun {GetMAZE} @MAZE end
        proc {SetSCORE X} SCORE := X end
        fun {GetSCORE} @SCORE end

        proc {AppendPORTS X} PORTS := X|@PORTS end
        fun {GetPORTS} @PORTS end
    in
        gc(setGUI:SetGUI setMAZE:SetMAZE setSCORE:SetSCORE getGUI:GetGUI getMAZE:GetMAZE getSCORE:GetSCORE appendPORTS:AppendPORTS getPORTS:GetPORTS)
    end

    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
    fun {GameController State}
        fun {MoveTo moveTo(Id Dir)}
            {System.show 'moving'}
            {State.gui moveBot(Id Dir)}
            {GameController State}
        end
        % function to handle the PacGumSpawned message
        fun {PacgumSpawned pacgumSpawned(X Y)}
            Index = Y * 28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive': true) 'ngum': State.items.ngum + 1)}
        in
            {System.show 'spawn pacgum'}
            {Broadcaster State.tracker pacgumSpawned(X Y)}
            {GameController {AdjoinAt State 'items' NewItems}}
        end
        % TODO: add other functions to handle the messages here
        %...
        
        % function to handle the movedTo message    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
        % Says to everyone that ID moved
        fun {MovedTo movedTo(Id Type X Y)}
            {System.show log(Id Type X Y)}

            
            % Create a NewState record with Adjoin/AdjoinAt function and return it
            {GameController State}
        end

        fun {IncreaseScore}
            {System.show 'points'}
            /* {System.show State}
            {System.show {State}}
            {System.show {State.score}} */
            {GameController State}
        end
    in
        % TODO: complete the interface and discard and report unknown messages
        % every function is a field in the interface() record
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
                'pacgumSpawned': PacgumSpawned
                'increaseScore': IncreaseScore
                %TODO: add other messages here
                %...
            )
        in
            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                %{System.show log('Unhandle message' Dispatch)}
                {GameController State}
            end
        end
    end

    proc {IncreaseScored State}
        CurrentPoints = {State.getSCORE}
        NewPoints = CurrentPoints+1
    in
        {State.setSCORE NewPoints}
        {{State.getGUI} updateScore(NewPoints)}
    end

    proc {MoveTo ID Dir State}
        {{State.getGUI} moveBot(ID Dir)}
        {{State.getGUI} update()}
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        case Msg of shutdown() then
            {System.show 'Message Shutdown'}
        [] increaseScore then
            {IncreaseScored Instance}

        [] moveTo(ID Dir) then
            {MoveTo ID Dir Instance}

        [] pacgumSpawned(X Y) then
            skip

        [] pacpowSpawned(X Y) then
            skip

        [] movedTo(ID Type X Y) then
            {System.show log('bot' ID 'has moved towards' X Y)}
            {Broadcast {Instance.getPORTS} movedTo(ID Type X Y)}

        else 
            {System.show log('Main Unknown Message' Msg)}
            %skip
        end

        %{{Instance.getGUI} update()}
        {Handler Upcoming Instance}
    end

    % TODO: Spawn the agents
    proc {StartGame}
        PacmozID
        PacmozPort
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 30}

        Maze = {Input.genMaze}
        {GUI buildMaze(Maze)}

        Instance = {GC}
        {Instance.setGUI GUI}
        {Instance.setMAZE Maze}
        {Instance.setSCORE 0}

        %{GUI updateScore(100)} % Update le score c'est bete mais ca marche

        {GUI spawnBot('pacmoz' 1 1 PacmozID)}
        %PacmozPort = {AgentManager.spawnBot 'pacmOz000Basic' init({GUI genId($)} Maze Port)}
        PacmozPort = {AgentManager.spawnBot 'pacmOz000Basic' init(PacmozID Port Maze)}

        {Instance.appendPORTS PacmozPort}

        {System.show {Instance.getPORTS}}
        
        %%% MSG
        {GUI moveBot(PacmozID 'south')}
        {GUI moveBot(PacmozID 'south')}

        {Send PacmozPort test}
        {Send PacmozPort movedTo(south)}
        {Send PacmozPort inf}
        
    in
        % TODO: log the winning team name and the score then use {Application.exit 0}
       % {GUI dispawnPacgum(1 1)}
       % {GUI moveBot(PacmozID 'south')}

        {GUI update()}
        {Handler Stream Instance}
        {Application.exit 0}
    end

    {StartGame}
end
