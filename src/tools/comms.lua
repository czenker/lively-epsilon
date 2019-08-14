Tools = Tools or {}

--- makes sure the player is able to at least once accept a communication
--- @param self
--- @param shipTemplateBased ShipTemplateBased
--- @param player PlayerSpaceship
--- @param message nil|string if `nil` it will offer a comms to the given target. Else it will just send the message.
Tools.ensureComms = function(self, shipTemplateBased, player, message)
    if not isEeShipTemplateBased(shipTemplateBased) then error("Expected a station or ship, but got " .. typeInspect(shipTemplateBased), 2) end
    if not isEePlayer(player) then error("Expected a player, but got " .. typeInspect(player), 2) end
    if not isString(message) and not isNil(message) then error("Expected message to be nil or string, but got " .. typeInspect(message), 2) end

    local tryFunc = function()
        if not player:isValid() then
            logWarning("Aborting ensureComms because player is no longer valid")
            return true
        elseif not shipTemplateBased:isValid() then
            logWarning("Aborting ensureComms because sender is no longer valid")
            return true
        elseif player:isCommsInactive() then
            if isNil(message) then
                shipTemplateBased:openCommsTo(player)
            else
                shipTemplateBased:sendCommsMessage(player, message)
            end
            return true
        end
        return false
    end

    if not tryFunc() then
        Cron.regular(function(self)
            if tryFunc() then Cron.abort(self) end
        end)
    end
end
