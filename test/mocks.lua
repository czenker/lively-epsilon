local noop = function() end

function SpaceObject()
    local isValid = true
    local positionX, positionY = 0, 0
    local reputationPoints = 0

    return {
        isValid = function() return isValid end,
        destroy = function(self) isValid = false; return self end,
        getPosition = function() return positionX, positionY end,
        setPosition = function(self, x, y) positionX, positionY = x, y; return self end,
        getObjectsInRange = function(self) return {} end,
        setReputationPoints = function(self, amount) reputationPoints = amount; return self end,
        getReputationPoints = function(self) return reputationPoints end,
        takeReputationPoints = function(self, amount) reputationPoints = math.max(0, reputationPoints - amount); return self end,
        addReputationPoints = function(self, amount) reputationPoints = reputationPoints + amount; return self end,
    }
end
function eeShipTemplateBasedMock()
    local callSign = Util.randomUuid()

    return Util.mergeTables(SpaceObject(), {
        getCallSign = function() return callSign end,
        setSystemHealth = noop,
        getSystemHealth = function() return 1 end,
        getShieldCount = function() return 1 end,
        setShields = noop,
        setShieldsMax = noop,
        getShieldMax = function() return 0 end,
        setCommsScript = noop,
    })
end

function SpaceShip()
    local weaponStorageMax = {
        hvli = 0,
        homing = 0,
        mine = 0,
        nuke = 0,
        emp = 0,
    }
    local weaponStorage = {
        hvli = 0,
        homing = 0,
        mine = 0,
        nuke = 0,
        emp = 0,
    }
    return Util.mergeTables(eeShipTemplateBasedMock(), {
        getWeaponStorageMax = function(self, weapon)
            if weaponStorageMax[weapon] == nil then error("Invalid weapon type " .. weapon, 2) end
            return weaponStorageMax[weapon]
        end,
        setWeaponStorageMax = function(self, weapon, amount)
            if weaponStorageMax[weapon] == nil then error("Invalid weapon type " .. weapon, 2) end
            weaponStorageMax[weapon] = math.max(0, amount)
            if weaponStorage[weapon] > weaponStorageMax[weapon] then weaponStorage[weapon] = weaponStorageMax[weapon] end
            return self
        end,
        getWeaponStorage = function(self, weapon)
            if weaponStorage[weapon] == nil then error("Invalid weapon type " .. weapon, 2) end
            return weaponStorage[weapon]
        end,
        setWeaponStorage = function(self, weapon, amount)
            if weaponStorage[weapon] == nil then error("Invalid weapon type " .. weapon, 2) end
            weaponStorage[weapon] = math.max(0, math.min(amount, weaponStorageMax[weapon]))
        end,
    })
end

function eeStationMock()
    return Util.mergeTables(eeShipTemplateBasedMock(), {
        typeName = "SpaceStation",
    })
end

function eeCpuShipMock()
    local order, orderTarget, orderX, orderY = "Idle", nil, nil, nil

    return Util.mergeTables(SpaceShip(), {
        orderIdle = function(self)
            order, orderTarget, orderX, orderY = "Idle", nil, nil, nil
            return self
        end,
        orderRoaming = function(self)
            order, orderTarget, orderX, orderY = "Roaming", nil, nil, nil
            return self
        end,
        orderStandGround = function(self)
            order, orderTarget, orderX, orderY = "Stand Ground", nil, nil, nil
            return self
        end,
        orderDefendLocation = function(self, x, y)
            order, orderTarget, orderX, orderY = "Defend Location", nil, x, y
            return self
        end,
        orderDefendTarget = function(self, target)
            order, orderTarget, orderX, orderY = "Defend Target", target, nil, nil
            return self
        end,
        orderFlyFormation = function(self, target, x, y)
            order, orderTarget, orderX, orderY = "Fly in formation", target, x, y
            return self
        end,
        orderFlyTowards = function(self, x, y)
            order, orderTarget, orderX, orderY = "Fly towards", nil, x, y
            return self
        end,
        orderFlyTowardsBlind = function(self, x, y)
            order, orderTarget, orderX, orderY = "Fly towards (ignore all)", nil, x, y
            return self
        end,
        orderAttack = function(self, target)
            order, orderTarget, orderX, orderY = "Attack", target, nil, nil
            return self
        end,
        orderDock = function(self, target)
            order, orderTarget, orderX, orderY = "Dock", target, nil, nil
            return self
        end,
        getOrder = function(self) return order end,
        getOrderTargetLocation = function(self) return orderX, orderY end,
        getOrderTargetLocationX = function(self) return orderX end,
        getOrderTargetLocationY = function(self) return orderY end,
        getOrderTarget = function(self) return orderTarget end,

        typeName = "CpuShip",
    })
