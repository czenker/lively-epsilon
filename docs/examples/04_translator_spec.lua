insulate("documentation on Cron", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"
    require "spec.universe"

    it("register, translate", function()
        local player = PlayerSpaceship()
        local station = SpaceStation()

        -- tag::basic[]
        local translator = Translator:new()
        translator:register("say_hi", "Hello World")
        translator:register({
            say_hi_to_foo = "Hello Foo",
            say_hi_to_bar = "Hello Bar",
        })

        translator:translate("say_hi") -- returns "Hello World"
        translator:translate("say_hi_to_foo") -- returns "Hello Foo"
        -- end::basic[]
        -- tag::function[]
        local translator = Translator:new()
        translator:register("say_hello", function(name)
            return "Hello " .. name
        end)

        translator:translate("say_hello", "Bob") -- returns "Hello Bob"
        -- end::function[]
        -- tag::languages[]
        local translator = Translator:new()
        translator:register("say_hello", function(name)
            return "Hello " .. name
        end)
        translator:register("de", "say_hello", function(name)
            return "Hallo " .. name
        end)

        translator:translate("say_hello", "Bob") -- returns "Hello Bob"

        translator:useLocale("de")
        translator:translate("say_hello", "Bob") -- returns "Hallo Bob"
        -- end::languages[]
        -- tag::fallbacks[]
        local translator = Translator:new()

        translator:register("en", "one", "One")
        translator:register("en", "two", "Two")
        translator:register("de", "one", "Eins")

        translator:useLocale("de", "en")
        translator:translate("one") -- returns "Eins"
        translator:translate("two") -- returns "Two"
        -- end::fallbacks[]
    end)
end)