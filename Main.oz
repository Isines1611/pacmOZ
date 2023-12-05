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
            {Broadcast State.tracker moveTo(Id Dir)}
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

            {Broadcast State.tracker pacgumDispawned(X Y)}
            {GameController NewState}
        end
        
        % function to handle the movedTo message    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
        fun {MovedTo movedTo(Id Type X Y)}
            Index = Y * 28 + X
        in 
            if Type == 'ghost' then
                {Broadcast State.tracker movedTo(Id Type X Y)}
                {GameController State}
            elseif Type == 'pacmoz' then
                {Broadcast State.tracker movedTo(Id Type X Y)}

                if {HasFeature State.items Index} andthen State.items.Index.alive then
                    {State.gui dispawnPacgum(X Y)}
                end

                if {HasFeature State.pacpow Index} andthen State.pacpow.Index.alive then
                    {State.gui dispawnPacpow(X Y)}
                end

                {GameController State}
            
            else
                {GameController State}
            end
        end

        fun {PacpowSpawned pacpowSpawned(X Y)}
            Index = Y * 28 + X
            NewPows = {Adjoin State.pacpow pacpow(Index: pow('alive': true) 'npow': State.pacpow.npow + 1)}
        in
            {Broadcast State.tracker spawnPacpow(X Y)}
            {System.show State.pacpow}
            {GameController {AdjoinAt State 'pacpow' NewPows}}
        end

        fun {PacpowDispawned pacpowDispawned(X Y)}
            Index = Y * 28 + X
            NewPows = {Adjoin State.pacpow pacpow(Index: pow('alive': false) 'npow': State.pacpow.npow - 1)}
        in
            {Broadcast State.tracker pacpowDispawned(X Y)}
            {GameController {AdjoinAt State 'pacpow' NewPows}}
        end

        fun {PacpowDown pacpowDown()}
            {Broadcast State.tracker pacpowDown()}
            {State.gui setAllScared(false)}
            {GameController State}
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
        {System.show handler(Msg|Upcoming)}
        {Handler Upcoming {Instance Msg}}
    end

    fun {InitAgents Agents Bool GUI Port Maze}
        fun {BuildAgent Bot}
            ID = {GUI spawnBot(Bot.1 Bot.3 Bot.4 $)}
            PORT = {AgentManager.spawnBot Bot.2 init(ID Port Maze)}
        in
            p(alive:true id:ID port:PORT)
        end

        fun {AddAgents L Acc}
            case L of H|T then
                {AddAgents T Acc|{BuildAgent H}}
            [] nil then Acc
            end
        end

        First
        End
    in
        case Agents of H|T then
            First = {BuildAgent H}
            End = {AddAgents T First}
        [] nil then End
        end
    end

    % TODO: Spawn the agents
    proc {StartGame}
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 30}
        PacmozID
        PacmozPort
        GhoZtID
        GhoZtPort 
        GhoZt2ID
        GhoZt2Port 
        GhoZt3ID
        GhoZt3Port 
        /*GhoZt4ID
        GhoZt4Por* */
        Track

        Maze = {Input.genMaze}
        {GUI buildMaze(Maze)}

        PacmozPort = {AgentManager.spawnBot 'pacmOz000Basic' init(PacmozID Port Maze)}
        thread {GUI spawnBot('pacmoz' 1 1 PacmozID)} end

        GhoZtPort = {AgentManager.spawnBot 'pacmOz000Basic' init(GhoZtID Port Maze)}
        thread {GUI spawnBot('pacmoz' 26 27 GhoZtID)} end
        
        GhoZt2Port = {AgentManager.spawnBot 'ghOzt000Basic' init(GhoZt2ID Port Maze)}
        thread {GUI spawnBot('ghost' 1 27 GhoZt2ID)} end

        GhoZt3Port = {AgentManager.spawnBot 'ghOzt000Basic' init(GhoZt3ID Port Maze)}
        thread {GUI spawnBot('ghost' 26 1 GhoZt3ID)} end
        
        /*GhoZt4Port = {AgentManager.spawnBot 'ghOzt000Basic' init(GhoZt4ID Port Maze)}
        thread {GUI spawnBot('ghost' 1 1 GhoZt4ID)} end
         */
        %Track = {InitAgents Input.bots 0 GUI Port Maze}

        Instance = {GameController state(
            'gui': GUI
            'maze': Maze
            'score': 0
            'items': items('ngum': 0)
            'pacpow': pacpow('npow': 0)
            %'tracker': p(p(alive:true id:PacmozID port:PacmozPort))
            %'tracker': p(alive:true id:GhoZtID port:GhoZtPort)#p(alive:true id:PacmozID port:PacmozPort)
            'tracker': p(alive:true id:GhoZtID port:GhoZtPort)#p(alive:true id:PacmozID port:PacmozPort)#p(alive:true id:GhoZt2ID port:GhoZt2Port)#p(alive:true id:GhoZt3ID port:GhoZt3Port)
            %'tracker': p(alive:true id:GhoZtID port:GhoZtPort)#p(alive:true id:GhoZt2ID port:GhoZt2Port)#p(alive:true id:GhoZt3ID port:GhoZt3Port)#p(alive:true id:GhoZt4ID port:GhoZt4Port)
        )}

    in
        thread {Handler Stream Instance} end
    end

    {StartGame}
end
