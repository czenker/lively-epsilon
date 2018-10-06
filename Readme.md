# Lively Epsilon

Lively Epsilon is a plugin framework for [Empty Epsilon](https://daid.github.io/EmptyEpsilon/)(EE) that aims
to fill the space with artificial life.

If you are into writing missions this framework might help you create an intriguing universe full
of life that your crew will be eager to explore. You as a Game Master can focus on your plot lines
without needing to entertain all stations at all times.

Think about flying through the galaxy and watching traders ship goods from one station to another,
law-enforcement ships scanning ships, stations answering docking requests of NPCs or just two pilots
having a chat through comms. There is a lot to explore in that galaxy.

### State

The current state is best described as _Let's see where it goes_. Feel free to use it, steal everything
you find useful or drop me a line if you like it.

### Getting Started

Checkout this repo into the ``scripts`` folder of your EE installation or just download the zip from
Github and extract.

If you just want to see some kind of tech demo load up the mission that comes with the repo, start
a Game Master Screen and at least one other instance with all the stations. The Game Master screen
will display different buttons that let you start up certain aspects of the framework.

If you want to use the framework you should already be familiar with writing missions
for EE.

#### Kickstart

The boilerplate code for activating the framework is pretty simple:
```lua
-- Name: Hello Lively Epsilon
-- Description: Testing Lively Epsilon
-- Type: Mission

require "src/lively_epsilon/init.lua"

function init()
    -- add your code here
end

function update(delta)
    Cron.tick(delta)
end
```

#### Storage

Products are maintained in ``resoures/products.lua``. You can extend and reconfigure
the products as needed – those are not used by the framework itself, but should help you
creating the universe.

```lua
require("resources/products.lua")

local station = SpaceStation():setPosition(0, 0)
Station:withStorageRooms(station, {
    [products.power] = 1000,
    [products.o2] = 500,
})

station:canStoreProduct(product.power) -- = true
station:canStoreProduct(product.ore) -- = false

station:getProductStorage(product.power) -- = 0
station:getEmptyProductStorage(product.power) -- = 1000
station:getMaxProductStorage(product.power) -- = 1000

station:modifyProductStorage(product.power, 700)
station:getProductStorage(product.power) -- = 700
station:getEmptyProductStorage(product.power) -- = 300
station:getMaxProductStorage(product.power) -- = 1000

station:modifyProductStorage(product.power, 9999)
station:getProductStorage(product.power) -- = 1000
station:modifyProductStorage(product.power, -1000)
station:getProductStorage(product.power) -- = 0
```

Please note that modifying a product storage beyond its minimum or maximum capacity
does not cause any kind of error. This is to ease scripting for you and not having
to take care of multiple error conditions.

#### Merchant

Having a storage is of course in itself not useful, but stations can have a merchant
that buys or sells goods.

```lua
require("resources/products.lua")

local station = SpaceStation():setPosition(0, 0)
Station:withStorageRooms(station, {
    [products.power] = 1000,
    [products.o2] = 500,
})
Station:withMerchant(station, {
    [products.power] = { buyingPrice = 1, buyingLimit = 420 },
    [products.o2] = { sellingPrice = 5, sellingLimit = 42 },
})

station:modifyProductStorage(product.power, 100)
station:modifyProductStorage(product.o2, 100)

station:isBuyingProduct(product.power)        -- = true
station:getProductBuyingPrice(products.power) -- = 1
station:getMaxProductBuying(product.power)    -- = 320

station:isSellingProduct(product.o2)        -- = true
station:getProductSellingPrice(products.o2) -- = 5
station:getMaxProductSelling(product.o2)    -- = 58
```

Configuring ``buyingLimit`` and ``sellingLimit`` is optional. If left blank the station
will sell and buy all of its stock. In any other case it will only sell if it got
more than ``sellingLimit`` units in store and buy if it got less than ``buyingLimit`` units
in store.

Configuring the merchant will allow any non-enemy ship (including the player) to
buy or sell from the station.

NOTE: There is no concept yet for money. So the prices actually do not matter... ;)

#### Production

Stations with a storage can transform products into other products or even create products from nothing
(think solar energy) or convert products into nothing (think energy again).

```lua
require("resources/products.lua")

local station = SpaceStation():setPosition(0, 0)
Station:withStorageRooms(station, {
    [products.power] = 1000,
    [products.o2] = 500,
})
Station:withProduction(station, {
    {
        productionTime = 30,
        consumes = {
            { product = products.power, amount = 10 }
        },
        produces = {
            { product = products.o2, amount = 10 },
        }
    },
})
```

Combining this with the Merchant can help you create a simple economy that the players can help running.

#### Traders

A trader is assigned to one station and buys one resource on behalf of the station from a different station.
So what you need is a station that sells some product, a station that buys that product and a trader assigned to
the second one.

```lua
require("resources/products.lua")

local seller = SpaceStation():setPosition(0, 0)
Station:withStorageRooms(seller, {
    [products.power] = 1000
})
Station:withMerchant(seller, {
    [products.power] = { sellingPrice = 1 },
})

local buyer = SpaceStation():setPosition(10000, 0)
Station:withStorageRooms(buyer, {
    [products.power] = 1000
})
Station:withMerchant(buyer, {
    [products.power] = { buyingPrice = 1 },
})

local ship = CpuShip():setTemplate("Goods Freighter 1"):setPosition(11000, 0)
Ship:withStorageRooms(ship, {
    [products.power] = 1000,
})
Ship:orderBuyer(ship, buyer, products.power)
```

This trader will try to find a station close to its home base ``buyer`` that sells power, buy it and bring
it back to its home station.

#### Miner

A miner is a different type of ship that will seek out Asteroids close to its home base, mine them and
unload the products at its home base.

```lua
require("resources/products.lua")

local factory = SpaceStation():setPosition(0, 0)
Station:withStorageRooms(factory, {
    [products.ore] = 1000
})

local ship = CpuShip():setTemplate("Goods Freighter 1"):setPosition(11000, 0)
Ship:withStorageRooms(ship, {
    [products.ore] = 1000,
})
Ship:orderBuyer(ship, factory, function(asteroid, ship, station)
    return {
       [products.ore] = math.random(10, 50)
    }
end)
```

Using the callback you can determine which resources the miner finds when it has mined an asteroid. Products
the ship or its home base can not store will be silently discarded.

#### Diving in deeper

Occasionally you will find spec-like tests in the ``test`` folder that should give you
a pretty good idea how things are supposed to work.

### Development

[![Build Status](https://travis-ci.org/czenker/lively-epsilon.svg?branch=master)](https://travis-ci.org/czenker/lively-epsilon)
[![Test Coverage](https://codecov.io/github/czenker/lively-epsilon/branch/master/graphs/badge.svg)](https://codecov.io/gh/czenker/lively-epsilon)

#### Tests

There are very few tests that test libraric functions, but they are by no means any proof that the modules
do what they should. Most of the code can not be tested outside an Empty Epsilon session.

You can run the tests by installing [Busted](https://olivinelabs.com/busted/) and run

```bash
busted
```

#### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
