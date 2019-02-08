insulate("BrokerUpgrade:new()", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    local player = PlayerSpaceship()
    local function upgradeMock(config)
        return BrokerUpgrade:new(Util.mergeTables({
            name = "Foobar",
            onInstall = function() end,
        }, config or {}))
    end

    it("returns a valid BrokerUpgrade", function()
        local upgrade = upgradeMock()
        assert.is_true(BrokerUpgrade:isUpgrade(upgrade))
    end)
    it("fails if first argument is a number", function()
        assert.has_error(function() BrokerUpgrade:new(42) end)
    end)
    it("fails if there is no name given", function()
        assert.has_error(function() BrokerUpgrade:new("Foobar") end)
    end)
    it("fails if there is no install function given", function()
        assert.has_error(function() BrokerUpgrade:new(nil, function() end) end)
    end)

    describe("config.id, getId()", function()
        it("sets a unique id", function()
            local upgrade = upgradeMock({id = nil})

            assert.is_string(upgrade:getId())
            assert.not_same("", upgrade:getId())

            local upgrade2 = upgradeMock({id = nil})
            assert.not_same(upgrade:getId(), upgrade2:getId())
        end)
        it("allows to set an id", function()
            local upgrade = upgradeMock({
                id = "fake_upgrade",
            })
            assert.is_same("fake_upgrade", upgrade:getId())
        end)
        it("fails if id is a number", function()
            assert.has_error(function() upgradeMock({id = 42}) end)
        end)
    end)

    describe("config.name, getName()", function()
        it("fails if no name is given", function()
            assert.has_error(function() BrokerUpgrade:new({
                onInstall = function() end,
            }) end)
        end)
        it("fails if name is a number", function()
            assert.has_error(function() upgradeMock({name = 42}) end)
        end)
        it("returns the name if it is a string", function()
            local name = "Hello World"
            local upgrade = upgradeMock({name = name})

            assert.is_same(name, upgrade:getName())
        end)
    end)

    describe("config.price, getPrice()", function()
        it("returns 0 if config.price is not set", function()
            local upgrade = upgradeMock()

            assert.is_same(0, upgrade:getPrice())
        end)
        it("fails if price is non-numeric", function()
            assert.has_error(function()
                upgradeMock({price = "foo"})
            end)
        end)
        it("takes the price that was set", function()
            local upgrade = upgradeMock({price = 42.0})

            assert.is_same(42.0, upgrade:getPrice())
        end)
        it("deduces the cost from the players reputation points when installed", function()
            local upgrade = upgradeMock({price = 42.0})
            local player = PlayerSpaceship():setReputationPoints(100)

            upgrade:install(player)

            assert.is_same(58, player:getReputationPoints())
        end)
    end)


    describe(":canBeInstalled()", function()
        local player = PlayerSpaceship()
        local canBeInstalledCalled = 0
        local upgrade
        upgrade = upgradeMock({canBeInstalled = function(callBrokerUpgrade, callPlayer)
            canBeInstalledCalled = canBeInstalledCalled + 1
            assert.is_same(upgrade, callBrokerUpgrade)
            assert.is_same(player, callPlayer)
        end})

        it("calls the callback", function()
            canBeInstalledCalled = 0

            local success, msg = upgrade:canBeInstalled(player)
            assert.is_same(1, canBeInstalledCalled)
        end)

        it("interprets as true, when callback returns nil", function()
            local player = PlayerSpaceship()
            local upgrade
            upgrade = upgradeMock({canBeInstalled = function()
                return nil
            end})

            local success, msg = upgrade:canBeInstalled(player)
            assert.is_true(success)
            assert.is_nil(msg)
        end)

        it("removes message if it is attached to a true response", function()
            local player = PlayerSpaceship()
            local upgrade = upgradeMock({canBeInstalled = function()
                return true, "message"
            end})

            local success, msg = upgrade:canBeInstalled(player)
            assert.is_true(success)
            assert.is_nil(msg)
        end)

        it("removes non-string message on failure", function()
            local player = PlayerSpaceship()
            local upgrade = upgradeMock({canBeInstalled = function()
                return false, 42
            end})

            local success, msg = upgrade:canBeInstalled(player)
            assert.is_false(success)
            assert.is_nil(msg)
        end)

        it("passes through a string on failure", function()
            local player = PlayerSpaceship()
            local upgrade = upgradeMock({canBeInstalled = function()
                return false, "foobar"
            end})

            local success, msg = upgrade:canBeInstalled(player)
            assert.is_false(success)
            assert.is_same("foobar", msg)
        end)

        it("fails if no player is given", function()
            canBeInstalledCalled = 0

            assert.has_error(function() upgrade:canBeInstalled(42) end)
            assert.is_same(0, canBeInstalledCalled)
        end)
    end)

    describe(":install()", function()
        local player = PlayerSpaceship()
        local installCalled = 0
        local canBeInstalledCalled = 0
        local upgrade
        upgrade = upgradeMock({
            onInstall = function(callBrokerUpgrade, callPlayer)
                installCalled = installCalled + 1
                assert.is_same(player, callPlayer)
                assert.is_same(upgrade, callBrokerUpgrade)
            end,
            canBeInstalled = function(callBrokerUpgrade, callPlayer)
                canBeInstalledCalled = canBeInstalledCalled + 1
                assert.is_same(player, callPlayer)
                assert.is_same(upgrade, callBrokerUpgrade)
            end
        })

        it("calls the canBeInstalled callback and the install callback", function()
            canBeInstalledCalled = 0
            installCalled = 0

            upgrade:install(player)
            assert.is_same(1, canBeInstalledCalled)
            assert.is_same(1, installCalled)

            upgrade:install(player)
            assert.is_same(2, canBeInstalledCalled)
            assert.is_same(2, installCalled)
        end)
        it("throws error if requirement is not met", function()
            local upgrade = upgradeMock({canBeInstalled = function()
                return false
            end})

            assert.has_error(function() upgrade:install(player) end)
        end)

        it("fails if no player is given", function()
            canBeInstalledCalled = 0
            installCalled = 0

            assert.has_error(function() upgrade:install(42) end)
            assert.is_same(0, canBeInstalledCalled)
            assert.is_same(0, installCalled)
        end)
    end)

    describe("config.description, getDescription()", function()
        it("fails if no player is given", function()
            local upgrade = upgradeMock()

            assert.has_error(function() upgrade:getDescription() end)
        end)
        it("returns nil if no description is set", function()
            local upgrade = upgradeMock({description = nil})

            assert.is_nil(upgrade:getDescription(player))
        end)
        it("returns the description if it is a string", function()
            local description = "This is an upgrade"
            local upgrade = upgradeMock({description = description})

            assert.is_same(description, upgrade:getDescription(player))
        end)

        it("returns the description if it is a function", function()
            local description = "This is an upate"
            local upgrade
            upgrade = upgradeMock({description = function(callBrokerUpgrade)
                assert.is_same(upgrade, callBrokerUpgrade)
                return description
            end})

            assert.is_same(description, upgrade:getDescription(player))
        end)
    end)

    describe("config.installMessage, getInstallMessage()", function()
        it("fails if no player is given", function()
            local upgrade = upgradeMock({installMessage = "Foobar" })

            assert.has_error(function() upgrade:getInstallMessage() end)
        end)

        it("returns nil if no installMessage is set", function()
            local upgrade = upgradeMock({installMessage = nil})

            assert.is_nil(upgrade:getInstallMessage(player))
        end)

        it("returns the message if it is a string", function()
            local message = "Thanks for buying that upgrade"
            local upgrade = upgradeMock({installMessage = message })

            assert.is_same(message, upgrade:getInstallMessage(player))
        end)

        it("returns the message if it is a function", function()
            local message = "Thanks for buying that upgrade"
            local upgrade
            upgrade = upgradeMock({installMessage = function(callBrokerUpgrade)
                assert.is_same(upgrade, callBrokerUpgrade)
                return message
            end})

            assert.is_same(message, upgrade:getInstallMessage(player))
        end)
    end)

    describe("config.unique", function()
        it("prevents the upgrade from being installed on a ship without Upgrade Tracker", function()
            local upgrade = upgradeMock({unique = true})
            local player = PlayerSpaceship()

            assert.is_false(upgrade:canBeInstalled(player))
        end)
        it("prevents the upgrade from being installed more than once on a ship", function()
            local upgrade = upgradeMock({unique = true})
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)

            assert.is_true(upgrade:canBeInstalled(player))
            upgrade:install(player)

            assert.is_false(upgrade:canBeInstalled(player))
        end)
    end)

    describe("config.requiredUpgrade", function()
        it("prevents the upgrade from being installed on a ship without Upgrade Tracker", function()
            local upgrade = upgradeMock({requiredUpgrade = "foobar"})
            local player = PlayerSpaceship()

            assert.is_false(upgrade:canBeInstalled(player))
        end)
        it("prevents the upgrade to be installed if the required is not installed", function()
            local upgrade = upgradeMock({requiredUpgrade = "foobar"})
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)
            player:addUpgrade(upgradeMock())

            assert.is_false(upgrade:canBeInstalled(player))
        end)
        it("allows to install an upgrade if the required is installed", function()
            local required = upgradeMock({id = "required"})
            local upgrade = upgradeMock({requiredUpgrade = "required"})
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)
            player:addUpgrade(required)

            assert.is_true(upgrade:canBeInstalled(player))
        end)
        it("exposes the required upgrade", function()
            local required = upgradeMock({id = "required"})
            local upgrade = upgradeMock({requiredUpgrade = "required"})
            local player = PlayerSpaceship()
            Player:withUpgradeTracker(player)
            player:addUpgrade(required)

            assert.is_same("required", upgrade:getRequiredUpgradeString())
        end)
    end)
end)