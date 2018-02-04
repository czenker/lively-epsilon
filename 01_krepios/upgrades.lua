My = My or {}
My.Upgrades = My.Upgrades or {}

My.Upgrades.speed1 = (function()
    local speed = 80

    return BrokerUpgrade:new({
        name = "Impulsantrieb MkII",
        onInstall = function(upgrade, player)
            player:setImpulseMaxSpeed(speed)
        end,
        id = "speed1",
        price = 250,
        unique = true,
        description = string.format(
            "Der Impulseantrieb MkII ist eine verbesserte Version des serienmäßig in leichten Schiffen verbauten Antriebs. Im Normalbetrieb sind mit ihm Geschwindigkeiten bis zu %0.1fu/min möglich - ein guter Techniker kann aber auch mehr herauskitzeln.",
            speed * 0.06
        ),
    })
end)()

My.Upgrades.speed2 = (function()
    local speed = 95

    return BrokerUpgrade:new({
        name = "Impulsantrieb MkIII",
        onInstall = function(upgrade, player)
            player:setImpulseMaxSpeed(speed)
        end,
        id = "speed2",
        price = 250,
        unique = true,
        requiredUpgrade = "speed1",
        description = string.format(
            "Durch überragende menschliche Konstruktionskunst konnte der Impulsantrieb für kleinere und mittlere Frachter noch weiter optimiert werden. Heraus kam der Impulsantrieb MkIII, der mit einer Maximalgeschwindigkeit %0.1fu/min überzeugt.",
            speed * 0.06
        ),
    })
end)()

My.Upgrades.speed3 = (function()
    local speed = 105

    return BrokerUpgrade:new({
        name = "Impulsantrieb MkIV",
        onInstall = function(upgrade, player)
            player:setImpulseMaxSpeed(speed)
        end,
        id = "speed3",
        price = 250,
        unique = true,
        requiredUpgrade = "speed2",
        description = string.format(
            "Kleinere Verbesserungen an der Materieeinspritzung und die Optimierung des Wirkungsgrads machen den Impulsantrieb MkIV zu einer der besten Optionen für kleine und mittlere Frachter. Seine Höchstgeschwindigkeite liegt bei %0.1fu/min ohne Turbo.",
            speed * 0.06
        ),
    })
end)()

My.Upgrades.rotation1 = (function()
    local speed = 15

    return BrokerUpgrade:new({
        name = "Schubdüsen MkII",
        onInstall = function(upgrade, player)
            player:setRotationMaxSpeed(speed)
        end,
        id = "rotation1",
        price = 150,
        unique = true,
        description = string.format(
            "Eine zielgerichtetere Steuerung der Schubdüsen erhöht die Wendigkeit des Schiffes immens und erlaubt es dem Schiff in weniger als %0.1f Sekunden eine 180° Wende auszuführen.",
            180 / speed
        ),
    })
end)()
My.Upgrades.rotation2 = (function()
    local speed = 20

    return BrokerUpgrade:new({
        name = "Schubdüsen MkIII",
        onInstall = function(upgrade, player)
            player:setRotationMaxSpeed(speed)
        end,
        id = "rotation2",
        price = 200,
        unique = true,
        requiredUpgrade = "rotation1",
        description = string.format(
            "Dieses Update verteilt die Energie zwischen Schubdüsen und Impulsantrieb dynamisch und erlaubt so in weniger als %0.1f Sekunden eine 180° Wende auszuführen.",
            180 / speed
        ),
    })
end)()

My.Upgrades.storage1 = (function()
    local storage = 50

    return BrokerUpgrade:new({
        name = "Lagerraum M",
        onInstall = function(upgrade, player)
            player:setMaxStorageSpace(player:getMaxStorageSpace() + storage)
        end,
        id = "storage1",
        price = 250,
        unique = true,
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player)
        end,
        description = string.format(
            "Durch Erweiterung des Laderaums kann die Ladekapazität eines kleinen oder mittleren Frachters um %d Einheiten erhöht werden.",
            storage
        )
    })
end)()

My.Upgrades.storage2 = (function()
    local storage = 50

    return BrokerUpgrade:new({
        name = "Lagerraum L",
        onInstall = function(upgrade, player)
            player:setMaxStorageSpace(player:getMaxStorageSpace() + storage)
        end,
        id = "storage2",
        price = 250,
        unique = true,
        requiredUpgrade = "storage1",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player)
        end,
        description = string.format(
            "Die Nutzung des Laderaums kann optimiert werden, in dem unnötige Trennwände entfernt und durch intelligente Lagersysteme ersetzt werden. Dadurch können bis zu %d Einheiten mehr gelagert werden.",
            storage
        )
    })
end)()

My.Upgrades.combatManeuver = BrokerUpgrade:new({
    name = "Manöverdüsen BST200",
    onInstall = function(upgrade, player)
        player:setCombatManeuver(250, 150)
    end,
    id = "combat_maneuver",
    price = 250,
    unique = true,
    description = "Manöverdüsen erlaubt schnelle, aber kurze Ausweichmanöver durchzuführen. So erlauben sie Objekten im All auszuweichen oder Raketen ins Leere laufen zu lassen.",
})

