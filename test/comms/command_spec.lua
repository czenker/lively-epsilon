insulate("Comms", function()
    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local requiredConfig = {
        label = "Hello World",
        commandScreen = function() end,
        defendScreen = function() end,
        defendConfirmScreen = function() end,
        attackScreen = function() end,
        attackConfirmScreen = function() end,
        navigationScreen = function() end,
        navigationConfirmScreen = function() end,
    }

    describe("commandFactory()", function()
        it("should create a valid Comms.reply", function()
            local commandComms = Comms:commandFactory(requiredConfig)

            assert.is_true(Comms.isReply(commandComms))
        end)
        it("fails if any of the required configs is missing", function()
            for k, _ in pairs(requiredConfig) do
                local config = Util.deepCopy(requiredConfig)
                config[k] = nil

                assert.has_error(function() Comms:commandFactory(config) end)
            end
        end)
    end)
end)