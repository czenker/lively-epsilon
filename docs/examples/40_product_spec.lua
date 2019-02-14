insulate("documentation on Product", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("new", function()
        -- tag::basic[]
        local ore = Product:new("Iron Ore", {
            id = "ore",
            size = 4,
        })
        -- end::basic[]
    end)
    it("mission item", function()
        -- tag::mission-item[]
        local mcguffin = Product:new("Mission Item")
        -- end::mission-item[]
    end)
end)