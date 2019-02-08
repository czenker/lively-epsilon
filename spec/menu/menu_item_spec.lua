insulate("Menu:newItem()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("works when all parameters are given", function()
        local item = Menu:newItem("Label", function() return "Hello World" end, 100)

        assert.is_true(Menu:isMenuItem(item))
        assert.is_same("Label", item:getLabel())
        assert.is_same("Hello World", item:onClick())
        assert.is_same(100, item:getPriority())
    end)
    it("sets a default priority of 0", function()
        local item = Menu:newItem("Label", function() return "Hello World" end)

        assert.is_true(Menu:isMenuItem(item))
        assert.is_same("Label", item:getLabel())
        assert.is_same("Hello World", item:onClick())
        assert.is_same(0, item:getPriority())
    end)
    it("wraps onClick in a function", function()
        local item = Menu:newItem("Label", "Hello World")

        assert.is_true(Menu:isMenuItem(item))
        assert.is_same("Label", item:getLabel())
        assert.is_same("Hello World", item:onClick())
        assert.is_same(0, item:getPriority())
    end)
    it("wraps onClick in a function with prio", function()
        local item = Menu:newItem("Label", "Hello World", 99)

        assert.is_true(Menu:isMenuItem(item))
        assert.is_same("Label", item:getLabel())
        assert.is_same("Hello World", item:onClick())
        assert.is_same(99, item:getPriority())
    end)
    it("only the label is mandatory", function()
        local item = Menu:newItem("Label")

        assert.is_true(Menu:isMenuItem(item))
        assert.is_same("Label", item:getLabel())
        assert.is_same(nil, item.onClick)
        assert.is_same(0, item:getPriority())
    end)
    it("allows a short syntax for labels with priority", function()
        local item = Menu:newItem("Label", 99)

        assert.is_true(Menu:isMenuItem(item))
        assert.is_same("Label", item:getLabel())
        assert.is_same(nil, item.onClick)
        assert.is_same(99, item:getPriority())
    end)
end)