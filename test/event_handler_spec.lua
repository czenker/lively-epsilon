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

        eh:register("test", function() result = result .. "d" end)
        eh:register("test", function() result = result .. "e" end)
        eh:register("test", function() result = result .. "f" end)

        result = ""
        eh:fire("test")
        assert.is.equal("abcdef", result)

        eh:register("test", function() result = result .. "g" end)
        eh:register("test", function() result = result .. "h" end)
        eh:register("test", function() result = result .. "i" end)

        result = ""
        eh:fire("test")
        assert.is.equal("abcdefghi", result)
    end)

    it("gives an additional argument to fire() to the listeners", function()
        local secret = "Hello World"
        local gottenArgument
        local eh = EventHandler:new()

        eh:register("test", function(self, argument) gottenArgument = argument end)
        eh:fire("test", secret)

        assert.is.equal(secret, gottenArgument)
    end)

    it("allows subsequent listener to modify the argument", function()
        local secret = {name=""}

        local eh = EventHandler:new()

        eh:register("test", function(self, argument) argument.name = argument.name .. "a" end)
        eh:register("test", function(self, argument) argument.name = argument.name .. "b" end)
        eh:register("test", function(self, argument) argument.name = argument.name .. "c" end)

        eh:fire("test", secret)

        assert.is.equal("abc", secret.name)
    end)

    describe("allows to limit events (in order to prevent typos)", function()
        it("allows to register and fire events from the whitelist", function()
            local eh = EventHandler:new({allowedEvents = {"foo"}})
            eh:register("foo", function() end)
        end)
        it("fails if a different event is registered", function()
            local eh = EventHandler:new({allowedEvents = {"foo"}})
            assert.has_error(function()
                eh:register("bar", function() end)
            end)
        end)
        it("fails if the config does not contain a table", function()
            assert.has_error(function()
                EventHandler:new({allowedEvents = 42})
            end)
        end)
        it("fails if the config does not contain strings", function()
            assert.has_error(function()
                EventHandler:new({allowedEvents = {"foo", "bar", 42}})
            end)
        end)
    end)

    describe("setting priority", function()
        it("allows to set priority of events", function()
            local result = ""
            local eh = EventHandler:new()

            eh:register("test", function() result = result .. "b" end, 20)
            eh:register("test", function() result = result .. "c" end, 30)
            eh:register("test", function() result = result .. "a" end, 10)

            eh:fire("test")
            assert.is.equal("abc", result)
        end)
        it("default priority is 0", function()
            local result = ""
            local eh = EventHandler:new()

            eh:register("test", function() result = result .. "b" end)
            eh:register("test", function() result = result .. "c" end, 10)
            eh:register("test", function() result = result .. "a" end, -10)

            eh:fire("test")
            assert.is.equal("abc", result)
        end)
        it("can handle a mix of priorities and registration order", function()
            local result = ""
            local eh = EventHandler:new()

            eh:register("test", function() result = result .. "c" end)
            eh:register("test", function() result = result .. "g" end, 50)
            eh:register("test", function() result = result .. "a" end, -10)
            eh:register("test", function() result = result .. "h" end, 50)
            eh:register("test", function() result = result .. "d" end)
            eh:register("test", function() result = result .. "b" end, -10)
            eh:register("test", function() result = result .. "f" end, 20)
            eh:register("test", function() result = result .. "e" end)

            eh:fire("test")
            assert.is.equal("abcdefgh", result)
        end)
    end)


    describe("new()", function()
        it("fails if config is not a table", function()
            assert.has_error(function()
                EventHandler:new(42)
            end)
        end)
    end)

    describe("register()", function()
        it("fails if eventName is not a string", function()
            local eh = EventHandler:new()
            assert.has_error(function()
                eh:register(42, function() end)
            end)
        end)
        it("fails if eventName is not given", function()
            local eh = EventHandler:new()
            assert.has_error(function()
                eh:register()
            end)
        end)
        it("fails if handler is not a function", function()
            local eh = EventHandler:new()
            assert.has_error(function()
                eh:register("foo", "invalid")
            end)
        end)
        it("fails if handler is not given", function()
            local eh = EventHandler:new()
            assert.has_error(function()
                eh:register("foo")
            end)
        end)
        it("fails if priority is not a number", function()
            local eh = EventHandler:new()
            assert.has_error(function()
                eh:register("foo", function() end, "foo")
            end)
        end)
    end)
    
    describe("fire()", function()
        it("fails if eventName is not a string", function()
            assert.has_error(function()
                EventHandler:new():fire(42)
            end)
        end)
        it("fails if no eventName is given", function()
            assert.has_error(function()
                EventHandler:new():fire()
            end)
        end)

        it("passes if no event is registered", function()
            EventHandler:new():fire("test")
        end)
    end)
end)