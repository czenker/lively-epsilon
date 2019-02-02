Missions = Missions or {}

--- Bring something to a station
---
--- This fills the storage on the ship
---
--- @param self
--- @param from SpaceStation
--- @param to SpaceStation
--- @param product Product
--- @param config table
---   @field amount number (default: `1`)
---   @field onLoad function(mission) When the product is loaded
---   @field onUnload function(mission)
---   @field onInsufficientStorage function(mission)
---   @field onProductLost function(mission)
--- @return Mission
Missions.transportProduct = function(self, from, to, product, config)
    if not isEeStation(from) then error("from needs to be a Station, but got " .. typeInspect(from), 2) end
    if not isEeStation(to) then error("to needs to be a Station, but got " .. typeInspect(to), 2) end
    if not Product:isProduct(product) then error("product needs to be a Product, but got " .. typeInspect(product), 2) end
    config = config or {}
    config.amount = config.amount or 1
    if not isTable(config) then error("Expected config to be a table, but " .. typeInspect(config) .. " given.", 2) end

    local isLoaded = false
    local cronId = Util.randomUuid()
    local isDockedOnFrom = false

    local mission
    mission = Mission:new({
        acceptCondition = function(self)
            local error
            if not Player:hasStorage(mission:getPlayer()) then
                error = "no_storage"
            elseif mission:getPlayer():getEmptyStorageSpace(product) < config.amount then
                error = "small_storage"
            end

            if isFunction(config.acceptCondition) then
                return config.acceptCondition(self, error)
            elseif error ~= nil then
                return error
            else
                return true
            end
        end,
        onAccept = config.onAccept,
        onDecline = config.onDecline,
        onStart = function(self)
            if isFunction(config.onStart) then config.onStart(self) end

            Cron.regular(cronId, function()
                if isLoaded == false then
                    if mission:getPlayer():isDocked(from) then
                        if Player:hasStorage(mission:getPlayer()) and mission:getPlayer():getEmptyProductStorage(product) >= config.amount then
                            if isFunction(config.onLoad) then config.onLoad(mission) end
                            mission:getPlayer():modifyProductStorage(product, config.amount)
                            isLoaded = true
                        elseif isDockedOnFrom == false and isFunction(config.onInsufficientStorage) then
                            config.onInsufficientStorage(mission)
                        end
                        isDockedOnFrom = true
                    else
                        isDockedOnFrom = false
                    end
                elseif Player:hasStorage(mission:getPlayer()) then
                    if mission:getPlayer():getProductStorage(product) < config.amount then
                        isLoaded = false
                        if isFunction(config.onProductLost) then config.onProductLost(mission) end
                        self:fail()
                    end
                    if mission:getPlayer():isDocked(to) then
                        if isFunction(config.onUnload) then config.onUnload(mission) end
                        mission:getPlayer():modifyProductStorage(product, -1 * config.amount)
                        isLoaded = false
                        self:success()
                    end
                end
            end, 0.2)
        end,
        onSuccess = config.onSuccess,
        onFailure = config.onFailure,
        onEnd = function(self)
            Cron.abort(cronId)
            if isFunction(config.onEnd) then config.onEnd(self) end
        end,
    })

    Mission:forPlayer(mission)

    --- @param self
    --- @return number
    mission.isLoaded = function(self) return isLoaded end

    --- @param self
    --- @return Product
    mission.getProduct = function(self) return product end

    --- @param self
    --- @return number
    mission.getAmount = function(self) return config.amount end

    return mission
end