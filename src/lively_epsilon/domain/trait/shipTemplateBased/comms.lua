ShipTemplateBased = ShipTemplateBased or {}

ShipTemplateBased.withComms = function (self, spaceObject)
    if not isEeShipTemplateBased(spaceObject) then
        error ("Expected a shipTemplateBased object but got " .. type(spaceObject), 2)
    end

    local comms = {}
    local theHailText

    spaceObject.setHailText = function(self, hailText)
        if not isString(hailText) and not isNil(hailText) and not isFunction(hailText) then
            error("hailText needs to be a string or a function", 2)
        end
        theHailText = hailText
    end

    spaceObject.getHailText = function(self)
        if isString(theHailText) then
            return theHailText
        elseif isFunction(theHailText) then
            local status, result = pcall(theHailText)
            if not status then
                if type(result) == "string" then
                    print("An error occured while getting the hailText: " .. result)
                else
                    print("An error occured while getting the hailText")
                end
            else
                return result
            end
        end
        return nil
    end

    spaceObject.addComms = function(self, playerSays, nextScreen, id)
        id = id or Util.randomUuid()
        comms[id] = { playerSays = playerSays, nextScreen = nextScreen }

        return id
    end

    spaceObject.getComms = function(self)
        return comms
    end

end