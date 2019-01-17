insulate("Generic", function()

    require "lively_epsilon"
    require "test.mocks"
    require "test.asserts"

    describe("withTags()", function()
        it("creates a valid tagged object", function()
            local station = SpaceStation()
            Generic:withTags(station)

            assert.is_true(Generic:hasTags(station))
        end)
        it("allows to set tags in the constructor", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar", "baz")

            assert.is_true(Generic:hasTags(station))
            assert.is_same(3, Util.size(station:getTags()))
        end)
        it("fails if the first argument is a number", function()
            assert.has_error(function() Generic:withTags(42) end)
        end)
        it("fails if a tag is not a string", function()
            assert.has_error(function() Generic:withTags(station, "foo", "bar", 42) end)
        end)
    end)

    describe("getTags()", function()
        it("returns all tags set in the constructor", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            local tags = station:getTags()
            assert.contains_value("foo", tags)
            assert.contains_value("bar", tags)
        end)
        it("does not allow to manipulate the tags", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            local tags = station:getTags()
            table.insert(tags, "fake")

            tags = station:getTags()
            assert.not_contains_value("fake", tags)
        end)
        it("does not return the same tag twice", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar", "bar", "bar")

            local tags = station:getTags()
            assert.is_same(2, Util.size(tags))
            assert.contains_value("foo", tags)
            assert.contains_value("bar", tags)
        end)
    end)

    describe("hasTag()", function()
        it("returns true if a tag was set in the constructor and false if not", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            assert.is_true(station:hasTag("foo"))
            assert.is_true(station:hasTag("bar"))
            assert.is_false(station:hasTag("fake"))
        end)
        it("fails if a non-string tag is given", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            assert.has_error(function()
                station:hasTag(42)
            end)
        end)
    end)

    describe("addTag()", function()
        it("adds a tag", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            station:addTag("baz")

            assert.is_true(station:hasTag("baz"))
            assert.contains_value("baz", station:getTags())
        end)
        it("fails if a number is given", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            assert.has_error(function()
                station:addTag(42)
            end)
        end)
    end)

    describe("addTags()", function()
        it("allows to batch add tags", function()
            local station = SpaceStation()
            Generic:withTags(station)

            station:addTags("foo", "bar", "baz")

            assert.is_true(station:hasTag("foo"))
            assert.is_true(station:hasTag("bar"))
            assert.is_true(station:hasTag("baz"))
            assert.contains_value("foo", station:getTags())
            assert.contains_value("baz", station:getTags())
            assert.contains_value("bar", station:getTags())
        end)
    end)

    describe("removeTag()", function()
        it("removes a tag if it was set before", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar", "baz")

            station:removeTag("baz")
            local tags = station:getTags()

            assert.is_false(station:hasTag("baz"))
            assert.not_contains_value("baz", tags)
            assert.is_same(2, Util.size(tags))
        end)
        it("fails silently if the tag was not set", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            station:removeTag("baz")
            local tags = station:getTags()

            assert.is_false(station:hasTag("baz"))
            assert.not_contains_value("baz", tags)
            assert.is_same(2, Util.size(tags))
        end)
        it("fails if a number is given", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar")

            assert.has_error(function()
                station:removeTag(42)
            end)
        end)
    end)

    describe("removeTags()", function()
        it("allows to batch remove tags", function()
            local station = SpaceStation()
            Generic:withTags(station, "foo", "bar", "baz")

            station:removeTags("bar", "baz")

            assert.is_true(station:hasTag("foo"))
            assert.is_false(station:hasTag("bar"))
            assert.is_false(station:hasTag("baz"))
            assert.contains_value("foo", station:getTags())
            assert.not_contains_value("baz", station:getTags())
            assert.not_contains_value("bar", station:getTags())
        end)
    end)

end)