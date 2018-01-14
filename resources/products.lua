products = {
    o2 = { name = "Oxygen"},
    power = { name = "Power Cells"},
    waste = { name = "Toxic Waste"},
    ore = { name = "Ore"},
    plutoniumOre = { name = "Plutonium Ore"},
}

-- add id to object
for k, v in pairs(products) do
    products[k] = Product:new(v.name, k)
end

-- validate
for k, v in pairs(products) do
    if not Product.isProduct(v) then
        error ("Product with id " .. k .. " is not valid.", 2)
    end
end