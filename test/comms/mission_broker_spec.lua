insulate("Comms", function()
    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local requiredConfig = {
        label = "Hello World",
        mainScreen = function() end,
        detailScreen = function() end,
        acceptScreen = function() end,
    }

    describe("missionBrokerFactory()", function()
        it("should create a valid Comms.reply", function()
            local missionComms = Comms:missionBrokerFactory(requiredConfig)

            assert.is_true(Comms.isReply(missionComms))
        end)
        it("fails if any of the required configs is missing", function()
            for k, _ in pairs(requiredConfig) do
                local config = Util.deepCopy(requiredConfig)
                config[k] = nil

                assert.has_error(function() Comms:missionBrokerFactory(config) end)
            end
        end)
    end)
end)