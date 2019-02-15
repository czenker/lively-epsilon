-- this file includes the whole library
--
-- it tries to handle dependencies and makes sure higher order modules are included
-- before modules that depend on it.

local myPackages = {
    "lively_epsilon/src/cron.lua",
    "lively_epsilon/src/event_handler.lua",
    "lively_epsilon/src/util.lua",
    "utils.lua",
    "lively_epsilon/src/utility/ee.lua",
    "lively_epsilon/src/utility/log.lua",
    "lively_epsilon/src/utility/lua.lua",
    "lively_epsilon/src/utility/type_inspect.lua",
    "lively_epsilon/src/utility/comms.lua",

    "lively_epsilon/src/chat/chatter.lua",
    "lively_epsilon/src/chat/chat_factory.lua",
    "lively_epsilon/src/chat/chat_noise.lua",

    "lively_epsilon/src/menu/menu.lua",
    "lively_epsilon/src/menu/menu_item.lua",
    "lively_epsilon/src/menu/gm_menu.lua",

    "lively_epsilon/src/domain/trait/generic/tags.lua",

    "lively_epsilon/src/domain/product.lua",
    "lively_epsilon/src/domain/person.lua",

    "lively_epsilon/src/domain/ship_template_based.lua",
    "lively_epsilon/src/domain/trait/shipTemplateBased/storage_rooms.lua",
    "lively_epsilon/src/domain/trait/shipTemplateBased/comms.lua",
    "lively_epsilon/src/domain/trait/shipTemplateBased/crew.lua",
    "lively_epsilon/src/domain/trait/shipTemplateBased/events.lua",
    "lively_epsilon/src/domain/trait/shipTemplateBased/mission_broker.lua",
    "lively_epsilon/src/domain/trait/shipTemplateBased/upgrade_broker.lua",

    "lively_epsilon/src/domain/station.lua",
    "lively_epsilon/src/domain/trait/station/merchant.lua",
    "lively_epsilon/src/comms/merchant.lua",
    "lively_epsilon/src/comms/mission_broker.lua",
    "lively_epsilon/src/comms/upgrade_broker.lua",
    "lively_epsilon/src/domain/trait/station/production.lua",

    "lively_epsilon/src/domain/mission.lua",
    "lively_epsilon/src/domain/trait/mission/broker.lua",
    "lively_epsilon/src/domain/trait/mission/for_player.lua",

    "lively_epsilon/src/domain/fleet.lua",

    "lively_epsilon/src/domain/ship.lua",
    "lively_epsilon/src/domain/trait/ship/crew.lua",
    "lively_epsilon/src/domain/trait/ship/events.lua",
    "lively_epsilon/src/domain/trait/ship/fleet.lua",
    "lively_epsilon/src/orders/generic.lua",
    "lively_epsilon/src/orders/attack.lua",
    "lively_epsilon/src/orders/defend.lua",
    "lively_epsilon/src/orders/dock.lua",
    "lively_epsilon/src/orders/fly_to.lua",
    "lively_epsilon/src/orders/order_queue.lua",
    "lively_epsilon/src/orders/roaming.lua",
    "lively_epsilon/src/orders/use.lua",

    "lively_epsilon/src/domain/player.lua",
    "lively_epsilon/src/domain/trait/player/menu.lua",
    "lively_epsilon/src/domain/trait/player/mission_tracker.lua",
    "lively_epsilon/src/domain/trait/player/mission_display.lua",
    "lively_epsilon/src/domain/trait/player/power_presets.lua",
    "lively_epsilon/src/domain/trait/player/storage.lua",
    "lively_epsilon/src/domain/trait/player/storage_display.lua",
    "lively_epsilon/src/domain/trait/player/upgrade_tracker.lua",
    "lively_epsilon/src/domain/trait/player/upgrade_display.lua",

    "lively_epsilon/src/domain/broker_upgrade.lua",

    "lively_epsilon/src/behaviors/miner.lua",
    "lively_epsilon/src/behaviors/trader.lua",

    "lively_epsilon/src/missions/answer.lua",
    "lively_epsilon/src/missions/bring_product.lua",
    "lively_epsilon/src/missions/capture.lua",
    "lively_epsilon/src/missions/crew_for_rent.lua",
    "lively_epsilon/src/missions/disable.lua",
    "lively_epsilon/src/missions/destroy.lua",
    "lively_epsilon/src/missions/destroy_raging_miner.lua",
    "lively_epsilon/src/missions/pick_up.lua",
    "lively_epsilon/src/missions/scan.lua",
    "lively_epsilon/src/missions/transport_token.lua",
    "lively_epsilon/src/missions/transport_product.lua",
    "lively_epsilon/src/missions/visit.lua",

    "lively_epsilon/src/tools/story_comms.lua",
    "lively_epsilon/src/tools/comms.lua",

    "lively_epsilon/src/translator/inspector.lua",
    "lively_epsilon/src/translator/translator.lua",
}

if package ~= nil and package.path ~= nil then
    local basePath = debug.getinfo(1).source
    if basePath:sub(1,1) == "@" then basePath = basePath:sub(2) end
    if basePath:sub(-8) == "init.lua" then basePath = basePath:sub(1, -9) end
    basePath = "./" .. basePath

    package.path = package.path .. ";" .. basePath .. "?.lua"

    -- when running tests
    local prefix = "lively_epsilon/"

    for _, package in pairs(myPackages) do
        if package:sub(1, prefix:len()) == prefix then
            package = package:sub(prefix:len() + 1)
        end

        local name = package:match("^(.+).lua$")

        require(name)
    end
else
    -- within empty epsilon

    for _, package in pairs(myPackages) do
        require(package)
    end
end




