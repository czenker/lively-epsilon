local noop = function(self) return self end

function _G.getObjectsInRadius() return {} end

local function mergeObjects(...)
    local merged = Util.mergeTables(table.unpack({...}))
    setmetatable(merged, Util.mergeTables(table.unpack(Util.map({...}, function(el) return getmetatable(el) end))))
    return merged
end

function SpaceObject()
    local callSign = ""
    local isValid = true
    local positionX, positionY = 0, 0
    local reputationPoints = 0
    local factionId = 0
    local faction = "Independent"
    local scannedState = "not" -- simplified version that does not take factions into account

    local obj = {
        setCallSign = function(self, sign)
            callSign = sign
            return self
        end,
        getCallSign = function() return callSign end,
        getSectorName = function(self) return "AA" end,
        isValid = function() return isValid end,
        destroy = function(self)
            isValid = false
            self:setCallSign(nil)
            return self
        end,
        getPosition = function() return positionX, positionY end,
        setPosition = function(self, x, y) positionX, positionY = x, y; return self end,
        getObjectsInRange = function(self) return {} end,
        areEnemiesInRange = noop,
        setReputationPoints = function(self, amount) reputationPoints = amount; return self end,
        getReputationPoints = function(self) return reputationPoints end,
        takeReputationPoints = function(self, amount) reputationPoints = math.max(0, reputationPoints - amount); return self end,
        addReputationPoints = function(self, amount) reputationPoints = reputationPoints + amount; return self end,
        getFactionId = function(self) return factionId end,
        setFactionId = function(self, id) factionId = id; return self end,
        setFaction = function(self, name) faction = name; return self end,
        getFaction = function(self) return faction end,
        isEnemy = function(self, other) return self:getFactionId() > 0 and other:getFactionId() > 0 and self:getFactionId() ~= other:getFactionId() end,
        isFriendly = function(self, other) return self:getFactionId() == other:getFactionId() end,
        isScannedBy = function(self, player)
            if not isEePlayer(player) then error("Mock only works for player", 2) end
            return scannedState == "simple"
        end,
        scannedByPlayer = function(self) scannedState = "simple" end,
        setDescription = noop,
        setDescriptionForScanState = noop,
        getDescription = function(self) return "" end,
        setDescriptions = noop,
        setScanningParameters = noop,
        setRadarSignatureInfo = noop,
        getRadarSignatureGravity = function(self) return 1 end,
        getRadarSignatureElectrical = function(self) return 1 end,
        getRadarSignatureBiological = function(self) return 1 end,
        sendCommsMessage = function(self, player, content)
            self:overrideComms(Comms:newScreen(content), true)
            local success = player:isCommsInactive()
            player:commandOpenTextComm(self)
            return success
         end,
        openCommsTo = function(self, player)
            player:commandOpenTextComm(self)
        end,
    }

    setmetatable(obj, {
        __index = function(table, key)
            if key:sub(1,3) == "set" then
                return noop
            end
        end
    })

    return obj
end
function ShipTemplateBasedObject()

    local hull = 50
    local hullMax = 50
    local repairDocked = false
    local shieldsMax = {}
    local shields = {}

    local normalizeShields = function()
        local newShields = {}
        for i,v in pairs(shieldsMax) do
            newShields[i] = math.min(shields[i] or v, v)
        end
        shields = newShields
    end

    local object = SpaceObject():setCallSign(Util.randomUuid())
    return mergeObjects(object, {
        setTemplate = noop,
        getShieldCount = function() return Util.size(shieldsMax) end,
        setShields = function(self, ...)
            shields = {...}
            normalizeShields()
            return self
        end,
        setShieldsMax = function(self, ...)
            shieldsMax = {...}
            normalizeShields()
            return self
        end,
        getShieldLevel = function(_, id)
            return shields[id + 1]
        end,
        getShieldMax = function(_, id)
            return shieldsMax[id + 1]
        end,
        setCommsScript = noop,
        setHullMax = function(self, amount)
            hullMax = amount
            hull = math.min(hull, amount)
            return self
        end,
        setHull = function(self, amount)
            hull = math.min(amount, hullMax)
            return self
        end,
        getHull = function() return hull end,
        getHullMax = function() return hullMax end,
        getRepairDocked = function() return repairDocked end,
        setRepairDocked = function(self, value) repairDocked = value; return self end,
        setCanBeDestroyed = noop,
    })
