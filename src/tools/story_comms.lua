Tools = Tools or {}

local cronId
local currentShipTemplateBased
local currentPlayer

--- Force the players to accept a comms and follow the dialog.
--- It also (initially) forces the comms screen to be displayed on the main screen so every crew member can read it.
---
--- This is helpful to ensure that a plot relevant chat is seen by the players.
--- @param self
--- @param shipTemplateBased ShipTemplateBased
--- @param player PlayerSpaceship
--- @param screen CommsScreenObject
Tools.storyComms = function(self, shipTemplateBased, player, screen)
    if not isEeShipTemplateBased(shipTemplateBased) then error("Expected a station or ship, but got " .. typeInspect(shipTemplateBased), 2) end
    if not ShipTemplateBased:hasComms(shipTemplateBased) then error("Expected the station or ship to have comms but it does not", 2) end
    if not isEeShipTemplateBased(player) then error("Expected a player, but got " .. typeInspect(player), 2) end
    if not Comms:isScreen(screen) then error("Expected a screen, but got " .. typeInspect(screen), 2) end
    if not isNil(cronId) then error("An annoying hail is already running", 2) end

    shipTemplateBased:overrideComms(screen)
    currentShipTemplateBased = shipTemplateBased
    currentPlayer = player

    cronId = Util.randomUuid()

    local tryFunc = function()
        if not player:isValid() then
            Tools:endStoryComms()
        elseif player:isCommsInactive() then
            if not shipTemplateBased:isValid() then
                Tools:endStoryComms()
            else
                shipTemplateBased:openCommsTo(player)
                player:commandMainScreenOverlay("showcomms")
            end
        end
    end

    tryFunc()

    Cron.regular(cronId, tryFunc)
end

--- End the story comms
--- @param self
Tools.endStoryComms = function(self)
    if cronId ~= nil then

        Cron.abort(cronId)
        cronId = nil
        if currentPlayer:isValid() then
            currentPlayer:commandMainScreenOverlay("hidecomms")
        end
        if currentShipTemplateBased:isValid() then
            currentShipTemplateBased:overrideComms(nil)
        end
    end
end
