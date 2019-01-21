function isEeObject(thing)
    return type(thing) == "table" and thing.typeName ~= nil
end

-- check if the given variable is a CpuShip object from EmptyEpsilon
function isEeShip(thing)
    return isEeObject(thing) and thing.typeName == "CpuShip"
end

-- check if the given variable is a PlayerSpaceship object from EmptyEpsilon
function isEePlayer(thing)
    return isEeObject(thing) and thing.typeName == "PlayerSpaceship"
end

-- check if the given variable is a SpaceStation object from EmptyEpsilon
function isEeStation(thing)
    return isEeObject(thing) and thing.typeName == "SpaceStation"
end

-- check if the given variable is a Nebula object from EmptyEpsilon
function isEeNebula(thing)
    return isEeObject(thing) and thing.typeName == "Nebula"
end
-- check if the given variable is an Artifact object from EmptyEpsilon
function isEeArtifact(thing)
    return isEeObject(thing) and thing.typeName == "Artifact"
end
-- check if the given variable is an SupplyDrop object from EmptyEpsilon
function isEeSupplyDrop(thing)
    return isEeObject(thing) and thing.typeName == "SupplyDrop"
end

-- check if the given variable is a SpaceShip object from EmptyEpsilon
function isEeSpaceShip(thing)
    return isEeShip(thing) or isEePlayer(thing)
end

-- check if the given variable is a ShipTemplateBased object from EmptyEpsilon
function isEeShipTemplateBased(thing)
    return isEeSpaceShip(thing) or isEeStation(thing)
end

-- check if the given variable is an Asteroid object from EmptyEpsilon
function isEeAsteroid(thing)
    return isEeObject(thing) and thing.typeName == "Asteroid"
end

-- check if the given variable is a Mine object from EmptyEpsilon
function isEeMine(thing)
    return isEeObject(thing) and thing.typeName == "Mine"
end

-- check if the given variable is a WormHole object from EmptyEpsilon
function isEeWormHole(thing)
    return isEeObject(thing) and thing.typeName == "WormHole"
end
-- check if the given variable is a BlackHole object from EmptyEpsilon
function isEeBlackHole(thing)
    return isEeObject(thing) and thing.typeName == "BlackHole"
end

-- check if the given variable is a BlackHole object from EmptyEpsilon
function isEeWarpJammer(thing)
    return isEeObject(thing) and thing.typeName == "WarpJammer"
end
-- check if the given variable is a ScanProbe object from EmptyEpsilon
function isEeScanProbe(thing)
    return isEeObject(thing) and thing.typeName == "ScanProbe"
end

function isVector2f(thing)
    return Util.isNumericTable(thing) and isNumber(thing[1]) and isNumber(thing[2])
end