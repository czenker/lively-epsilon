function MissionGenerator.transport(from, to)
    if not isEeStation(from) then
        error("InvalidArgument: 'from' needs to be SpaceStation to call transport", 2)
    end
    if not isEeStation(to) then
        error("InvalidArgument: 'to' needs to be SpaceStation to call transport", 2)
    end

    -- @TODO: randomize
    local cargo = "Rote Heringe"

    return {
        -- meta to allow this mission to be accepted
        id = Util.randomUuid(),
        title = "Transportiere " .. cargo .. " nach " .. to:getCallSign(),
        description = "Es ist super-wichtig, dass die Roten Heringe heil ankommen. Wir koennen Ihnen leider keine Bezahlung anbieten, aber das Gefuehl etwas Gutes getan zu haben sollte Belohnung genug fuer Sie sein.",
        acceptMessage = "Vielen Dank, dass sie sich um den Transportauftrag kuemmern. Wir haben die Waren in ihren Laderaum geladen.",

        --

        acceptReminder = "Transport nach " .. to:getCallSign(),
        completeLog = cargo .. " erfolgreich ausgeliefert",
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