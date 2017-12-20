insulate("Cron", function()
    require "lively_epsilon"

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
    end)


end)