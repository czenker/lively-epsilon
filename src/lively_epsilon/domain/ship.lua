local prototype = {
    isEnriched = true,
    maxStorage = 1000,
    getCloseObjects = function(self, radius)
        radius = radius or getLongRangeRadarRange()
        local x, y = self:getPosition()
        getObjectsInRadius(x, y, radius)
    end
}


Ship = {
    -- enrich a CpuShip with more story driven properties
    enrich = function(self, ship)
        if not isEeShip(ship) then
            error("ship given to Ship.enrich needs to be a CpuShip", 2)
        end

        if (ship.isEnriched == true) then return ship end

        for key, value in pairs(prototype) do
            ship[key] = value
        end

        ship.captain = Person:new()

        ship:setCommsScript("src/lively_epsilon/scripts/comms.lua")

        return ship
    end
}

setmetatable(Ship,{
    __index = ShipTemplateBased
})