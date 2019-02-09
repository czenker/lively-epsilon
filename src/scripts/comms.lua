require "lively_epsilon/src/utility/lua.lua"
require "lively_epsilon/src/domain/trait/shipTemplateBased/comms.lua"

local function printScreen(screen)
    local whatNpcSays = screen:getWhatNpcSays(comms_target, player)
    if whatNpcSays ~= nil and whatNpcSays ~= "" then
        setCommsMessage(whatNpcSays)
    end
    for _, reaction in pairs(screen:getHowPlayerCanReact()) do
        local visible = reaction:checkCondition(comms_target, player)
        if visible then
            local playerSays = reaction:getWhatPlayerSays(comms_target, player)
            local goToNextScreen = function()
                local nextScreen = reaction:getNextScreen(comms_target, player)
                if nextScreen ~= nil then
                    printScreen(nextScreen)
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