end

function SpaceShip()
    local scannedState = "not" -- simplified version that does not take factions into account
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
    local docked

    local systemPower = {}
    local systemCoolant = {}
    local systemHealth = {}

    local hasJumpDrive, hasWarpDrive = false, false

    return mergeObjects(ShipTemplateBasedObject(), {
        typeName = "SpaceShip",
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
            return self
        end,
        getBeamWeaponArc = function(index) return 42 end,
        getBeamWeaponDirection = function(index) return 42 end,
        getBeamWeaponRange = function(index) return 42 end,
        getBeamWeaponTurretArc = function(index) return 42 end,
        getBeamWeaponTurretDirection = function(index) return 42 end,
        getBeamWeaponCycleTime = function(index) return 42 end,
        getBeamWeaponDamage = function(index) return 42 end,
        getBeamWeaponEnergyPerFire = function(index) return 42 end,
        getBeamWeaponHeatPerFire = function(index) return 42 end,
        isFriendOrFoeIdentifiedBy = function(self, player)
            if not isEePlayer(player) then error("Mock only works for player", 2) end
            return scannedState ~= "not"
        end,
        isScannedBy = function(self, player)
            if not isEePlayer(player) then error("Mock only works for player", 2) end
            return scannedState == "simple" or scannedState == "full"
        end,
        isFullyScannedBy = function(self, player)
            if not isEePlayer(player) then error("Mock only works for player", 2) end
            return scannedState == "full"
        end,
        notScannedByPlayer = function(self) scannedState = "not"; return self end,
        friendOrFoeIdentifiedByPlayer = function(self) scannedState = "friendorfoeidentified"; return self end,
        scannedByPlayer = function(self) scannedState = "simple" end,
        fullScannedByPlayer = function(self) scannedState = "full"; return self end,
        setDockedAt = function(self, station) docked = station end,
        isDocked = function(self, station) return station == docked end,
        setSystemHealth = function(self, system, health)
            systemHealth[system] = math.min(math.max(health, -1), 1)
            return self
        end,
        getSystemHealth = function(self, system)
            return systemHealth[system] or 1
        end,
        setSystemPower = function(self, system, power)
            systemPower[system] = power
            return self
        end,
        getSystemPower = function(self, system)
            return systemPower[system] or 1
        end,
        setSystemCoolant = function(self, system, power)
            systemCoolant[system] = power
            return self
        end,
        getSystemCoolant = function(self, system)
            return systemCoolant[system] or 0
        end,
        hasJumpDrive = function(self)
            return hasJumpDrive
        end,
        setJumpDrive = function(self, has)
            hasJumpDrive = has
            return self
        end,
        hasWarpDrive = function(self)
            return hasWarpDrive
        end,
        setWarpDrive = function(self, has)
            hasWarpDrive = has
            return self
        end,
        setImpulseMaxSpeed = noop,
        setRotationMaxSpeed = noop,
    })
end

function SpaceStation()
    return mergeObjects(ShipTemplateBasedObject(), {
        typeName = "SpaceStation",
    })
end

function CpuShip()
    local order, orderTarget, orderX, orderY = "Idle", nil, nil, nil

    return mergeObjects(SpaceShip(), {
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
        getOrderTarget = function(self)
            if isEeObject(orderTarget) and orderTarget:isValid() then
                return orderTarget
            end
            return nil
        end,

        typeName = "CpuShip",
    })
end

