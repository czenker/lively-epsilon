humanShipHail = function(self, player)
    return "Hello " .. player:getCallSign() .. ".\n\nThis is Captain " .. self:getCrewAtPosition("captain"):getFormalName() .. " of " .. self:getCallSign() .. ". How can I help you?"
end

humanStationHail = function(self, player)
    return "Hello World"
end
