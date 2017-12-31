Station = Station or {}

setmetatable(Station,{
    __index = ShipTemplateBased
})