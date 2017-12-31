function eeStationMock()
    local callSign = Util.randomUuid()

    return {
        typeName = "SpaceStation",
        getCallSign = function() return callSign end,
        isValid = function() return true end,
    }
end

function eeCpuShipMock()
    local callSign = Util.randomUuid()

    return {
        typeName = "CpuShip",
        getCallSign = function() return callSign end,
        isValid = function() return true end,
    }
end

function personMock()
    return {
        getFormalName = function() return "Johnathan Doe" end,
        getNickName = function() return "John" end
    }
end