function PlayerSpaceship()
    local repairCrewCount = 0
    local playerButtons = {}
    local getButton = function(pos, label)
        for _, button in pairs(playerButtons) do
            if button.pos == pos and button.label == label then return button end
        end
    end
    local lastCustomMessage = {}
    local currentCommsScreen = nil
    local currentCommsTarget = nil
    local maxNumberScanProbes = 8
    local numberScanProbes = 8
    local shortRangeRadarRange = 5000
    local longRangeRadarRange = 30000

    local player = {
        typeName = "PlayerSpaceship",
        addCustomMessage = function(self, position, _, caption)
            lastCustomMessage[position] = caption
            return self
        end,
        hasCustomMessage = function(self, position)
            return lastCustomMessage[position] ~= nil
        end,
        getCustomMessage = function(self, position)
            return lastCustomMessage[position]
        end,
        closeCustomMessage = function(self, position)
            if self:getCustomMessage(position) == nil then error("There was no custom message open for " .. position) end
            lastCustomMessage = nil
            return self
        end,
        commandMainScreenOverlay = noop,
        addCustomButton = function(self, pos, id, label, callback)
            playerButtons[id] = {
                pos = pos,
                id = id,
                label = label,
                callback = callback or nil,
            }
            return self
        end,
        addCustomInfo = function(self, pos, id, label)
            playerButtons[id] = {
                pos = pos,
                id = id,
                label = label,
                callback = nil,
            }
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
        commandSetSystemPowerRequest = function(self, system, power) return self:setSystemPower(system, power) end,
        commandSetSystemCoolantRequest = function(self, system, coolant) return self:setSystemCoolant(system, coolant) end,
        addToShipLog = noop,
        commandOpenTextComm = function(self, target)
            currentCommsScreen = target:getComms(self)
            currentCommsTarget = target
            return self
        end,
        commandCloseTextComm = function(self)
            currentCommsScreen = nil
            currentCommsTarget = nil
            return self
        end,
        isCommsInactive = function(self)
            return currentCommsScreen == nil and currentCommsTarget == nil
        end,
        hasComms = function(self, label)
            if currentCommsScreen == nil then error("There is currently no comms open.", 2) end
            for _, reply in pairs(currentCommsScreen:getHowPlayerCanReact()) do
                if reply:getWhatPlayerSays(currentCommsTarget, self) == label and reply:checkCondition(currentCommsTarget, self) == true then
                    return true
                end
            end
            return false
        end,
        selectComms = function(self, label)
            if currentCommsScreen == nil then error("There is currently no comms open.", 2) end
            local labels = {}
            for _, reply in pairs(currentCommsScreen:getHowPlayerCanReact()) do
                local theLabel = reply:getWhatPlayerSays(currentCommsTarget, self)
                table.insert(labels, theLabel)
                if theLabel == label then
                    if not reply:checkCondition(currentCommsTarget, self) then
                        error("The button labeled \"" .. label .. "\" exists, but is not displayed, because the display condition is not met.", 2)
                    else
                        local next = reply:getNextScreen(currentCommsTarget, self)
                        if Comms:isScreen(next) then
                            currentCommsScreen = next
                            return
                        elseif isNil(next) then
                            currentCommsScreen = currentCommsTarget:getComms(self)
                            return
                        else
                            error("Expected comms labeled \"" .. label .. "\" to return a screen or nil, but got " .. typeInspect(next), 2)
                        end
                    end
                end
            end

            error("Did not find a Reply labeled \"" .. label .. "\". Valid labels: " .. Util.mkString(Util.map(labels, function(el) return "\"" .. el .. "\"" end), ", ", " and "))
        end,
        getCurrentCommsScreen = function(self)
            return currentCommsScreen
        end,
        getCurrentCommsText = function(self)
            if currentCommsScreen == nil then error("There is currently no comms open.", 2) end
            return currentCommsScreen:getWhatNpcSays(currentCommsTarget, self)
        end,
        getScanProbeCount = function(self)
            return numberScanProbes
        end,
        getMaxScanProbeCount = function(self)
            return maxNumberScanProbes
        end,
        setScanProbeCount = function(self, amount)
            numberScanProbes = math.min(math.max(0, amount), maxNumberScanProbes)
        end,
        setMaxScanProbeCount = function(self, amount)
            maxNumberScanProbes = math.max(0, amount)
            numberScanProbes = math.min(numberScanProbes, maxNumberScanProbes)
        end,
        setShortRangeRadarRange = function(self, range)
            shortRangeRadarRange = range
            return self
        end,
        getShortRangeRadarRange = function(self)
            return shortRangeRadarRange
        end,
        setLongRangeRadarRange = function(self, range)
            longRangeRadarRange = range
            return self
        end,
        getLongRangeRadarRange = function(self)
            return longRangeRadarRange
        end,
    }

    setmetatable(player, {
        __index = function(table, key)
            if key:sub(1,3) == "set" or key:sub(1,7) == "command" then
                return noop
            elseif key:sub(1,2) == "is" then
                return function() return false end
            end
        end
    })

    return mergeObjects(SpaceShip(), player)

end

