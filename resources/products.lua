products = {
    o2 = { name = "Sauerstoff"},
    power = { name = "Energiezellen"},
    waste = { name = "Giftmuell"},
    ore = { name = "Erz"},
    plutoniumOre = { name = "Plutoniumerz"},
}

-- add id to object
for k, v in pairs(products) do
    v.id = k
end

-- validate
for k, v in pairs(products) do
    if not Product.isProduct(v) then
        error ("Product with id " .. k .. " is not valid.", 2)
    end
end