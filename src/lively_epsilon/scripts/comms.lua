require "src/lively_epsilon/utility/lua.lua"
require "src/lively_epsilon/domain/trait/shipTemplateBased/comms.lua"

local function printScreen(npcSays, howPlayerCanReact)
    setCommsMessage(npcSays)
    for _, reaction in pairs(howPlayerCanReact) do
        local playerSays = reaction.playerSays(comms_target, player)
        local goToNextScreen = function()
            if isFunction(reaction.nextScreen) then
                local screen = reaction.nextScreen(comms_target, player)
                printScreen(screen.npcSays, screen.howPlayerCanReact)
            else
                printScreen(comms_target:getHailText(player), comms_target:getComms(player))
            end
        end
        addCommsReply(playerSays, goToNextScreen)
    end
end


function mainMenu()
    if (ShipTemplateBased:hasComms(comms_target)) then
        printScreen(comms_target:getHailText(player), comms_target:getComms(player))
    end
end

mainMenu()
