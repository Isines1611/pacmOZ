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
        {Record.forAll Tracker proc {$ Agent}
            {System.show live(Agent.id Agent.alive Agent.port Agent.x Agent.y)}
            if Agent.alive then
                {Send Agent.port Msg}
            end
        end}
    end

    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
    fun {GameController State}
        fun {MoveTo moveTo(Id Dir)}
            {State.gui moveBot(Id Dir)}
            {Broadcast State.agent moveTo(Id Dir)}
            {GameController State}
        end
        % function to handle the PacGumSpawned message
        fun {PacgumSpawned pacgumSpawned(X Y)}
            Index = Y * 28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive': true) 'ngum': State.items.ngum + 1)}
        in
            {Broadcast State.agent pacgumSpawned(X Y)}
            {GameController {AdjoinAt State 'items' NewItems}}
        end

        fun {PacgumDispawned pacgumDispawned(X Y)}
            NewState
            Index = Y*28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive': false) 'ngum': State.items.ngum-1)}
        in
            if State.items.ngum == 1 then {System.show 'THE PACMOZ WIN WITH SCORE: 32000'} {Application.exit 0} end
            
            {State.gui updateScore(320 - State.items.ngum)}

            NewState = {AdjoinAt State 'items' NewItems}
            /*NewState = {Adjoin NewState state(
                'score': State.score + 100
            )} */

            {Broadcast State.agent pacgumDispawned(X Y)}
            {GameController NewState}
        end
        
        % function to handle the movedTo message    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
        fun {MovedTo movedTo(Id Type X Y)}
            Index = Y * 28 + X
            NewState
            NState

            Te
            C = {NewCell nil}
        in 
            {Record.forAll State.agent proc {$ Agent}
                if Id \= Agent.id andthen Agent.alive andthen Agent.type \= Type andthen X == Agent.x andthen Y == Agent.y then
                    if State.pacpowActive then % Elimine fantome
                        {System.show 'ghost die'}
                        {System.show die(Agent)}
                    else % Elimine pacmoz
                        {System.show 'pacmoz die'}
                        C := Id
                    end
                end
            end}

            if Type == 'pacmoz' then
                if {HasFeature State.items Index} andthen State.items.Index.alive then
                    {State.gui dispawnPacgum(X Y)}
                end

                if {HasFeature State.pacpow Index} andthen State.pacpow.Index.alive then
                    {State.gui dispawnPacpow(X Y)}
                end
            end

            NewState = {Adjoin State.agent agent(Id: pos(x:X y:Y type:State.agent.Id.type id:Id alive:State.agent.Id.alive port:State.agent.Id.port maze:State.agent.Id.maze))}
            NState = {AdjoinAt State 'agent' NewState}

            {Broadcast State.agent movedTo(Id Type X Y)}

            if @C \= nil then NextState in % Death
                {System.show Te} 
                NextState = {Adjoin State.agent agent(Id: pos(x:X y:Y type:State.agent.@C.type id:@C alive:false port:State.agent.@C.port maze:State.agent.@C.maze))}
                
                {State.gui dispawnBot(@C)}

                {GameController {AdjoinAt State 'agent' NextState}}
            else
                {GameController NState}
            end

        end

        fun {PacpowSpawned pacpowSpawned(X Y)}
            Index = Y * 28 + X
            NewPows = {Adjoin State.pacpow pacpow(Index: pow('alive': true) 'npow': State.pacpow.npow + 1)}
        in
            {Broadcast State.agent spawnPacpow(X Y)}
            {GameController {AdjoinAt State 'pacpow' NewPows}}
        end

        fun {PacpowDispawned pacpowDispawned(X Y)}
            Index = Y * 28 + X
            NewPows = {Adjoin State.pacpow pacpow(Index: pow('alive': false) 'npow': State.pacpow.npow - 1)}
            NewState
            NState
        in
            NState = {AdjoinAt State 'pacpow' NewPows}
            NewState = {Adjoin NState state(
                'pacpowActive': true
            )}

            {Broadcast State.agent pacpowDispawned(X Y)}
            {GameController NewState}
        end

        fun {PacpowDown pacpowDown()}
            NewState
        in
            NewState = {Adjoin State state(
                'pacpowActive': false
            )}

            {Broadcast State.agent pacpowDown()}
            {State.gui setAllScared(false)}
            {GameController NewState}
        end
    in
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
                'pacgumSpawned': PacgumSpawned
                'pacgumDispawned': PacgumDispawned
                'pacpowSpawned': PacpowSpawned
                'pacpowDispawned': PacpowDispawned
                'pacpowDown': PacpowDown
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
        %{System.show handler(Msg|Upcoming)}
        {Handler Upcoming {Instance Msg}}
    end

    fun {InitAgents Agents GUI Maze GCPort}
        fun {BuildAgent Bot}
            ID = {GUI spawnBot(Bot.1 Bot.3 Bot.4 $)}
            PORT = {AgentManager.spawnBot Bot.2 init(ID GCPort Maze)}
        in
            agent(ID: pos(x:Bot.3 y:Bot.4 type:Bot.1 id:ID alive:true port:PORT maze:Maze))
        end

        fun {AddAgents L S}
            NewState
            NState
        in
            case L of H|T then

                NewState = {Adjoin S.agent {BuildAgent H}}
                NState = {AdjoinAt S 'agent' NewState}

                {AddAgents T NState}
            [] nil then S
            end
        end
    in
        {AddAgents Agents agent(agent: unit)}
    end

    % TODO: Spawn the agents
    proc {StartGame}
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 60}

        Agents
        Track

        Maze = {Input.genMaze}
        {GUI buildMaze(Maze)}

        Agents = Input.bots.1 | Input.bots.2.1 | nil

        Track = {InitAgents Agents GUI Maze Port}
        {System.show t(Track)}

        {System.show t2(Track.agent)}

        Instance = {GameController state(
            'gui': GUI
            'maze': Maze
            'score': 0
            'items': items('ngum': 0)
            'pacpow': pacpow('npow': 0)
            'pacpowActive': true

            'agent': Track.agent
         )}

    in
        thread {Handler Stream Instance} end
    end

    {StartGame}
end