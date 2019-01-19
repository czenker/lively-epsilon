-- this file includes the whole library
--
-- it tries to handle dependencies and makes sure higher order modules are included
-- before modules that depend on it.

local myPackages = {
    "src/lively_epsilon/cron.lua",
    "src/lively_epsilon/event_handler.lua",
    "src/lively_epsilon/util.lua",
    "utils.lua",
    "src/lively_epsilon/utility/ee.lua",
    "src/lively_epsilon/utility/log.lua",
    "src/lively_epsilon/utility/lua.lua",
    "src/lively_epsilon/utility/type_inspect.lua",
    "src/lively_epsilon/utility/comms.lua",

    "src/lively_epsilon/chat/chatter.lua",
    "src/lively_epsilon/chat/chat_factory.lua",
    "src/lively_epsilon/chat/chat_noise.lua",

    "src/lively_epsilon/menu/menu.lua",
    "src/lively_epsilon/menu/menu_item.lua",

    "src/lively_epsilon/domain/trait/generic/tags.lua",

    "src/lively_epsilon/domain/product.lua",
    "src/lively_epsilon/domain/person.lua",

    "src/lively_epsilon/domain/ship_template_based.lua",
    "src/lively_epsilon/domain/trait/shipTemplateBased/storage_rooms.lua",
    "src/lively_epsilon/domain/trait/shipTemplateBased/comms.lua",
    "src/lively_epsilon/domain/trait/shipTemplateBased/crew.lua",
    "src/lively_epsilon/domain/trait/shipTemplateBased/events.lua",
    "src/lively_epsilon/domain/trait/shipTemplateBased/mission_broker.lua",
    "src/lively_epsilon/domain/trait/shipTemplateBased/upgrade_broker.lua",

    "src/lively_epsilon/domain/station.lua",
    "src/lively_epsilon/domain/trait/station/merchant.lua",
    "src/lively_epsilon/comms/command.lua",
    "src/lively_epsilon/comms/merchant.lua",
    "src/lively_epsilon/comms/mission_broker.lua",
    "src/lively_epsilon/comms/upgrade_broker.lua",
    "src/lively_epsilon/domain/trait/station/production.lua",

    "src/lively_epsilon/domain/mission.lua",
    "src/lively_epsilon/domain/trait/mission/broker.lua",
    "src/lively_epsilon/domain/trait/mission/for_player.lua",

    "src/lively_epsilon/domain/fleet.lua",

    "src/lively_epsilon/domain/ship.lua",
    "src/lively_epsilon/domain/trait/ship/crew.lua",
    "src/lively_epsilon/domain/trait/ship/events.lua",
    "src/lively_epsilon/domain/trait/ship/fleet.lua",
    "src/lively_epsilon/orders/generic.lua",
    "src/lively_epsilon/orders/attack.lua",
    "src/lively_epsilon/orders/defend.lua",
    "src/lively_epsilon/orders/dock.lua",
    "src/lively_epsilon/orders/fly_to.lua",
    "src/lively_epsilon/orders/order_queue.lua",

    "src/lively_epsilon/domain/player.lua",
    "src/lively_epsilon/domain/trait/player/menu.lua",
    "src/lively_epsilon/domain/trait/player/mission_tracker.lua",
    "src/lively_epsilon/domain/trait/player/mission_display.lua",
    "src/lively_epsilon/domain/trait/player/power_presets.lua",
    "src/lively_epsilon/domain/trait/player/storage.lua",
    "src/lively_epsilon/domain/trait/player/storage_display.lua",
    "src/lively_epsilon/domain/trait/player/upgrade_tracker.lua",
    "src/lively_epsilon/domain/trait/player/upgrade_display.lua",

    "src/lively_epsilon/domain/broker_upgrade.lua",

    "src/lively_epsilon/behaviors/miner.lua",
    "src/lively_epsilon/behaviors/patrol.lua",
    "src/lively_epsilon/behaviors/trader.lua",

    "src/lively_epsilon/missions/answer.lua",
    "src/lively_epsilon/missions/bring_product.lua",
    "src/lively_epsilon/missions/capture.lua",
    "src/lively_epsilon/missions/crew_for_rent.lua",
    "src/lively_epsilon/missions/destroy.lua",
    "src/lively_epsilon/missions/destroy_raging_miner.lua",
    "src/lively_epsilon/missions/pick_up.lua",
    "src/lively_epsilon/missions/scan.lua",
    "src/lively_epsilon/missions/transport_token.lua",
    "src/lively_epsilon/missions/transport_product.lua",
    "src/lively_epsilon/missions/visit.lua",

    "src/lively_epsilon/narrative/repository.lua",
    "src/lively_epsilon/narrative/runner.lua",

    "src/lively_epsilon/tools/story_comms.lua",
    "src/lively_epsilon/tools/comms.lua",

    "src/lively_epsilon/translator/inspector.lua",
    "src/lively_epsilon/translator/translator.lua",
}

if package ~= nil and package.path ~= nil then
    -- when running tests

    for _, package in pairs(myPackages) do
        local name = package:match("^(.+).lua$")

        require(name)
    end
else
    -- within empty epsilon

    for _, package in pairs(myPackages) do
        require(package)
    end
end




