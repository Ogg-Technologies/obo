local species = "Enderium" -- e.g. Industrious, Cultivated, Imperial
return {
    target = {
        caveDwelling = { trait = true, importance = 1 },
        effect = { trait = "None", importance = 1 },
        fertility = { trait = 4.0, importance = 1 },
        flowerProvider = { trait = "Flowers", importance = 1 },
        humidityTolerance = { trait = "Both 5", importance = 1 },
        lifespan = { trait = 10.0, importance = 1 },
        nocturnal = { trait = true, importance = 1 },
        species = { trait = species, importance = 1 },
        speed = { trait = 2.0, importance = 1 },
        temperatureTolerance = { trait = "Both 5", importance = 1 },
        tolerantFlyer = { trait = true, importance = 1 }
    },
    runSimulations = true
}