My.Upgrades.warpDrive = BrokerUpgrade:new({
    name = "Warp Antrieb X8",
    onInstall = function(upgrade, player)
        player:setWarpDrive(true)
    end,
    price = 1000,
    unique = true,
    canBeInstalled = function(upgrade, player)
        return not player:hasJumpDrive() and not player:hasWarpDrive()
    end,
    description = "Für längere Reisen sind größere Schiffe mit Warp Antrieben ausgerüstet, die Reisen mit Überlichtgeschwindigkeit ermöglichen.\n\nAuf einem Schiff können nur entweder ein Warp Antrieb oder ein Sprung Antrieb installiert werden.",
})

My.Upgrades.jumpDrive = BrokerUpgrade:new({
    name = "Jump Antrieb 30U",
    onInstall = function(upgrade, player)
        player:setJumpDrive(true)
    end,
    price = 1000,
    unique = true,
    canBeInstalled = function(upgrade, player)
        return not player:hasJumpDrive() and not player:hasWarpDrive()
    end,
    description = "Der Sprungantrieb wird häufig von militärischen und paramilitärischen Gruppierungen verwendet um Überraschungsangriffe durch zu führen. Doch auch für längere Reisen ist der Sprungantrieb durchaus geeignet.\n\nAuf einem Schiff können nur entweder ein Warp Antrieb oder ein Sprung Antrieb installiert werden.",
})

