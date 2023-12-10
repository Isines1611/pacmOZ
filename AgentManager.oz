functor

import
    System
    GhOzt117Hunter
    GhOzt117Basic
    PacmOz117Basic
export
    'spawnBot': SpawnBot
define

    % Spawn the agent and returns its port
    fun {SpawnBot BotName Init}
        % Init => init(Id GameControllerPort Maze)
        case BotName of
            'ghOzt117Hunter' then {GhOzt117Hunter.getPort Init}
        []  'pacmOz117Basic' then {PacmOz117Basic.getPort Init}
        []  'ghOzt117Basic' then {GhOzt117Basic.getPort Init}
        else
            {System.show 'Unknown BotName'}
            false
        end
    end
end