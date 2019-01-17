insulate("typeInspect", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    it("prints nil", function()
        assert.is_same("<nil>", typeInspect(nil))
    end)

    it("prints boolean", function()
        assert.is_same("<bool>true", typeInspect(true))
        assert.is_same("<bool>false", typeInspect(false))
    end)

    it("prints number", function()
        assert.is_same("<number>42", typeInspect(42))
        assert.is_same("<number>-123", typeInspect(-123))
        assert.is_same("<number>12.3456", typeInspect(12.3456))
    end)

    it("prints strings", function()
        assert.is_same("<string>\"foobar\"", typeInspect("foobar"))
        assert.is_same("<string>\"This is a very long sting that...\"", typeInspect("This is a very long sting that should be cut off in order to not be too long."))
        assert.is_same("<string>\"\"", typeInspect(""))
    end)

    it("prints function", function()
        assert.is_same("<function>", typeInspect(function() end))
    end)

    it("prints tables with numeric key", function()
        assert.is_same("<table>(size: 2)", typeInspect({"foo", "bar"}))
    end)

    it("prints tables with string key", function()
        assert.is_same("<table>(size: 2)", typeInspect({foo = "bar", baz = 42}))
    end)

    it("prints PlayerSpaceShip", function()
        local player = PlayerSpaceship():setCallSign("Artemis")
        assert.is_same("<PlayerSpaceship>\"Artemis\"", typeInspect(player))

        player:destroy()
        assert.is_same("<PlayerSpaceship>", typeInspect(player))
    end)
end)