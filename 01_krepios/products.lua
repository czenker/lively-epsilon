local s = 1
local m = 2
local l = 4
local xl = 8
local xxl = 16

products = {
    ore = {
        name = "Erz",
        size = m,
        basePrice = 1,
    },
    plutoniumOre = {
        name = "Plutoniumerz",
        size = l,
        basePrice = 10,
    },
    miningMachinery = {
        name = "Bergbaumaschinen",
        size = xl,
        basePrice = 15,
    },

    -- those have special meaning because of their id
    hvli = {
        name = "HVLI",
        size = m,
        basePrice = 4,
    },
    homing = {
        name = "Homing Missile",
        size = m,
        basePrice = 4,
    },
    mine = {
        name = "Mine",
        size = xl,
        basePrice = 8,
    },
    emp = {
        name = "EMP Missile",
        size = l,
        basePrice = 10,
    },
    nuke = {
        name = "Nuke Missile",
        size = l,
        basePrice = 30,
    },
}

-- add id to object
for k, v in pairs(products) do
    products[k] = Product:new(v.name, {
        id = k,
        size = v.size,
    })
    products[k].basePrice = v.basePrice
end

-- validate
for k, v in pairs(products) do
    if not Product.isProduct(v) then
        error ("Product with id " .. k .. " is not valid.", 2)
    end
end