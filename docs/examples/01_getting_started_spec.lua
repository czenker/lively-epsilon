insulate("basic setup", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    it("should run getting started", function()
        require = function()
            -- disable the require function to prevent errors
        end

        -- tag::getting-started[]
        -- Name: Hello Lively Epsilon
        -- Description: Testing Lively Epsilon
        -- Type: Mission
        -- end::getting-started[]
--[[
        -- tag::getting-started[]
        require "lively_epsilon/init.lua"
        -- end::getting-started[]
]]--
        -- tag::getting-started[]
        function init()
            -- add your code here
        end

        function update(delta)
            Cron.tick(delta)
        end
        -- end::getting-started[]
        init()
        update(1)
    end)
end)