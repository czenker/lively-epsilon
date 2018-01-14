local s = 1
local m = 2
local l = 4
local xl = 8

products = {
    o2 = {
        name = "Oxygen",
        size = s,
    },
    power = {
        name = "Power Cells",
        size = s,
    },
    waste = {
        name = "Toxic Waste",
        size = m,
    },
    ore = {
        name = "Ore",
        size = m,
    },
    plutoniumOre = {
        name = "Plutonium Ore",
        size = l,
    },
}

-- add id to object
for k, v in pairs(products) do
    products[k] = Product:new(v.name, {
        id = k,
        size = v.size,
    })
end

-- validate
for k, v in pairs(products) do
    if not Product.isProduct(v) then
        error ("Product with id " .. k .. " is not valid.", 2)
    end
end