Player = Player or {}

--- add a quick dial panel to the relay station
--- @param self
--- @param player PlayerSpaceship
--- @param config table
---   @field label string the label for the menu item
--- @return PlayerSpaceship
Player.withQuickDial = function(self, player, config)
    if not isEePlayer(player) then error("Expected player to be a Player, but got " .. typeInspect(player), 2) end
    if not Player:hasMenu(player) then error("Expected player " .. player:getCallSign() .. " to have menus enabled, but it does not", 2) end
    if Player:hasQuickDial(player) then error("Player " .. player:getCallSign() .. " already has a upgrade display", 2) end
    config = config or {}
    if not isTable(config) then error("Expected config to be a table, but got " .. typeInspect(config), 2) end
    if not isString(config.label) then error("Expected label to be a string, but got " .. typeInspect(config.label), 2) end

    local quickDials = {}

    --- add a quick dial
    --- @param self
    --- @param ShipTemplateBased|Fleet any
    player.addQuickDial = function(self, thing)
        if isEeShipTemplateBased(thing) or Fleet:isFleet(thing) then
            table.insert(quickDials, thing)
        else
            error("Expected shipTemplateBased or fleet, but got " .. typeInspect(thing), 2)
        end
    end

    --- remove a quick dial
    --- @param self
    --- @param ShipTemplateBased|Fleet any
    player.removeQuickDial = function(self, thing)
        for i=1, #quickDials do
            if thing == quickDials[i] then quickDials[i] = nil end
        end
    end

    --- get quick dials
    --- @return table[ShipTemplateBased|Fleet]
    player.getQuickDials = function(self)
        local ret = {}
        for _, quickDial in pairs(quickDials) do
            if quickDial:isValid() then table.insert(ret, quickDial) end
        end
        return ret
    end

    player:addRelayMenuItem(Menu:newItem(config.label, function()
        local targets = {}
        for _, target in pairs(quickDials) do
            if isEeShipTemplateBased(target) and target:isValid() then
                table.insert(targets, target)
            elseif Fleet:isFleet(target) and target:isValid() then
                table.insert(targets, target:getLeader())
            end
        end

        table.sort(targets, function(a, b)
            if a:isValid() then a = a:getCallSign() else a = "" end
            if b:isValid() then b = b:getCallSign() else b = "" end
            return a < b
        end)

        local menu = Menu:new()
        menu:addItem(Menu:newItem(config.label, 0))
        for i, target in ipairs(targets) do
            menu:addItem("quick_dial_" .. i, Menu:newItem(target:getCallSign(), function()
                player:commandOpenTextComm(target)
            end, i))
        end

        return menu
    end))

    return player
end

--- check if the player has quick dials
--- @param self
--- @param player any
--- @return boolean
Player.hasQuickDial = function(self, player)
    return isTable(player) and
            isFunction(player.addQuickDial) and
            isFunction(player.removeQuickDial) and
            isFunction(player.getQuickDials)
end