require "src/lively_epsilon/utility/lua.lua"
require "src/lively_epsilon/domain/trait/shipTemplateBased/comms.lua"

local function printScreen(screen)
    if screen.npcSays ~= nil then
        setCommsMessage(screen.npcSays)
    end
    for _, reaction in pairs(screen.howPlayerCanReact) do
        local visible = reaction.condition(comms_target, player)
        if visible then
            local playerSays = reaction.playerSays(comms_target, player)
            local goToNextScreen = function()
                if isFunction(reaction.nextScreen) then
                    local screen = reaction.nextScreen(comms_target, player)
                    printScreen(screen)
                else
                    printScreen(comms_target:getComms(player))
                end
            end
            addCommsReply(playerSays, goToNextScreen)
        end
    end
end


function mainMenu()
    if (ShipTemplateBased:hasComms(comms_target)) then
        printScreen(comms_target:getComms(player))
    end
end

mainMenu()
