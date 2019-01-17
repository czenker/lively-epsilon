ShipTemplateBased = ShipTemplateBased or {}

ShipTemplateBased.withUpgradeBroker = function (self, spaceObject, config)
    if not isEeShipTemplateBased(spaceObject) then error ("Expected a shipTemplateBased object but got " .. typeInspect(spaceObject), 2) end
    if ShipTemplateBased:hasUpgradeBroker(spaceObject) then error ("Object with call sign " .. spaceObject:getCallSign() .. " already has an upgrade broker.", 2) end

    config = config or {}
    if not isTable(config) then
        error("Expected config to be a table, but " .. type(config) .. " given.", 2)
    end
    if not isNil(config.upgrades) and not isTable(config.upgrades) then error("Upgrades need to be a table, but got " .. typeInspect(config.upgrades)) end

    local upgrades = {}

    spaceObject.addUpgrade = function(self, upgrade)
        if not BrokerUpgrade:isUpgrade(upgrade) then
            error("Expected upgrade to be a broker upgrade, but " .. type(upgrade) .. " given.", 2)
        end

        upgrades[upgrade:getId()] = upgrade
    end

    spaceObject.removeUpgrade = function(self, upgrade)
        if isString(upgrade) then
            upgrades[upgrade] = nil
        elseif BrokerUpgrade:isUpgrade(upgrade) then
            upgrades[upgrade:getId()] = nil
        else
            error("Expected upgrade to be a upgrade or upgrade id, but " .. type(upgrade) .. " given.", 2)
        end
    end

    spaceObject.getUpgrades = function(self)
        local ret = {}
        for _,upgrade in pairs(upgrades) do
            table.insert(ret, upgrade)
        end
        return ret
    end

    spaceObject.hasUpgrades = function(self)
        for _,_ in pairs(upgrades) do
            return true
        end
        return false
    end

    for _, upgrade in pairs(config.upgrades or {}) do
        spaceObject:addUpgrade(upgrade)
    end
end

ShipTemplateBased.hasUpgradeBroker = function(self, thing)
    return isFunction(thing.addUpgrade) and
            isFunction(thing.removeUpgrade) and
            isFunction(thing.getUpgrades) and
            isFunction(thing.hasUpgrades)
end