insulate("Comms:missionBrokerFactory()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local requiredConfig = {
        label = "Hello World",
        mainScreen = function() end,
        detailScreen = function() end,
        acceptScreen = function() end,
    }

    it("should create a valid Comms:newReply", function()
        local missionComms = Comms:missionBrokerFactory(requiredConfig)

        assert.is_true(Comms:isReply(missionComms))
    end)
    it("fails if any of the required configs is missing", function()
        for k, _ in pairs(requiredConfig) do
            local config = Util.deepCopy(requiredConfig)
            config[k] = nil

            assert.has_error(function() Comms:missionBrokerFactory(config) end)
        end
    end)
end)