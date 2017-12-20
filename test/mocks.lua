function eeStationMock()
    local callSign = Util.randomUuid()


    return {
        typeName = "SpaceStation",
        getCallSign = function() return callSign end
    }
end