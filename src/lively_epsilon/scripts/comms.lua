require "src/lively_epsilon/utility/lua.lua"
require "src/lively_epsilon/utility/traits.lua"

local function printScreen(npcSays, howPlayerCanReact)
    setCommsMessage(npcSays)
    for _, reaction in pairs(howPlayerCanReact) do
        local playerSays = reaction.playerSays
        local goToNextScreen = function()
            if isFunction(reaction.nextScreen) then
                local screen = reaction.nextScreen(comms_target, player)
                printScreen(screen.npcSays, screen.howPlayerCanReact)
            else
                printScreen(comms_target:getHailText(), comms_target:getComms())
            end
        end
        addCommsReply(playerSays, goToNextScreen)
    end
end


function mainMenu()
    if (hasComms(comms_target)) then
        printScreen(comms_target:getHailText(), comms_target:getComms())
    end
end

mainMenu()