end

function eePlayerMock()
    local repairCrewCount = 0
    local playerButtons = {}
    local getButton = function(pos, label)
        for _, button in pairs(playerButtons) do
            if button.pos == pos and button.label == label then return button end
        end
    end
    local infoByPos = {}

    return Util.mergeTables(SpaceShip(), {
        typeName = "PlayerSpaceship",
        addCustomMessage = noop,
        commandMainScreenOverlay = noop,
        addCustomButton = function(self, pos, id, label, callback)
            playerButtons[id] = {
                pos = pos,
                id = id,
                label = label,
                callback = callback or nil
            }
            return self
        end,
        addCustomInfo = function(self, pos, id, label)
            infoByPos[pos] = label
            return self
        end,
        getCustomInfo = function(self, pos)
            return infoByPos[pos]
        end,
        closeCustomInfo = function(self, pos)
            infoByPos[pos] = nil
            return self
        end,
        removeCustom = function(self, id) playerButtons[id] = nil; return self end,
        hasButton = function(self, pos, label)
            return getButton(pos, label) ~= nil
        end,
        clickButton = function(self, pos, label)
            local button = getButton(pos, label)
            if button == nil then error("Button with label \"" .. label .. "\" for position " .. pos .. " does not exist.", 2) end
            if button.callback == nil then error("Button with label \"" .. label .. "\" for position " .. pos .. " does not have a callback.", 2) end
            return button.callback()
        end,
        getButtonLabel = function(self, pos, id)
            local button = getButton(pos, label)
            if button == nil then error("Button with label \"" .. label .. "\" for position " .. pos .. " does not exist.", 2) end
            return button.label
        end,
        setRepairCrewCount = function(self, count) repairCrewCount = count; return self end,
        getRepairCrewCount = function() return repairCrewCount end,
    })
end

function Artifact()
    return Util.mergeTables(SpaceShip(), {
        typeName = "Artifact",
        setModel = function(self) return self end,
        allowPickup = function(self) return self end,
    })
end

function ElectricExplosionEffect()
    return Util.mergeTables(SpaceObject(), {
        setSize = noop,
    })
end

function personMock()
    return {
        getFormalName = function() return "Johnathan Doe" end,
        getNickName = function() return "John" end
    }
end

function missionMock()
    return Mission:new()
end

function missionWithBrokerMock(broker)
    local mission = missionMock()
    Mission:withBroker(mission, "Hello World")
    mission:setMissionBroker(broker or eeStationMock())

    return mission
end

function acceptedMissionWithBrokerMock(broker, player)
    local mission = missionWithBrokerMock(broker, player)
    mission:accept()
    return mission
end

function declinedMissionWithBrokerMock(broker, player)
    local mission = missionWithBrokerMock(broker, player)
    mission:decline()
    return mission
end

function startedMissionWithBrokerMock(broker, player)
    local mission = acceptedMissionWithBrokerMock(broker, player)
    mission:start()
    return mission
end

function failedMissionWithBrokerMock(broker, player)
    local mission = startedMissionWithBrokerMock(broker, player)
    mission:fail()
    return mission
end

function successfulMissionWithBrokerMock(broker, player)
    local mission = startedMissionWithBrokerMock(broker, player)
    mission:success()
    return mission
end

function commsScreenMock()
    return Comms.screen("Hi there, stranger.")
end
function commsScreenReplyMock()
    return Comms.reply("Click me", nil)
end

function narrativeMock(name)
    return {
        name = name or Util.randomUuid()
    }
end

function productMock()
    local id = Util.randomUuid()
    return Product:new(id, {id = id})
end

function upgradeMock()
    return BrokerUpgrade:new({
        name = "Foobar",
        onInstall = function() end,
    })
end

function fleetMock(ships)
    return Fleet:new(ships)
end
