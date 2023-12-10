functor

import
    Input
    System
    Graphics
    AgentManager
    Application
    QTk at 'x-oz://system/wp/QTk.ozf'
define
     % Check the Adjoin and AdjoinAt function, documentation: (http://mozart2.org/mozart-v1/doc-1.4.0/base/record.html#section.records.records)
    proc {Broadcast Tracker Msg}
        {Record.forAll Tracker proc {$ Agent}
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
       
        fun {PacgumSpawned pacgumSpawned(X Y)}
            Index = Y * 28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive': true) 'ngum': State.items.ngum + 1)}
        in
            {Broadcast State.agent pacgumSpawned(X Y)}
            {GameController {AdjoinAt State 'items' NewItems}}
        end

        fun {PacgumDispawned pacgumDispawned(X Y)}
            FState
            NewState
            Index = Y*28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive': false) 'ngum': State.items.ngum-1)}
        in
            if State.items.ngum == 1 then {System.show 'THE PACMOZ WIN WITH SCORE: 32000'} {Application.exit 0} end
            
            {State.gui updateScore(320 - State.items.ngum)}

            NewState = {AdjoinAt State 'items' NewItems}
            FState = {Adjoin NewState state(
                'score': State.score + 100
            )}

            {Broadcast State.agent pacgumDispawned(X Y)}
            {GameController FState}
        end
        
        % function to handle the movedTo message    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
        fun {MovedTo movedTo(Id Type X Y)}
            Index = Y * 28 + X
            NewState
            NState

            Dead
        in  
            {CheckWin}

            {Record.forAll State.agent proc {$ Agent}
                if Id \= Agent.id andthen Agent.alive andthen X == Agent.x andthen Y == Agent.y andthen Agent.type \= Type then

                    if Type == 'pacmoz' andthen State.pacpowActive then
                        Dead = Agent.id
                        {Send State.agent shutdown()} 
                    elseif Type == 'pacmoz' then
                        Dead = Id
                        {Send State.agent shutdown()} 
                    elseif Type == 'ghozt' andthen State.pacpowActive then
                        Dead = Id
                        {Send State.agent shutdown()} 
                    else
                        Dead = Agent.id
                        {Send State.agent shutdown()} 
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

            if {Value.isDet Dead} then NextState FState TState in 
                NextState = {Adjoin State.agent agent(Dead: pos(x:X y:Y type:State.agent.Dead.type id:Dead alive:false port:State.agent.Dead.port maze:State.agent.Dead.maze))}
                TState = {AdjoinAt State 'agent' NextState}

                if State.agent.Dead.type == 'pacmoz' then % Pacmoz Eliminated
                    
                    FState = {Adjoin TState state(
                        'lives': lives('pacmozTotal':State.lives.pacmozTotal 'pacmozDead':State.lives.pacmozDead+1 'ghoztTotal':State.lives.ghoztTotal 'ghoztDead':State.lives.ghoztDead)
                        
                    )}
                    
                else % Ghozt eliminated
                    
                    FState = {Adjoin TState state(
                        'lives': lives('pacmozTotal':State.lives.pacmozTotal 'pacmozDead':State.lives.pacmozDead 'ghoztTotal':State.lives.ghoztTotal 'ghoztDead':State.lives.ghoztDead+1)
                        'score': State.score + 500
                    )}
                               
                end

                {State.gui dispawnBot(Dead)}

                {GameController FState}
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

        proc {CheckWin}
            if State.lives.pacmozDead == State.lives.pacmozTotal then
                {System.show log('THE GHOZT TEAM WIN')} {Application.exit 0}
            elseif State.lives.ghoztTotal == State.lives.ghoztDead then
                {System.show log('THE PACMOZ TEAM WIN WITH SCORE:' State.score)} {Application.exit 0}
            end
        end

        fun {TellTeam tellTeam(Id Rec)}
            {Record.forAll State.agent proc {$ Agent}
                if Agent.type == State.agent.Id.type then
                    {Send Agent.port Rec}
                end
            end}

            {GameController State}
        end

        fun {Haunt haunt(PId GId)}
            NewState
            NState
            FState
        in
            if State.agent.PId.alive andthen State.agent.GId.alive andthen State.agent.PId.type \= State.agent.GId.type andthen State.agent.PId.x == State.agent.GId.x andthen State.agent.PId.x == State.agent.GId.x then

                NewState = {Adjoin State.agent agent(PId: pos(x:State.agent.PId.x y:State.agent.PId.y type:State.agent.PId.type id:PId alive:false port:State.agent.PId.port maze:State.agent.PId.maze))}
                NState = {AdjoinAt State 'agent' NewState}

                FState = {Adjoin NState state(
                    'lives': lives('pacmozTotal':State.lives.pacmozTotal 'pacmozDead':State.lives.pacmozDead+1 'ghoztTotal':State.lives.ghoztTotal 'ghoztDead':State.lives.ghoztDead)
                )}

                {Broadcast State.agent gotHaunted(PId)}
                {Send State.agent.PId.port shutdown()}
                
                {GameController FState}

            else {Send State.agent.PId.port invalidAction()} {GameController State}
            end
        end

        fun {Incense incense(PId GId)}
            NewState
            NState
            FState
        in
            if State.agent.PId.alive andthen State.agent.GId.alive andthen State.agent.PId.type \= State.agent.GId.type andthen State.agent.PId.x == State.agent.GId.x andthen State.agent.PId.x == State.agent.GId.x then
                
                NewState = {Adjoin State.agent agent(PId: pos(x:State.agent.PId.x y:State.agent.PId.y type:State.agent.PId.type id:PId alive:false port:State.agent.PId.port maze:State.agent.PId.maze))}
                NState = {AdjoinAt State 'agent' NewState}

                FState = {Adjoin NState state(
                    'lives': lives('pacmozTotal':State.lives.pacmozTotal 'pacmozDead':State.lives.pacmozDead 'ghoztTotal':State.lives.ghoztTotal 'ghoztDead':State.lives.ghoztDead+1)
                    'score': State.score + 500
                )}

                {Broadcast State.agent gotIncensed(PId)}
                {Send State.agent.PId.port shutdown()}
                
                {GameController FState}

            else {Send State.agent.PId.port invalidAction()} {GameController State}
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
                'pacpowSpawned': PacpowSpawned
                'pacpowDispawned': PacpowDispawned
                'pacpowDown': PacpowDown
                'tellTeam': TellTeam
                'haunt': Haunt
                'incerse': Incense
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

        fun {AddAgents L S PT GT}
            NewState
            NState
        in
            case L of H|T then

                NewState = {Adjoin S.agent {BuildAgent H}}
                NState = {AdjoinAt S 'agent' NewState}

                if H.1 == 'pacmoz' then {AddAgents T NState PT+1 GT}
                else {AddAgents T NState PT GT+1}
                end

            [] nil then [S PT GT]
            end
        end
    in
        {AddAgents Agents agent(agent: unit) 0 0}
    end

    % EXTENSIONS
    fun {ConfigureKeys AgentId UpKey DownKey LeftKey RightKey}
        KeyConfig = agent(
            'id': AgentId
            'keys': keys('up': UpKey 'down': DownKey 'left': LeftKey 'right': RightKey)
        )
    in
        KeyConfig
    end

    % TODO: Spawn the agents
    proc {StartGame}
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 60}
        PacmozKeys

        Agents
        Track

        Maze = {Input.genMaze}
        {GUI buildMaze(Maze)}

        Agents = Input.bots.1 | Input.bots.2.1 | nil

        Track = {InitAgents Agents GUI Maze Port}

        PacmozKeys = {QTk.build lr(
            button(text:"Move Up" action:proc{$} {Send Track.1.agent moveTo('pacmoz' 'up')} end)
            button(text:"Move Down" action:proc{$} {Send Track.1.agent moveTo('pacmoz' 'down')} end)
            button(text:"Move Left" action:proc{$} {Send Track.1.agent moveTo('pacmoz' 'left')} end)
            button(text:"Move Right" action:proc{$} {Send Track.1.agent moveTo('pacmoz' 'right')} end)
        )}

        Instance = {GameController state(
            'gui': GUI
            'maze': Maze
            'score': 0
            'items': items('ngum': 0)
            'pacpow': pacpow('npow': 0)
            'pacpowActive': true

            'lives': lives('pacmozTotal':Track.2.1 'pacmozDead':0 'ghoztTotal':Track.2.2.1 'ghoztDead':0)
            'agent': Track.1.agent
        )}

    in
        thread {PacmozKeys show} end
        thread {Handler Stream Instance} end
    end

    {StartGame}
end
