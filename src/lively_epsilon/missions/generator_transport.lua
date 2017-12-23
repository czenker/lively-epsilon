function MissionGenerator.transport(from, to)
    if not isEeStation(from) then
        error("InvalidArgument: 'from' needs to be SpaceStation to call transport", 2)
    end
    if not isEeStation(to) then
        error("InvalidArgument: 'to' needs to be SpaceStation to call transport", 2)
    end

    -- @TODO: randomize
    local cargo = "Red Herrings"

    return {
        -- meta to allow this mission to be accepted
        id = Util.randomUuid(),
        title = "Ship " .. cargo .. " to " .. to:getCallSign(),
        description = "It is very important that the Red Herrings are shipped without harming them. We can't offer payment at the moment, but the feeling of having done a good deed should be enough of a reward.",
        acceptMessage = "Thanks for taking care of this transport mission. We brought the cargo to your ships storage already.",

        --

        acceptReminder = "shipment for " .. to:getCallSign(),
        completeLog = cargo .. " shipped successfuly",
        player = nil,

        start = function(self, player)
            player:logMission(self.title)
            player:addCustomInfo("relay", self.id, self.acceptReminder)

            self.player = player

            Cron.regular(self.id, function()
                self:update()
            end, 1)
        end,

        update = function(self)
            if self.player:isDocked(to) then
                self.player:logMission(self.completeLog)
                self:stop()
            end
        end,

        stop = function(self)
            -- cleanup
            if self.player ~= nil then
                if self.player.mission == self then
                    self.player.mission = nil
                end
                self.player:removeCustom(self.id)
            end
            Cron.abort(self.id)
        end
    }

end