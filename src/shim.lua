-- Shims are a way to backport features from newer EE versions to older versions to allow for some
-- grace when you need to update EE to play a mission.
-- They will not stay forever, so try to upgrade soon.

if not isFunction(_G.getLongRangeRadarRange) then
    _G.getLongRangeRadarRange = function()
        local ship = getPlayerShip(-1)
        if isEePlayer(ship) then
            logDeprecation("getLongRangeRadarRange() is shimmed. Consider upgrading your mission script.")

            return ship:getLongRangeRadarRange()
        else
            return 30000
        end
    end
end


local theRealPlayerSpaceship = PlayerSpaceship

_G.PlayerSpaceship = function()
    local player = theRealPlayerSpaceship()
    player.getLongRangeRadarRange = player.getLongRangeRadarRange or function()
        logDeprecation("PlayerSpaceship:getLongRangeRadarRange() is shimmed. Consider upgrading your Empty Epsilon installation.")
        return _G.getLongRangeRadarRange()
    end
    player.getShortRangeRadarRange = player.getShortRangeRadarRange or function()
        logDeprecation("PlayerSpaceship:getShortRangeRadarRange() is shimmed. Consider upgrading your Empty Epsilon installation.")
        return 5000
    end

    return player
end