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

    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
    fun {GameController State}
        fun {MoveTo moveTo(Id Dir)}
            {State.gui moveBot(Id Dir)}
            {State.gui update()}
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

        fun {PacgumDispawned pacgumDispawned(X Y)}
            {System.show 'rm'}
            {GameController State}
        end
        
        % function to handle the movedTo message    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
        fun {MovedTo movedTo(Id Type X Y)}
            NewItems
            Index = Y * 28 + X
        in 
            if Type == 'pacmoz' andthen {HasFeature State.items Index} andthen State.items.Index.alive then
                NewItems = {Adjoin State.items items(Index: gum('alive': false) 'ngum': State.items.ngum-1)}
                
                {Broadcast State.tracker pacgumDispawned(X Y)}
                {State.gui updateScore(320 - State.items.ngum)}
                {State.gui dispawnPacgum(X Y)}

                if State.items.ngum == 1 then
                    {System.show win('THE PACMOZ WIN WITH SCORE:' NewPoints*100)}
                    {Application.exit 0}
                end

                {Broadcast State.tracker movedTo(Id Type X Y)}
                {GameController {AdjoinAt State 'items' NewItems}}
            else
                {Broadcast State.tracker movedTo(Id Type X Y)}
                {GameController State}
            end

            
        end
    in
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
                'pacgumSpawned': PacgumSpawned
                'pacgumDispawned': PacgumDispawned
            )
        in
            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                {System.show log('Unhandle message' Dispatch)}
                {GameController State}
            end
        end
    end

    proc {Handler Msg | Upcoming Instance}
        {Handler Upcoming {Instance Msg}}
    end

    % TODO: Spawn the agents
    proc {StartGame}
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 30}
        PacmozID
        PacmozPort

        Maze = {Input.genMaze}
        {GUI buildMaze(Maze)}

        {GUI spawnBot('pacmoz' 1 1 PacmozID)}
        PacmozPort = {AgentManager.spawnBot 'pacmOz000Basic' init(PacmozID Port Maze)}

        Instance = {GameController state(
            'gui': GUI
            'maze': Maze
            'score': 0
            'items': items('ngum': 0)
            'tracker': track(playerState(alive:true id:PacmozID port:PacmozPort))
        )}
    in
        {GUI update()}
        {Handler Stream Instance}
        {Application.exit 0}
    end

    {StartGame}
end
