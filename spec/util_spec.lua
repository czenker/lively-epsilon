insulate("Util", function()

    require "init"
    require "spec.mocks"
    require "spec.asserts"

    describe(":size()", function()
        it("correctly determines size of an empty table", function()
            assert.is.same(Util.size({}), 0)
        end)

        it("correctly determines size of a table with numerical index", function()
            assert.is.same(Util.size({42, "foobar", {}}), 3)
        end)

        it("correctly determines size of a table with object index", function()
            assert.is.same(Util.size({
                foo = 42,
                bar = "baz",
                baz = {}
            }), 3)
        end)

        it("correctly determines size of a table with mixed indices", function()
            assert.is.same(Util.size({
                foo = 42,
                bar = "baz",
                baz = {},
                42,
            }), 4)
        end)
    end)

    describe(":isNumericTable()", function()
        it("returns true on empty table", function()
            assert.is_true(Util.isNumericTable({}))
        end)

        it("returns true on table that only contains numerical indices", function()
            assert.is_true(Util.isNumericTable({1, 2, 3, 4}))
        end)

        it("returns false on table that only contains string indices", function()
            assert.is_false(Util.isNumericTable({one = 1, two = 2, three = 3}))
        end)

        it("returns false on table that contains mixed indices", function()
            assert.is_false(Util.isNumericTable({42, foo = "bar", 2, 3, "bar", baz = 42}))
        end)
    end)

    describe(":random()", function()
        it("returns nil if list is empty", function()
            assert.is_nil(Util.random({}))
        end)

        it("returns an element from a non-empty list with numerical index", function()
            local thing = { foo = "bar" }

            assert.is.equal(Util.random({thing}), thing)
        end)

        it("returns an element from a non-empty list with index", function()
            local thing = { foo = "bar" }

            assert.is.equal(Util.random({foo = thing}), thing)
        end)

        it("returns all items from the list at random", function()
            local thing1 = { foo = "bar" }
            local thing2 = { baz = "bar" }

            local testDummy = {thing1, thing2 }

            local thing1Seen = false
            local thing2Seen = false

            for i=1,16,1 do
                local result = Util.random(testDummy)
                if result == thing1 then thing1Seen = true elseif result == thing2 then thing2Seen = true end
            end

            assert.is_true(thing1Seen)
            assert.is_true(thing2Seen)
        end)

        it("allows to filter elements", function()
            local thing1 = { foo = "bar" }
            local thing2 = { baz = "bar" }
            local thing3 = { blu = "bla" }

            local testDummy = {thing1, thing2, thing3 }

            local thing1Seen = false
            local thing2Seen = false
            local thing3Seen = false

            for i=1,16,1 do
                local result = Util.random(testDummy, function(k, v)
                    return k ~= 3
                end)
                if result == thing1 then thing1Seen = true elseif result == thing2 then thing2Seen = true elseif result == thing3 then thing3Seen = true end
            end

            assert.is_true(thing1Seen)
            assert.is_true(thing2Seen)
            assert.is_false(thing3Seen)
        end)

        it("returns nil if the filter does not leave any item", function()
            assert.is_nil(Util.random({1, 2, 3, 4}, function() return false end))
        end)
    end)

    describe(":randomSort()", function()
        it("randomly sorts a numeric list", function()
            local input = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
            local output = Util.randomSort(input)

            assert.is_table(output)
            assert.is_same(16, Util.size(output))
            assert.contains_value(8, output)
            assert.is_true(Util.isNumericTable(output))
            assert.not_same(input, output)
        end)
        it("returns different results each time in a numeric list", function()
            local input = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
            local output1 = Util.randomSort(input)
            local output2 = Util.randomSort(input)

            assert.not_same(output1, output2)
        end)
        it("randomly sorts a named list", function()
            local input = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8, i=9, j=10, k=11, l=12, m=13, n=14, o=15, p=16}
            local output = Util.randomSort(input)

            assert.is_table(output)
            assert.is_same(16, Util.size(output))
            assert.contains_value(8, output)
            assert.is_true(Util.isNumericTable(output))
            assert.not_same(input, output)
        end)
        it("returns different results each time in a numeric list", function()
            local input = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8, i=9, j=10, k=11, l=12, m=13, n=14, o=15, p=16}
            local output1 = Util.randomSort(input)
            local output2 = Util.randomSort(input)

            assert.not_same(output1, output2)
        end)
        it("fails if no table is given", function()
            assert.has_error(function() Util.randomSort() end)
        end)
    end)

    describe(":keys()", function()
        it("returns the keys of a table in an arbitrary order", function()
            local input = {
                foo = "bar",
                baz = "blubb",
                number = 42,
            }
            local output = Util.keys(input)

            assert.is_table(output)
            assert.is_same(3, Util.size(output))
            assert.contains_value("foo", output)
            assert.contains_value("baz", output)
            assert.contains_value("number", output)
            assert.is_true(Util.isNumericTable(output))
        end)
        it("fails if no table is given", function()
            assert.has_error(function() Util.keys() end)
            assert.has_error(function() Util.keys(42) end)
        end)
    end)

    describe(":onVector()", function()
        it("returns point 1 when ratio is 0", function()
            local x, y = Util.onVector(1000, 2000, 3000, 4000, 0)
            assert.is_same({1000, 2000}, {x, y})
        end)
        it("returns point 2 when ratio is 1", function()
            local x, y = Util.onVector(1000, 2000, 3000, 4000, 1)
            assert.is_same({3000, 4000}, {x, y})
        end)
        it("returns a point between point 1 and point 2", function()
            local x, y = Util.onVector(1000, 2000, 3000, 4000, 0.5)
            assert.is_same({2000, 3000}, {x, y})
        end)
        it("works with two objects", function()
            local ship1 = CpuShip():setPosition(1000, 2000)
            local ship2 = CpuShip():setPosition(3000, 4000)
            local x, y = Util.onVector(ship1, ship2, 0.5)
            assert.is_same({2000, 3000}, {x, y})
        end)
        it("works with an object and coordinates", function()
            local ship = CpuShip():setPosition(1000, 2000)
            local x, y = Util.onVector(ship, 3000, 4000, 0.5)
            assert.is_same({2000, 3000}, {x, y})
        end)
        it("works with coordinate and an object", function()
            local ship = CpuShip():setPosition(3000, 4000)
            local x, y = Util.onVector(1000, 2000, ship, 0.5)
            assert.is_same({2000, 3000}, {x, y})
        end)
    end)

    describe(":randomUuid()", function()
        it("should return a 16 digit hex", function()
            local uuid = Util.randomUuid()
            assert.not_nil(uuid:match("^([0-9a-f]+)$"))
            assert.equal(uuid:len(), 16)
        end)

        it("should not return the same uuid twice", function()
            local uuid = Util.randomUuid()
            local uuid2 = Util.randomUuid()
            assert.not_equal(uuid, uuid2)
        end)
    end)

    describe(":deepCopy()", function()
        it("should copy primitive types", function()
            local thing = {
                foo = "bar",
                baz = 42
            }
            local copied = Util.deepCopy(thing)

            thing.foo = "fake"
            thing.baz = 12
            thing.blu = "some"

            assert.equal("bar", copied.foo)
            assert.equal(42, copied.baz)
            assert.is_nil(copied.blu)
        end)

        it("should not copy objects from Empty Epsilon", function()
            -- Copying them would cause the object to exists twice in memory.
            -- This would cause an inconsistent state and might cause the game to crash
            -- because of access to invalid memory segments.

            require "spec.mocks"

            local thing = {
                foo = "bar",
                station = SpaceStation()
            }
            local copied = Util.deepCopy(thing)

            thing.station.foo = "bar"

            assert.same("bar", copied.station.foo)
        end)
    end)

    describe(":mkString()", function()
        describe("with lastSeparator parameter", function()
            it("should return an empty string if table is empty", function()
                local table = {}

                assert.equal(Util.mkString(table, ", ", " and "), "")
            end)

            it("should return a string for a single value", function()
                local table = { "one" }

                assert.equal(Util.mkString(table, ", ", " and "), "one")
            end)

            it("should return a string for two values", function()
                local table = { "one", "two" }

                assert.equal(Util.mkString(table, ", ", " and "), "one and two")
            end)

            it("should return a string for three values", function()
                local table = { "one", "two", "three" }

                assert.equal(Util.mkString(table, ", ", " and "), "one, two and three")
            end)

            it("should fail when using an associative table", function()
                local table = { a = "one", c = "two", b = "three" }

                assert.has_error(function()
                    Util.mkString(table, ", ", " and ")
                end)
            end)
        end)

        it("should return a string if lastSeparator is left out", function()
            local table = { "one", "two", "three" }

            assert.equal(Util.mkString(table, ", "), "one, two, three")
        end)
    end)

    describe(":round()", function()
        it("rounds mathematically correct for positive numbers", function()
            assert.is_same(42, Util.round(42))
            assert.is_same(42, Util.round(42.1))
            assert.is_same(42, Util.round(42.4))
            assert.is_same(42, Util.round(42.49))
            -- because of float magic do not test 42.5 directly
            assert.is_same(43, Util.round(42.51))
            assert.is_same(43, Util.round(42.6))
            assert.is_same(43, Util.round(42.9))
        end)
        it("rounds mathematically correct for negative numbers", function()
            assert.is_same(-42, Util.round(-42))
            assert.is_same(-42, Util.round(-42.1))
            assert.is_same(-42, Util.round(-42.4))
            assert.is_same(-42, Util.round(-42.49))
            -- because of float magic do not test -42.5 directly
            assert.is_same(-43, Util.round(-42.51))
            assert.is_same(-43, Util.round(-42.6))
            assert.is_same(-43, Util.round(-42.9))
        end)
        it("can round to different bases", function()
            assert.is_same(40, Util.round(42, 5))
            assert.is_same(42, Util.round(42, 7))
            assert.is_same(40, Util.round(42, 10))
        end)
        it("can correctly round to a base of 10", function()
            assert.is_same(0, Util.round(0, 10))
            assert.is_same(0, Util.round(1, 10))
            assert.is_same(0, Util.round(4, 10))
            assert.is_same(0, Util.round(4.9, 10))
            assert.is_same(10, Util.round(5.1, 10))
            assert.is_same(10, Util.round(6, 10))
            assert.is_same(10, Util.round(9, 10))
            assert.is_same(10, Util.round(10, 10))
        end)
    end)

    describe(":mergeTables()", function()
        it("returns a new table where all items and from the second are present", function()
            local a = {a = 1, b = 2}
            local b = {c = 3, d = 4}

            local merged = Util.mergeTables(a, b)
            assert.is_same({a = 1, b = 2, c = 3, d = 4}, merged)
            -- ensure the original tables are not overridden
            assert.not_same(a, merged)
            assert.not_same(b, merged)
        end)
        it("the second table overrides the first one", function()
            local a = {a = 1, b = 2}
            local b = {b = 3, c = 4}

            local merged = Util.mergeTables(a, b)
            assert.is_same({a = 1, b = 3, c = 4}, merged)
        end)
        it("can merge three tables", function()
            local a = {a = 1, b = 2}
            local b = {b = 3, c = 4}
            local c = {c = 5, d = 6}

            local merged = Util.mergeTables(a, b, c)
            assert.is_same({a = 1, b = 3, c = 5, d = 6}, merged)
            -- ensure the original tables are not overridden
            assert.not_same(a, merged)
            assert.not_same(b, merged)
            assert.not_same(c, merged)
        end)
        it("fails if the first argument is not a table", function()
            assert.has_error(function() Util.mergeTables(42, {a = 1}) end)
        end)
        it("fails if the second argument is not a table", function()
            assert.has_error(function() Util.mergeTables({a = 1}, 42) end)
        end)
    end)

    describe(":appendTables()", function()
        it("returns a new table where all the items of all tables are present", function()
            local a = {1, 2}
            local b = {3, 4}

            local merged = Util.appendTables(a, b)
            assert.is_same({1, 2, 3, 4}, merged)

            -- ensure the original tables are not overridden
            assert.not_same(a, merged)
            assert.not_same(b, merged)
        end)
        it("does not remove duplicates", function()
            local a = {1, 3}
            local b = {3, 7}

            local merged = Util.appendTables(a, b)
            assert.is_same({1, 3, 3, 7}, merged)

            -- ensure the original tables are not overridden
            assert.not_same(a, merged)
            assert.not_same(b, merged)
        end)
        it("can merge three tables", function()
            local a = {1, 2}
            local b = {3, 4}
            local c = {5, 6}

            local merged = Util.appendTables(a, b, c)
            assert.is_same({1, 2, 3, 4, 5, 6}, merged)
            -- ensure the original tables are not overridden
            assert.not_same(a, merged)
            assert.not_same(b, merged)
            assert.not_same(c, merged)
        end)
        it("fails if the first argument is not a numeric table", function()
            assert.has_error(function() Util.appendTables(42, {1}) end)
            assert.has_error(function() Util.appendTables(nil, {1}) end)
        end)
        it("fails if the second argument is not a table", function()
            assert.has_error(function() Util.appendTables({1}, 42) end)
        end)

    end)

    describe(":vectorFromAngle()", function()
        it ("has the x axis for 0 degree", function()
            local x, y = Util.vectorFromAngle(0, 1000)

            assert.is_same(1000, math.floor(x))
            assert.is_same(0, math.floor(y))
        end)
        it ("it works with degrees", function()
            local x, y = Util.vectorFromAngle(180, 1000)

            assert.is_same(-1000, math.floor(x))
            assert.is_same(0, math.floor(y))
        end)
        it ("it works counter clockwise", function()
            local x, y = Util.vectorFromAngle(90, 1000)

            assert.is_same(0, math.floor(x))
            assert.is_same(1000, math.floor(y))
        end)
    end)

    describe(":addVector()", function()
        it("returns the point when adding a vector of zero length", function()
            local x, y = Util.addVector(0, 0, 180, 0)
            assert.is_same({0, 0}, {x, y})
        end)
        it ("has the x axis for 0 degree", function()
            local x, y = Util.addVector(1000, 0, 0, 1000)

            assert.is_same(2000, math.floor(x))
            assert.is_same(0, math.floor(y))
        end)
        it ("it works with degrees", function()
            local x, y = Util.addVector(1000, 0, 180, 1000)

            assert.is_same(0, math.floor(x))
            assert.is_same(0, math.floor(y))
        end)
        it ("it works counter clockwise", function()
            local x, y = Util.addVector(1000, 0, 90, 1000)

            assert.is_same(1000, math.floor(x))
            assert.is_same(1000, math.floor(y))
        end)
        it ("it works with SpaceObject", function()
            local ship = CpuShip():setPosition(1337, 42)
            local x, y = Util.addVector(ship, 90, 1000)

            assert.is_same(1337, math.floor(x))
            assert.is_same(1042, math.floor(y))
        end)
    end)

    describe(":angleFromVector()", function()
        it ("has the x axis for 0 degree", function()
            local angle, distance = Util.angleFromVector(1000, 0)

            assert.is_same(0, math.floor(angle))
            assert.is_same(1000, math.floor(distance))
        end)
        it ("it works with degrees", function()
            local angle, distance = Util.angleFromVector(-1000, 0)

            assert.is_same(180, math.floor(angle))
            assert.is_same(1000, math.floor(distance))
        end)
        it ("it works counter clockwise", function()
            local angle, distance = Util.angleFromVector(0, 1000)

            assert.is_same(90, math.floor(angle))
            assert.is_same(1000, math.floor(distance))
        end)
    end)

    describe(":distanceToLineSegment()", function()
        it("fails if any argument is not a number", function()
            assert.has_error(function() Util.distanceToLineSegment(0, 0, 1000, 0, 0, "") end)
            assert.has_error(function() Util.distanceToLineSegment(0, 0, 1000, 0, "", 0) end)
            assert.has_error(function() Util.distanceToLineSegment(0, 0, 1000, "", 0, 0) end)
            assert.has_error(function() Util.distanceToLineSegment(0, 0, "fo", 0, 0, 0) end)
            assert.has_error(function() Util.distanceToLineSegment(0, "", 1000, 0, 0, 0) end)
            assert.has_error(function() Util.distanceToLineSegment("", 0, 1000, 0, 0, 0) end)
        end)
        it("fails if start and end are identical", function()
            assert.has_error(function() Util.distanceToLineSegment(0, 0, 0, 0, 0, 0) end)
            assert.has_error(function() Util.distanceToLineSegment(100, 0, 100, 0, 0, 0) end)
        end)
        it("returns 0 if point is on the line segment", function()
            assert.is_same(0, Util.distanceToLineSegment(0, 0, 1000, 0, 0, 0))
            assert.is_same(0, Util.distanceToLineSegment(0, 0, 1000, 0, 1000, 0))
            assert.is_same(0, Util.distanceToLineSegment(0, 0, 1000, 0, 500, 0))
        end)
        it("returns distance if point is on the line, but outside the segment", function()
            assert.is_same(1000, Util.distanceToLineSegment(0, 0, 1000, 0, 2000, 0))
            assert.is_same(500, Util.distanceToLineSegment(0, 0, 1000, 0, -500, 0))
        end)
        it("returns distance of a point from a line segment (when closest point is on the line)", function()
            assert.is_same(200, Util.distanceToLineSegment(
                0, 0,
                1000, 0,
                500, 200
            ))
            assert.is_same(200, Util.distanceToLineSegment(
                0, 0,
                1000, 0,
                500, -200
            ))

            -- the same shifted to the right
            assert.is_same(200, Util.distanceToLineSegment(
                300, 0,
                1300, 0,
                800, 200
            ))
            assert.is_same(200, Util.distanceToLineSegment(
                300, 0,
                1300, 0,
                800, -200
            ))

            -- and now rotate the whole thing
            for _, deg in pairs({30, 45, 60, 90, 120, 150}) do
                deg = deg / 180 * math.pi
                local rotate = function(x, y)
                    return math.cos(deg) * x - math.sin(deg) * y, math.sin(deg) * x + math.cos(deg) * y
                end

                local startX, startY = rotate(300, 0)
                local endX, endY = rotate(1300, 0)

                local x1, y1 = rotate(800, 200)
                assert.is_same(200, Util.round(Util.distanceToLineSegment(startX, startY, endX, endY, x1, y1)))

                local x2, y2 = rotate(800, -200)
                assert.is_same(200, Util.round(Util.distanceToLineSegment(startX, startY, endX, endY, x2, y2)))
            end
        end)
        it("returns distance of a point from a line segment (when closest point is the end)", function()
            assert.is_same(200, Util.distanceToLineSegment(300, 0, 1300, 0, 1300, 200))
            assert.is_same(200, Util.distanceToLineSegment(300, 0, 1300, 0, 1300, -200))
        end)

        it("returns distance of a point from a line segment (when closest point is the start)", function()
            assert.is_same(200, Util.distanceToLineSegment(300, 0, 1300, 0, 300, 200))
            assert.is_same(200, Util.distanceToLineSegment(300, 0, 1300, 0, 300, -200))
        end)
        it("can use objects instead of positions", function()
            local start = CpuShip():setPosition(300, 0)
            local stop = CpuShip():setPosition(1300, 0)
            local point = CpuShip():setPosition(1300, 200)

            assert.is_same(200, Util.distanceToLineSegment(300, 0, 1300, 0, 1300, 200))
            assert.is_same(200, Util.distanceToLineSegment(start, 1300, 0, 1300, 200))
            assert.is_same(200, Util.distanceToLineSegment(300, 0, stop, 1300, 200))
            assert.is_same(200, Util.distanceToLineSegment(300, 0, 1300, 0, point))
            assert.is_same(200, Util.distanceToLineSegment(start, stop, 1300, 200))
            assert.is_same(200, Util.distanceToLineSegment(start, 1300, 0, point))
            assert.is_same(200, Util.distanceToLineSegment(300, 0, stop, point))
            assert.is_same(200, Util.distanceToLineSegment(start, stop, point))
        end)
    end)

    describe(":heading()", function()
        it("takes positive y axis as 180°", function()
            local one, two = CpuShip(), CpuShip()
            one:setPosition(0, 0)
            two:setPosition(0, 1000)

            assert.is_same(180, Util.heading(one, two))
        end)
        it("goes clockwise", function()
            local one, two = CpuShip(), CpuShip()
            one:setPosition(0, 0)

            two:setPosition(-1000, 0)
            assert.is_same(270, Util.heading(one, two))

            two:setPosition(0, -1000)
            assert.is_same(0, Util.heading(one, two))

            two:setPosition(1000, 0)
            assert.is_same(90, Util.heading(one, two))
        end)
        it("works with coordinates as second argument", function()
            local ship = CpuShip()
            ship:setPosition(0, 0)
            assert.is_same(270, Util.heading(ship, -1000, 0))
        end)
        it("works with coordinates as first argument", function()
            local ship = CpuShip()
            ship:setPosition(-1000, 0)
            assert.is_same(270, Util.heading(0, 0, ship))
        end)
        it("works with coordinates only", function()
            assert.is_same(270, Util.heading(0, 0, -1000, 0))
        end)
        it("raises an error if used incorrectly", function()
            assert.has_error(function()
                Util.heading()
            end)
            assert.has_error(function()
                Util.heading("foo")
            end)
            assert.has_error(function()
                Util.heading(12, 13, 14)
            end)
            assert.has_error(function()
                Util.heading(12, CpuShip())
            end)
        end)
    end)

    describe(":angleDiff()", function()
        it("returns correct results", function()
            assert.is_same(20, Util.angleDiff(10, 30))
            assert.is_same(-20, Util.angleDiff(30, 10))
            assert.is_same(20, Util.angleDiff(350, 10))
            assert.is_same(-20, Util.angleDiff(10, 350))
        end)
    end)

    describe(":map()", function()
        it("maps values and retains keys", function()
            local input = {a=1, b=2, c=3}
            local output = Util.map(input, function(value) return value+1 end)

            assert.is_same({a=2, b=3, c=4}, output)
            assert.not_same(input, output) -- it should not change in-place
        end)
        it("makes the keys available in the function", function()
            local input = {a=1, b=2, c=3}
            local output = Util.map(input, function(value, key) return key .. value end)

            assert.is_same({a="a1", b="b2", c="c3"}, output)
            assert.not_same(input, output) -- it should not change in-place
        end)
        it("maps a numberic table", function()
            local input = {1, 2, 3, 4}
            local output = Util.map(input, function(value) return value+1 end)

            assert.is_same({2, 3, 4, 5}, output)
            assert.not_same(input, output) -- it should not change in-place
        end)
        it("fails when first argument is not a table", function()
            assert.has_error(function()
                Util.map(42, function() end)
            end)
        end)
        it("fails when second argument is not a function", function()
            assert.has_error(function()
                Util.map({}, 42)
            end)
        end)
    end)
end)