insulate("ShipTemplateBased:withUpgradeBroker()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("causes hasUpgradeBroker() to be true", function()
        local station = SpaceStation()
        ShipTemplateBased:withUpgradeBroker(station)

        assert.is_true(ShipTemplateBased:hasUpgradeBroker(station))
    end)

    it("fails if first argument is not a SpaceObject", function()
        assert.has_error(function() ShipTemplateBased:withUpgradeBroker(42) end)
    end)

    it("fails if first argument is already a SpaceObject with broker", function()
        local station = SpaceStation()
        ShipTemplateBased:withUpgradeBroker(station)

        assert.has_error(function() ShipTemplateBased:withUpgradeBroker(station) end)
    end)

    it("fails if second argument is not a table", function()
        local station = SpaceStation()

        assert.has_error(function() ShipTemplateBased:withUpgradeBroker(station, 42) end)
    end)

    it("allows to set upgrades", function()
        local station = SpaceStation()

        ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgradeMock(), upgradeMock(), upgradeMock()}})
        assert.is_same(3, Util.size(station:getUpgrades()))
    end)

    it("fails if upgrades is a number", function()
        local station = SpaceStation()

        assert.has_error(function() ShipTemplateBased:withUpgradeBroker(station, {upgrades = 42}) end)
    end)

    it("fails if any of the upgrades is not a upgrade with broker", function()
        local station = SpaceStation()

        assert.has_error(function() ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgradeMock}}) end)
    end)

    describe(":addUpgrade()", function()
        it("allows to add upgrades", function()
            local station = SpaceStation()
            ShipTemplateBased:withUpgradeBroker(station)

            station:addUpgrade(upgradeMock())
            assert.is_same(1, Util.size(station:getUpgrades()))
            station:addUpgrade(upgradeMock())
            assert.is_same(2, Util.size(station:getUpgrades()))
            station:addUpgrade(upgradeMock())
            assert.is_same(3, Util.size(station:getUpgrades()))
        end)

        it("fails if the argument is a number", function()
            local station = SpaceStation()
            ShipTemplateBased:withUpgradeBroker(station)

            assert.has_error(function() station:addUpgrade(42) end)
        end)
    end)

    describe(":removeUpgrade()", function()
        it("allows to remove a upgrade object", function()
            local station = SpaceStation()
            local upgrade = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgrade}})

            assert.is_same(1, Util.size(station:getUpgrades()))
            station:removeUpgrade(upgrade)
            assert.is_same(0, Util.size(station:getUpgrades()))
        end)

        it("allows to remove a upgrade by its id", function()
            local station = SpaceStation()
            local upgrade = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgrade}})

            assert.is_same(1, Util.size(station:getUpgrades()))
            station:removeUpgrade(upgrade:getId())
            assert.is_same(0, Util.size(station:getUpgrades()))
        end)

        it("fails if the argument is a number", function()
            local station = SpaceStation()
            ShipTemplateBased:withUpgradeBroker(station)

            assert.has_error(function() station:removeUpgrade(42) end)
        end)

        it("fails silently if the upgrade is unknown", function()
            local station = SpaceStation()
            local upgrade1 = upgradeMock()
            local upgrade2 = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades={upgrade1}})

            station:removeUpgrade(upgrade2)
            assert.is_same(1, Util.size(station:getUpgrades()))
        end)
    end)

    describe(":getUpgrades()", function()
        it("returns an empty table if no upgrades where added", function()
            local station = SpaceStation()
            ShipTemplateBased:withUpgradeBroker(station)

            assert.is_same(0, Util.size(station:getUpgrades()))
        end)

        it("returns any upgrades added via withUpgradeBroker() and addUpgrade()", function()
            local station = SpaceStation()
            local upgrade1 = upgradeMock()
            local upgrade2 = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgrade1}})
            station:addUpgrade(upgrade2)

            local upgrade1Found = false
            local upgrade2Found = false

            for _, upgrade in pairs(station:getUpgrades()) do
                if upgrade == upgrade1 then upgrade1Found = true end
                if upgrade == upgrade2 then upgrade2Found = true end
            end

            assert.is_true(upgrade1Found)
            assert.is_true(upgrade2Found)
        end)

        it("should not allow to manipulate the upgrade table", function()
            local station = SpaceStation()
            local upgrade1 = upgradeMock()
            local upgrade2 = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgrade1}})

            table.insert(station:getUpgrades(), upgrade2)

            assert.is_same(1, Util.size(station:getUpgrades()))
        end)
    end)

    describe(":hasUpgrade()", function()
        it("returns false if no upgrades where added", function()
            local station = SpaceStation()
            ShipTemplateBased:withUpgradeBroker(station)
            local upgrade = upgradeMock()

            assert.is_false(station:hasUpgrade(upgrade))
        end)

        it("returns true if a upgrade has been added via withUpgradeBroker()", function()
            local station = SpaceStation()
            local upgrade = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgrade}})

            assert.is_true(station:hasUpgrade(upgrade))
            assert.is_true(station:hasUpgrade(upgrade:getId()))
        end)

        it("returns true if a upgrade has been added via addUpgrade()", function()
            local station = SpaceStation()
            local upgrade = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station)
            station:addUpgrade(upgrade)

            assert.is_true(station:hasUpgrade(upgrade))
            assert.is_true(station:hasUpgrade(upgrade:getId()))
        end)

        it("raises an error on invalid arguments", function()
            local station = SpaceStation()
            local upgrade = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgrade}})

            assert.has_error(function() station:hasUpgrade(42) end)
            assert.has_error(function() station:hasUpgrade(SpaceStation()) end)
            assert.has_error(function() station:hasUpgrade(nil) end)
        end)
    end)

    describe(":hasUpgrades()", function()
        it("returns false if no upgrades where added", function()
            local station = SpaceStation()
            ShipTemplateBased:withUpgradeBroker(station)

            assert.is_false(station:hasUpgrades())
        end)

        it("returns true if a upgrade has been added via withUpgradeBroker()", function()
            local station = SpaceStation()
            local upgrade = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station, {upgrades = {upgrade}})

            assert.is_true(station:hasUpgrades())
        end)

        it("returns true if a upgrade has been added via addUpgrade()", function()
            local station = SpaceStation()
            local upgrade = upgradeMock()
            ShipTemplateBased:withUpgradeBroker(station)
            station:addUpgrade(upgrade)

            assert.is_true(station:hasUpgrades())
        end)
    end)
end)