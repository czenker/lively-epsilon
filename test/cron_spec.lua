insulate("Cron", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("once()", function()
        it("will call a function after a certain time", function()
            local called = false
            Cron.once(function() called = true end, 5)

            assert.is_false(called)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(called)
            Cron.tick(1)
            assert.is_true(called)
        end)

        it("will call the function only once", function()
            local called = 0
            Cron.once(function() called = called + 1 end, 1)

            assert.is_same(0, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(1, called)
        end)

        it("will call a function with a name", function()
            local called = false
            Cron.once("foobar", function() called = true end, 5)

            assert.is_false(called)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(called)
            Cron.tick(1)
            assert.is_true(called)
        end)

        it("is possible to remove a function with a name", function()
            local called = false
            Cron.once("foobar", function() called = true end, 5)

            assert.is_false(called)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(called)

            Cron.abort("foobar")

            Cron.tick(1)
            assert.is_false(called)
        end)

        it("is possible to remove a function with a generated name", function()
            local called = false
            local cronId = Cron.once(function() called = true end, 5)

            assert.is_false(called)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_false(called)

            Cron.abort(cronId)

            Cron.tick(1)
            assert.is_false(called)
        end)

        it("allows to replace a once with regular on call", function()
            local called = 0
            Cron.once("foobar", function()
                called = called + 1
                Cron.regular("foobar", function()
                    called = called + 1
                end, 1)
            end, 1)

            assert.is_same(0, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(2, called)
            Cron.tick(1)
            assert.is_same(3, called)
        end)

        it("allows to set a new callback after removing the current one", function()
            local i = 0
            local fun
            fun = function()
                i = i+1
                if i < 10 then Cron.once(fun, 1) end
            end
            Cron.once(fun, 1)
            assert.not_has_error(function()
                for i=1,10 do Cron.tick(1) end
            end)
        end)

        it("allows to remove a callback by calling one callback", function()
            local ids = {
                "foo",
                "bar",
            }
            for _, id in pairs(ids) do
                Cron.once(id, function()
                    for _, id in pairs(ids) do
                        Cron.abort(id)
                    end
                end, 1)
            end
            assert.not_has_error(function()
                Cron.tick(1)
            end)
        end)

    end)

    describe("regular()", function()
        it("will call a function at a regular interval", function()
            local called = 0
            Cron.regular("foobar", function() called = called + 1 end, 2)

            assert.is_same(0, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(2, called)
            Cron.tick(1)
            assert.is_same(2, called)
            Cron.tick(1)
            assert.is_same(3, called)
            Cron.tick(1)
            assert.is_same(3, called)
        end)

        it("will call a function at a regular interval with delay", function()
            local called = 0
            Cron.regular("foobar", function() called = called + 1 end, 2, 2)

            assert.is_same(0, called)
            Cron.tick(1)
            assert.is_same(0, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(2, called)
            Cron.tick(1)
            assert.is_same(2, called)
            Cron.tick(1)
            assert.is_same(3, called)
        end)

        it("a function can remove itself", function()
            local called = 0
            Cron.regular("foobar", function()
                if called >= 3 then Cron.abort("foobar") else called = called + 1 end
            end, 1)

            assert.is_same(0, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(2, called)
            Cron.tick(1)
            assert.is_same(3, called)
            Cron.tick(1)
            assert.is_same(3, called)
            Cron.tick(1)
            assert.is_same(3, called)
        end)

        it("a function can be stopped from outside", function()
            local called = 0
            local cronId = Cron.regular(function() called = called + 1 end, 1)

            assert.is_same(0, called)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.abort(cronId)
            Cron.tick(1)
            assert.is_same(1, called)
            Cron.tick(1)
            assert.is_same(1, called)
        end)

        it("the function gets its id as first parameter", function()
            local theFirstParameter
            Cron.regular("foobar", function(cronId)
                theFirstParameter = cronId
            end, 1)

            Cron.tick(1)
            assert.is_same("foobar", theFirstParameter)
        end)

        it("the function gets its generated id as first parameter", function()
            local theFirstParameter
            Cron.regular(function(cronId)
                theFirstParameter = cronId
            end, 1)

            Cron.tick(1)
            assert.not_nil(theFirstParameter)
            assert.is_string(theFirstParameter)
            assert.not_same("", theFirstParameter)
        end)

        it("allows the callback function to return the interval for the next try", function()
            local called = 0

            Cron.regular("foobar", function()
                called = called + 1
                if called == 2 then return 3 end
            end, 1)

            assert.is_same(0, called)

            Cron.tick(0.5)
            assert.is_same(1, called)

            Cron.tick(1)
            assert.is_same(2, called)

            Cron.tick(1)
            assert.is_same(2, called)

            Cron.tick(1)
            assert.is_same(2, called)

            Cron.tick(1)
            assert.is_same(3, called)

            Cron.tick(1)
            assert.is_same(4, called)
        end)
    end)

    describe("getDelay()", function()
        it("returns nil for an undefined cron", function()
            assert.is_nil(Cron.getDelay("doesnotexist"))
        end)

        it("allows to get the delay until the next call of function when using regular()", function()
            Cron.regular("foobar", function() end, 3, 5)

            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(3, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(2, Cron.getDelay("foobar"))
        end)

        it("allows to get the delay until the call of function when using once()", function()
            Cron.once("foobar", function() end, 5)

            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(1, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_nil(Cron.getDelay("foobar"))
        end)
    end)

    describe("setDelay()", function()
        it("fails silently when an unknown Cron is set", function()
            Cron.setDelay("doesnotexist", 5)
            assert.is_nil(Cron.getDelay("doesnotexist"))
        end)

        it("allows to override the delay of a regular", function()
            Cron.regular("foobar", function() end, 3, 5)

            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.setDelay("foobar", 5)
            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(3, Cron.getDelay("foobar"))
            Cron.setDelay("foobar", 5)
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
        end)

        it("allows to set the delay when using once()", function()
            Cron.once("foobar", function() end, 5)

            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.setDelay("foobar", 5)
            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.tick(1)
        end)
    end)

    describe("addDelay()", function()
        it("fails silently when an unknown Cron is set", function()
            Cron.addDelay("doesnotexist", 5)
            assert.is_nil(Cron.getDelay("doesnotexist"))
        end)

        it("allows to override the delay of a regular", function()
            Cron.regular("foobar", function() end, 3, 5)

            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.addDelay("foobar", 1)
            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            Cron.tick(1)
            assert.is_same(3, Cron.getDelay("foobar"))
            Cron.addDelay("foobar", 2)
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
        end)

        it("allows to set the delay when using once()", function()
            Cron.once("foobar", function() end, 5)

            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.addDelay("foobar", 1)
            assert.is_same(5, Cron.getDelay("foobar"))
            Cron.tick(1)
            assert.is_same(4, Cron.getDelay("foobar"))
            Cron.tick(1)
        end)
    end)


    describe("now()", function()
        it("gives the current time", function()
            local now = Cron.now()
            assert.is_true(isNumber(now))

            Cron.tick(1)

            assert.is_same(1, Cron.now() - now)
        end)
    end)


end)