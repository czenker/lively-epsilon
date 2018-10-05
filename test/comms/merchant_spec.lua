insulate("Comms", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    local requiredConfig = {
        label = "Hello World",
        mainScreen = function() end,
        buyScreen = function() end,
        buyProductScreen = function() end,
        buyProductConfirmScreen = function() end,
        sellScreen = function() end,
        sellProductScreen = function() end,
        sellProductConfirmScreen = function() end,
    }

    describe("merchantFactory()", function()
        it("should create a valid Comms.reply", function()
            local merchantComms = Comms:merchantFactory(requiredConfig)

            assert.is_true(Comms.isReply(merchantComms))
        end)
        it("fails if any of the required configs is missing", function()
            for k, _ in pairs(requiredConfig) do
                local config = Util.deepCopy(requiredConfig)
                config[k] = nil

                assert.has_error(function() Comms:merchantFactory(config) end)
            end
        end)
    end)
end)