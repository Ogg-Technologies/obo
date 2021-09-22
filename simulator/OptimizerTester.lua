local simulator = require("simulator.Simulator")
local mockDrones = require("simulator.MockDrones")
local luaUtils = require("utils.luaUtils")

local function calculateAvgGenerationsRequired(nrOfSimulations, startingDrones,
                                               startingPrincess, target,
                                               optimizer, verbose)
    local generationsRequired = {}
    for simulationIndex = 1, nrOfSimulations do
        local nrGenerations = simulator.performSimulation(startingDrones,
                                                          startingPrincess,
                                                          target, optimizer,
                                                          verbose)
        if nrGenerations == nil then
            -- One simulation was never completed
            return nil
        end
        generationsRequired[simulationIndex] = nrGenerations
    end
    local avgGenerationsRequired = luaUtils.average(generationsRequired)
    if verbose then
        print(avgGenerationsRequired .. " generations required on average")
    end
    return avgGenerationsRequired
end

local badDrone = mockDrones.createDrones({
    species = "Forest",
    speed = 0.4,
    fertility = 1,
    lifespan = 30,
    tolerantFlyer = false,
    caveDwelling = false,
    nocturnal = false
})

local allDrones = {
    mockDrones.createDrones({species = "Imperial"}, 32), -- good traits, wrong species
    mockDrones.createDrones({species = "Cultivated"}, 32, badDrone) -- bad traits, correct species
}

local currentPrincess = mockDrones.createDrones({}, 1, badDrone) -- princess bad traits, wrong species

local target = {
    caveDwelling = {trait = true, importance = 1},
    effect = {trait = "None", importance = 1},
    fertility = {trait = 4.0, importance = 1},
    flowerProvider = {trait = "Flowers", importance = 1},
    lifespan = {trait = 10.0, importance = 1},
    nocturnal = {trait = true, importance = 1},
    species = {trait = "Cultivated", importance = 1},
    speed = {trait = 1.2000000476837, importance = 1},
    tolerantFlyer = {trait = true, importance = 1}
}

local optimizer = require("optimizers.MixingOptimizer")

print(calculateAvgGenerationsRequired(200, allDrones, currentPrincess, target,
                                      optimizer, true))
