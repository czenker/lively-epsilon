insulate("EventHandler", function()
    require "lively_epsilon"
    require "test.mocks"

    it("allow to register a listener", function()
        local called = 0
        local eh = EventHandler:new()
        eh:register("test", function() called = called + 1 end)

        eh:fire("test")
        assert.is.equal(1, called)
    end)

    it("allow to register multiple listeners to the event", function()
        local called = 0
        local eh = EventHandler:new()

        eh:register("test", function() called = called + 1 end)
        eh:register("test", function() called = called + 2 end)

        eh:fire("test")
        assert.is.equal(3, called)
    end)

    it("calls the listeners in the order they where registered", function()
        local result = ""
        local eh = EventHandler:new()

        eh:register("test", function() result = result .. "a" end)
        eh:register("test", function() result = result .. "b" end)
        eh:register("test", function() result = result .. "c" end)

        eh:fire("test")
        assert.is.equal("abc", result)
    end)

    describe("register()", function()
        it("fails if eventName is not a string", function()
            assert.has_error(function()
                EventHandler:new():register(42, function() end)
            end)
        end)
        it("fails if handler is not a function", function()
            assert.has_error(function()
                EventHandler:new():register("foo", "invalid")
            end)
        end)
    end)
    
    describe("fire()", function()
        it("fails if eventName is not a string", function()
            assert.has_error(function()
                EventHandler:new():fire(42)
            end)
        end)

        it("passes if no event is registered", function()
            EventHandler:new():fire("test")
        end)
    end)
end)