My.Upgrades.hvli1 = (function()
    local amount = 4
    local storageMalus = 4

    return BrokerUpgrade:new({
        name = "HVLI Lager M",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("hvli", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "hvli1",
        price = 75,
        unique = true,
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Durch Umbau des Lagerraums kann Platz für %d HVLI Raketen geschaffen werden. Dadurch wird jedoch der Lagerraum um %d Einheiten verringert.", amount, storageMalus),
    })
end)()
My.Upgrades.hvli2 = (function()
    local amount = 8
    local storageMalus = 8

    return BrokerUpgrade:new({
        name = "HVLI Lager L",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("hvli", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "hvli2",
        price = 100,
        unique = true,
        requiredUpgrade = "hvli1",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Eine weitere Verkleinerung des Lagerraums um %d Einheiten schafft Platz für Aufhängungen mit denen insgesamt %d HVLI Raketen gelagert werden können.", storageMalus, amount),
    })
end)()

My.Upgrades.homing1 = (function()
    local amount = 4
    local storageMalus = 4

    return BrokerUpgrade:new({
        name = "Homing Lager M",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("homing", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "homing1",
        price = 100,
        unique = true,
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Durch Umbau des Lagerraums kann Platz für %d Homing Raketen geschaffen werden. Dadurch wird jedoch der Lagerraum um %d Einheiten verringert.", amount, storageMalus),
    })
end)()
My.Upgrades.homing2 = (function()
    local amount = 8
    local storageMalus = 8

    return BrokerUpgrade:new({
        name = "Homing Lager L",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("homing", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "homing2",
        price = 150,
        unique = true,
        requiredUpgrade = "homing1",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Eine weitere Verkleinerung des Lagerraums um %d Einheiten schafft Platz für Aufhängungen mit denen insgesamt %d Homing Raketen gelagert werden können.", storageMalus, amount),
    })
end)()

My.Upgrades.mine1 = (function()
    local amount = 1
    local storageMalus = 8

    return BrokerUpgrade:new({
        name = "Mine Lager S",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("mine", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "mine1",
        price = 150,
        unique = true,
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Durch Einrichtung eines Stasisfelds kann im Lagerraum eine Mine sicher transportiert werden. Der Lagerraum wird durch dem Umbau um %d Einheiten verkleinert.", storageMalus),
    })
end)()
My.Upgrades.mine2 = (function()
    local amount = 2
    local storageMalus = 8

    return BrokerUpgrade:new({
        name = "Mine Lager M",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("mine", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "mine2",
        price = 100,
        unique = true,
        requiredUpgrade = "mine1",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Durch eine Vergrößerung des Stasisfelds können insgesamt %d Minen im Lagerraum untergebracht werden. Dazu wird aber der Lagerraum um weitere %d Einheiten verkleinert.", amount, storageMalus),
    })
end)()
My.Upgrades.mine3 = (function()
    local amount = 4
    local storageMalus = 16

    return BrokerUpgrade:new({
        name = "Mine Lager L",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("mine", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "mine3",
        price = 200,
        unique = true,
        requiredUpgrade = "mine2",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Mit diesem Upgrade kann ein mittlerer Transporter zu einem Behelfs-Minenleger umfunktioniert werden. Mit einer Lagerkapazität von %d Minen können kleinere Minengürtel gelegt werden. Durch das Upgrade werden %d Einheiten im Lagerraum nicht anderweitig nutzbar.", amount, storageMalus),
    })
end)()

My.Upgrades.emp1 = (function()
    local amount = 1
    local storageMalus = 4

    return BrokerUpgrade:new({
        name = "EMP Lager S",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("emp", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "emp1",
        price = 100,
        unique = true,
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("EMP Waffen erlauben das Schild von Schiffen zu deaktivieren ohne die Hülle zu beschädigen. Durch Reduzierung des Lagerraums um %d Einheiten kann Platz zum Lagern einer EMP Rakete geschaffen werden.", storageMalus),
    })
end)()
My.Upgrades.emp2 = (function()
    local amount = 2
    local storageMalus = 4

    return BrokerUpgrade:new({
        name = "Emp Lager M",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("emp", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "emp2",
        price = 75,
        unique = true,
        requiredUpgrade = "emp1",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Durch eine weitere Reduzierung des Lagerraums um %d wird Lagerraum für insgesamt %d EMP Raketen geschaffen.", storageMalus, amount),
    })
end)()
My.Upgrades.emp3 = (function()
    local amount = 4
    local storageMalus = 8

    return BrokerUpgrade:new({
        name = "Emp Lager L",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("emp", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "emp3",
        price = 150,
        unique = true,
        requiredUpgrade = "emp2",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Die Erweiterung des Lagerraums auf %d EMP Raketen ist besonders bei Piraten und Gesetzeshütern sehr beliebt, da im Gegensatz zu konventionellen Raketen kaum bleibende Schäden verursacht werden. Für den Lagerraum muss der Lagerraum um %d Einheiten verkleinert werden.", amount, storageMalus),
    })
end)()

My.Upgrades.nuke1 = (function()
    local amount = 1
    local storageMalus = 16

    return BrokerUpgrade:new({
        name = "Nuke Lager S",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("nuke", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "nuke1",
        price = 300,
        unique = true,
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Um ein konventionelles Lager für Nukes nutzbar zu machen sind größere Umbauten nötig um einen zuverlässigen Strahlenschutz der Besatzung und des restlichen Schiffs zu gewährleisten. Der Lagerraum wird um %d Einheiten reduziert.", storageMalus),
    })
end)()
My.Upgrades.nuke2 = (function()
    local amount = 2
    local storageMalus = 16

    return BrokerUpgrade:new({
        name = "Nuke Lager M",
        onInstall = function(upgrade, player)
            player:setWeaponStorageMax("nuke", amount)
            player:setMaxStorageSpace(player:getMaxStorageSpace() - storageMalus)
        end,
        id = "nuke2",
        price = 200,
        unique = true,
        requiredUpgrade = "nuke1",
        canBeInstalled = function(upgrade, player)
            return Player:hasStorage(player) and player:getMaxStorageSpace() >= storageMalus
        end,
        description = string.format("Größerer Lagerraum für %d Nukes, der auf Kosten von %d Einheiten Lagerraum geht. Dafür wird die militärische Schlagkraft des Schiffes enorm erhöht.", amount, storageMalus),
    })
end)()

My.Upgrades.energy1 = (function()
    local amount = 250
    return BrokerUpgrade:new({
        name = "Power MkII",
        onInstall = function(upgrade, player)
            player:setMaxEnergy(player:getMaxEnergy() + amount)
        end,
        id = "energy1",
        price = 100,
        unique = true,
        description = string.format("Technische Fortschritte der Energiespeicherforschung in den letzten Jahren erlauben höhere Mengen Energie auf gleichem Raum zu speichern. Durch ein Upgrade auf Mikroporen Speichertechnologie kann zusätzliche Energie mit einem Level von %d gespeichert werden.", amount),
    })
end)()

My.Upgrades.energy2 = (function()
    local amount = 250
    return BrokerUpgrade:new({
        name = "Power MkIII",
        onInstall = function(upgrade, player)
            player:setMaxEnergy(player:getMaxEnergy() + amount)
        end,
        id = "energy2",
        price = 100,
        unique = true,
        requiredUpgrade = "energy1",
        description = string.format("Verteilte Energiesysteme sorgen für Redundanz und Ausfallsicherheit. Durch kleinere Energiespeicher direkt an den Komponenten kann sowohl die Speicherkapazität um %d erhöht werden als auch eine bessere Ausfallsicherheit gewährleistet werden.", amount),
    })
end)()

My.Upgrades.energy3 = (function()
    local amount = 500
    local storageMalus = 10

    return BrokerUpgrade:new({
        name = "Power MkIV",
        onInstall = function(upgrade, player)
            player:setMaxEnergy(player:getMaxEnergy() + amount)
        end,
        id = "energy3",
        price = 200,
        unique = true,
        requiredUpgrade = "energy2",
        description = string.format("Zusätzliche Energiespeicher können im Lagerraum installiert werden um die Speicherkapazität um %d zu erhöhen. Dadurch stehen allerdings %d Einheiten weniger im Lager zur Verfügung.", amount, storageMalus),
    })
end)()
