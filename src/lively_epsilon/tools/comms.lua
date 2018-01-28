Tools = Tools or {}

Tools.ensureComms = function(self, shipTemplateBased, player, description)
    if not isEeShipTemplateBased(shipTemplateBased) then error("Expected a station or ship, but got " .. type(shipTemplateBased), 2) end
    if not isEePlayer(player) then error("Expected a player, but got " .. type(player), 2) end

    local cronId = Util.randomUuid()

    Cron.regular(cronId, function()
        if player:isCommsInactive() then
            shipTemplateBased:sendCommsMessage(player, description)
            Cron.abort(cronId)
        end
    end, 0.1, 0)
end
