functor

import
    System
    GhOzt000Basic
    PacmOz000Basic
export
    'spawnBot': SpawnBot
define

    % Spawn the agent and returns its port
    fun {SpawnBot BotName Init}
        % Init => init(Id GameControllerPort Maze)
        case BotName of
            'ghOzt000Basic' then {GhOzt000Basic.getPort Init}
        []  'pacmOz000Basic' then {PacmOz000Basic.getPort Init}
        else
            {System.show 'Unknown BotName'}
            false
        end
    end
end