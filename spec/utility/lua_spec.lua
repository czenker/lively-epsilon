insulate("Util", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.log_catcher"

    describe("userCallback()", function()
        it("calls the callback and returns the args if no error occurs", function()
            local a,b,c = userCallback(function(arg1, arg2, arg3) return arg1 * 7, arg2 .. "bar", not arg3 end, 6, "foo", true)

            assert.is_same(42, a)
            assert.is_same("foobar", b)
            assert.is_false(c)
        end)

        it("logs an error and returns nil if an error occurs", function()
            withLogCatcher(function(logs)
                local result = userCallback(function() error("Fail") end)
                assert.is_nil(result)
                assert.is_not_nil(logs:popLastError())
            end)
        end)

        it("returns if no function is given", function()
            withLogCatcher(function(logs)
                local result = userCallback(nil)
                assert.is_nil(result)
                assert.is_nil(logs:popLastError())
            end)
        end)

        it("logs an error if an invalid function is given", function()
            withLogCatcher(function(logs)
                local result = userCallback("foobar")
                assert.is_nil(result)
                assert.is_not_nil(logs:popLastError())
            end)
        end)
    end)
end)