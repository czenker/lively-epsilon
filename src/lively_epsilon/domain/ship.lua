Ship = Ship or {}

setmetatable(Ship,{
    __index = ShipTemplateBased
})