function Artifact()
    local onPickUpCallback

    return mergeObjects(SpaceObject(), {
        typeName = "Artifact",
        setModel = function(self) return self end,
        allowPickup = function(self) return self end,
        onPickUp = function(self, callback)
            onPickUpCallback = callback
            return self
        end,
        pickUp = function(self, player)
            if isFunction(onPickUpCallback) then onPickUpCallback(self, player) end
            self:destroy()
        end,
    })
end

function Asteroid()
    return mergeObjects(SpaceObject(), {
        typeName = "Asteroid",
    })
end

function ExplosionEffect()
    return mergeObjects(SpaceObject(), {
        setSize = noop,
    })
end

function ElectricExplosionEffect()
    return mergeObjects(SpaceObject(), {
        setSize = noop,
    })
end

function WarpJammer()
    return mergeObjects(SpaceObject(), {
        typeName = "WarpJammer",
        setRange = noop,
    })
end

function ScanProbe()
    return mergeObjects(SpaceObject(), {
        typeName = "ScanProbe",
        setRange = noop,
    })
end

function SupplyDrop()
    local onPickUpCallback

    return mergeObjects(SpaceObject(), {
        typeName = "SupplyDrop",
        setEnergy = noop,
        onPickUp = function(self, callback)
            onPickUpCallback = callback
            return self
        end,
        pickUp = function(self, player)
            if isFunction(onPickUpCallback) then onPickUpCallback(self, player) end
            self:destroy()
        end,
    })
end

function Planet()
    return mergeObjects(SpaceObject(), {
        typeName = "Planet",
        setPlanetAtmosphereColor = noop,
        setPlanetAtmosphereTexture = noop,
        setPlanetSurfaceTexture = noop,
        setPlanetCloudTexture = noop,
        setPlanetRadius = noop,
        setPlanetCloudRadius = noop,
        setDistanceFromMovementPlane = noop,
        setAxialRotationTime = noop,
        setOrbit = noop,
    })
end
function Nebula()
    return mergeObjects(SpaceObject(), {
        typeName = "Nebula",
    })
end
function Mine()
    return mergeObjects(SpaceObject(), {
        typeName = "Mine",
    })
end
function WormHole()
    local targetX, targetY = 0, 0

    return mergeObjects(SpaceObject(), {
        typeName = "WormHole",
        setTargetPosition = function(self, x, y)
            targetX, targetY = x, y
            return self
        end,
        getTargetPosition = function(self)
            return targetX, targetY
        end,
        onTeleportation = noop,
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
    mission:setMissionBroker(broker or SpaceStation())

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
    return Comms:newScreen("Hi there, stranger.")
end
function commsScreenReplyMock()
    return Comms:newReply("Click me", nil)
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

function mockOrder()
    local order = Order:_generic()

    order.getShipExecutor = function()
        return {
            go = noop,
            tick = noop,
        }
    end
    order.getFleetExecutor = function()
        return {
            go = noop,
            tick = noop,
        }
    end

    assert(Order:isOrder(order))

    return order
end

function mockChatter()
    local lastSender, lastMessage, lastMessages
    local chatter = {
        say = function(_, sender, message)
            lastSender, lastMessage = sender, message
        end,
        converse = function(_, messages)
            lastMessages = messages
        end,
        getLastSender = function() return lastSender end,
        getLastMessage = function() return lastMessage end,
        getLastMessages = function() return lastMessages end,
    }

    assert(Chatter:isChatter(chatter))

    return chatter
end

function mockChatFactory()

    local chatFactory = Chatter:newFactory(1, function(one)
        return {
            {one, "Hello World"}
        }
    end)

    assert(Chatter:isChatFactory(chatFactory))

    return chatFactory
end

function mockMenuLabel(label, pos)
    label = label or "Hello World"

    local item = Menu:newItem(label, pos)

    assert(Menu:isMenuItem(item))

    return item
end

function mockMenu()
    local menu = Menu:new()

    assert(Menu:isMenu(menu))

    return menu
end

function mockSubmenu(label, subMenuCallback, pos)
    label = label or "Submenu"

    local item = Menu:newItem(label, function()
        local menu = mockMenu()
        if isFunction(subMenuCallback) then subMenuCallback(menu) end
        return menu
    end, pos)

    assert(Menu:isMenuItem(item))

    return item
end

function mockMenuItemWithSideEffects(label, pos)
    label = label or "Side Effects"

    local item = Menu:newItem(label, function()
        -- do something and return nil
    end, pos)

    assert(Menu:isMenuItem(item))

    return item
end