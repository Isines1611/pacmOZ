functor

import
    Input
    System
    Graphics
    AgentManager
    Application
define
     % Check the Adjoin and AdjoinAt function, documentation: (http://mozart2.org/mozart-v1/doc-1.4.0/base/record.html#section.records.records)

    proc {Broadcast Tracker Msg}
        {Record.forAll Tracker proc {$ Tracked} if Tracked.alive then {Send Tracked.port Msg} end end}
    end
    % TODO: define here any auxiliary functions or procedures you may need

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
            {Broadcast State.tracker pacgumSpawned(X Y)}
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
    in
        % TODO: complete the interface and discard and report unknown messages
        % every function is a field in the interface() record
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
                'pacgumSpawned': PacgumSpawned
                %TODO: add other messages here
                %...
            )
        in
            if {HasFeature Msg Dispatch} then
                {Interface.Dispatch Msg}
            else
                %{System.show log('Unhandle message' Dispatch)}
                {GameController State}
            end
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        {Handler Upcoming {Instance Msg}}
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

        Instance = {GameController state(
            'gui': GUI
            'maze': Maze
            'score': 0
        )}

        {GUI updateScore(100)} % Update le score c'est bete mais ca marche

        PacmozID = {GUI spawnBot('pacmoz' 1 1 $)}
        PacmozPort = {AgentManager.spawnBot 'pacmOz000Basic' init({GUI genId($)} Maze Port)}

        {Send PacmozPort 'movedTo'}
        {Send PacmozPort sum(5 7)}

        {Send PacmozPort movedTo(south)}
        
    in
        % TODO: log the winning team name and the score then use {Application.exit 0}
        {GUI dispawnPacgum(1 1)}
        {GUI moveBot(PacmozID 'south')}

        {System.show 'TEAM'}
        {Handler Stream Instance}
        {Application.exit 0}
    end

    {StartGame}
end
