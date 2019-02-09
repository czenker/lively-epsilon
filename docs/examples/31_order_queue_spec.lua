insulate("documentation on OrderQueue", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        -- tag::basic[]
        local ship = CpuShip():setFaction("Human Navy")
        local homeBase = SpaceStation():setFaction("Human Navy")
        local enemyBase = SpaceStation():setFaction("Kraylor")
        Ship:withOrderQueue(ship)

        ship:addOrder(Order:defend(10000, 0, {
            range = 20000,
            minClearTime = 30,
        }))
        ship:addOrder(Order:attack(enemyBase))
        ship:addOrder(Order:dock(homeBase))
        ship:addOrder(Order:flyTo(5000, 0))
        -- end::basic[]
    end)
    it("loop", function()
        -- tag::loop[]
        local ship = CpuShip()
        Ship:withOrderQueue(ship)
        ship:setPosition(0, 0)

        ship:addOrder(Order:flyTo(5000, 0, {
            onCompletion = function(self, ship) ship:addOrder(self) end,
        }))
        ship:addOrder(Order:flyTo(-5000, 0, {
            onCompletion = function(self, ship) ship:addOrder(self) end,
        }))
        -- end::loop[]

        assert.is_same("Fly towards", ship:getOrder())
        assert.is_same({5000, 0}, {ship:getOrderTargetLocation()})

        ship:setPosition(5000, 0)
        Cron.tick(1)
        assert.is_same("Fly towards", ship:getOrder())
        assert.is_same({-5000, 0}, {ship:getOrderTargetLocation()})

        ship:setPosition(-5000, 0)
        Cron.tick(1)
        assert.is_same("Fly towards", ship:getOrder())
        assert.is_same({5000, 0}, {ship:getOrderTargetLocation()})

        ship:setPosition(5000, 0)
        Cron.tick(1)
        assert.is_same("Fly towards", ship:getOrder())
        assert.is_same({-5000, 0}, {ship:getOrderTargetLocation()})
    end)
    it("flyTo", function()
        -- tag::flyTo[]
        local ship = CpuShip():setFaction("Human Navy")
        Ship:withOrderQueue(ship)
        ship:addOrder(Order:flyTo(10000, 0, {
            minDistance = 1000
        }))
        ship:addOrder(Order:flyTo(0, 10000, {
            minDistance = 1000
        }))
        ship:addOrder(Order:flyTo(-10000, 0, {
            minDistance = 1000
        }))
        -- end::flyTo[]
    end)
    it("dock", function()
        -- tag::dock[]
        local ship = CpuShip():setFaction("Human Navy")
        local station = SpaceStation():setFaction("Human Navy")
        Ship:withOrderQueue(ship)

        ship:addOrder(Order:dock(station))
        -- end::dock[]
    end)
    it("attack", function()
        -- tag::attack[]
        local ship = CpuShip():setFaction("Human Navy")
        local station = SpaceStation():setFaction("Kraylor")
        Ship:withOrderQueue(ship)

        ship:addOrder(Order:attack(station))
        -- end::attack[]
    end)
    it("defend", function()
        -- tag::defend[]
        local ship = CpuShip():setFaction("Human Navy")
        local station = SpaceStation():setFaction("Human Navy")
        Ship:withOrderQueue(ship)

        ship:addOrder(Order:defend(station))
        ship:addOrder(Order:defend(10000, 0))
        ship:addOrder(Order:defend())
        -- end::defend[]
    end)
    it("use", function()
        -- tag::use[]
        local ship = CpuShip():setFaction("Human Navy")
        local ship2 = CpuShip():setFaction("Human Navy")
        local ship3 = CpuShip():setFaction("Human Navy")
        local wormHole = WormHole():setPosition(10000, 0):setTargetPosition(99999, 0)

        local fleet = Fleet:new({ ship, ship2, ship3 })
        Fleet:withOrderQueue(fleet)

        fleet:addOrder(Order:use(wormHole))
        fleet:addOrder(Order:flyTo(99999, 99999))
        -- end::use[]
    end)
end)