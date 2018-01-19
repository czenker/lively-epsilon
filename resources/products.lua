local s = 1
local m = 2
local l = 4
local xl = 8

products = {
    o2 = {
        name = "Oxygen",
        size = s,
        basePrice = 1,
    },
    power = {
        name = "Power Cells",
        size = s,
        basePrice = 1,
    },
    water = {
        name = "Water",
        size = s,
        basePrice = 1,
    },
    waste = {
        name = "Toxic Waste",
        size = m,
        basePrice = 1,
    },
    ore = {
        name = "Ore",
        size = m,
        basePrice = 1,
    },
    plutoniumOre = {
        name = "Plutonium Ore",
        size = l,
        basePrice = 10,
    },
    miningMachinery = {
        name = "Mining Machinery",
        size = xl,
        basePrice = 15,
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