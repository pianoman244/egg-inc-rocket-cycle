//
//  TankBrain.swift
//  Egg Fueling Demo
//
//  Created by Nathan Chasse on 7/3/21.
//

import UIKit

protocol TankViewController {
    func updateStorageTankUI(storageTank: StorageTank)
    func updateRocketTankUI(rocketTank: RocketTank)
    func handleEndOfStorageTankCycle(storageTank: StorageTank, info: FullCycleData)
    func buildStorageTankUI(tank: StorageTank)
    func buildRocketTankUI(tank: RocketTank)
}

class TankBrain: StorageTankDelegate, RocketTankDelegate {
    
    //MARK: - Initializers/First Loads
    var tanksToCheck: [StorageTank] = [] // Filled in populate() with tanks to be cycled through
    var goodTanks: [StorageTank] = [] // Change this later?
    var delegate: TankViewController?
    var activeTank: StorageTank?
    var activeRocket: RocketTank?
    var activeMissionsLaunched: Int = 0
    var activeTotalMissionsLaunched: Int = 0
    
    /*
     Fills tanksToCheck with a bunch of unique tanks. The smallest "fuel unit" that can fill each tank is equal to the GCD of the decreaseAmounts. tanksToCheck will be filled with all possible tanks where the fuel amounts are multiples of that fuel unit.
     */
    func populate(capacity: Int, decreaseAmounts: [Int], fuelNames: [EggCode]) {
        if decreaseAmounts.count != fuelNames.count {
            print("Bad input to populate(capacity: Int, decreaseAmounts: [Int], fuelNames: [EggCode]) in tankBrain")
            return
        }
        
        let count = decreaseAmounts.count
        let combinations = getSumCombinations(sum: capacity, nums: count)
        for combination in combinations {
            
            let permutations = getPermutations(of: combination, filter: decreaseAmounts)
            for permutation in permutations {
                var fuels: [Fuel] = []
                for i in (0..<count) {
                    fuels.append(Fuel(amount: permutation[i], name: fuelNames[i]))
                }
                tanksToCheck.append(StorageTank(fuels: fuels, decreaseAmounts: decreaseAmounts, capacity: capacity))
            }
        }
    }
    
    /*
     Populates tanksToCheck() with the original working tank.
     */
    func populate() {
        tanksToCheck.append(StorageTank(fuels: [Fuel(amount: 20, name: EggCode.tach), Fuel(amount: 6, name: EggCode.dili), Fuel(amount: 22, name: EggCode.anti), Fuel(amount: 52, name: EggCode.dark)], decreaseAmounts: [1, 3, 3, 3], capacity: 100))
    }
    
    //MARK: - UI Updates
    /**
     Update the UI with the information supplied
     */
    func updateStorageTankUI(tank: StorageTank) {
        delegate?.updateStorageTankUI(storageTank: tank)
    }
    
    func updateRocketTankUI(rocketTank: RocketTank) {
        delegate?.updateRocketTankUI(rocketTank: rocketTank)
    }
    
    /**
     If the tank that just finished cycling is successful, add it to goodTanks
     */
    func handleEndOfCycle(tank: StorageTank, info: FullCycleData) {
        if info.successful {
            if info.originalTank != nil {
                goodTanks.append(info.originalTank!)
            }
        }
        
        delegate?.handleEndOfStorageTankCycle(storageTank: tank, info: info)
    }
    
    func resetActiveMissions() {
        activeMissionsLaunched = 0
    }
    
    func fillRocket() {
        if let tank = activeTank {
            let startingAmounts: [Int] = tank.fuels.map({$0.amount})
            tank.UICycleTimer?.fire()
            let endingAmounts: [Int] = tank.fuels.map({$0.amount})
            
            if let rocket = activeRocket {
                rocket.fillWith(amounts: { () -> [Int] in
                    var amounts: [Int] = []
                    for i in (0..<endingAmounts.count) {
                        amounts.append(abs(startingAmounts[i] - endingAmounts[i]))
                    }
                    return amounts
                }() )
            }
        }
        
    }
    
    func launchRocket() {
        if let rocket = activeRocket {
            rocket.launch()
            activeMissionsLaunched += 1
            activeTotalMissionsLaunched += 1
            updateStorageTankUI(tank: activeTank!)
        }
    }
    
    //MARK: - Cycle methods
    
    /**
     Works through tanksToCheck in the background and adds successful tanks to goodTanks
     */
    func checkTanks(totalCycles: Int, missionsFueled: Int = 0, minConsecMissions: Int = 0)  {
        for tank in tanksToCheck {
            tank.delegate = self
            let cycleInfo = tank.cycle(cyclesLeft: totalCycles)
            if cycleInfo.successful && (cycleInfo.totalMissionsFueled >= missionsFueled && cycleInfo.minConsecMissions >= minConsecMissions) {
                if cycleInfo.originalTank != nil {
                    goodTanks.append(tank)
                }
            }
        }
        
        tanksToCheck = []
    }
    
    func checkTanksDiagnostic(totalCycles: Int, minConsecMissions: Int = 0)  {
        for tank in tanksToCheck {
            tank.delegate = self
            print("\n--------------------")
            print("== Starting cycle ==")
            print("--------------------\n")
            print("\nStarting tank configuration:")
            tank.print()
            Swift.print("\n")
            
            let cycleInfo = tank.cycleWithConsoleUpdates(cyclesLeft: totalCycles)
            
            print("\nSelf before cycle:")
            print(tank.selfBeforeCycle?.print() ?? "idfk")
            print("---\n")
            
            if cycleInfo.successful && cycleInfo.minConsecMissions > minConsecMissions {
                if cycleInfo.originalTank != nil {
                    addTank(cycleInfo.originalTank!)
                }
            }
        }
    }
    
    func findTanks(capacity: Int, decreaseAmounts: [Int], fuelNames: [EggCode], missionsFueled: Int, minConsecMissions: Int = 0, cycleAmountRange: ClosedRange<Int> = (1...5)) {
        
        goodTanks = []
        
        for i in cycleAmountRange {
            populate(capacity: capacity, decreaseAmounts: decreaseAmounts, fuelNames: fuelNames)
            checkTanks(totalCycles: i, missionsFueled: missionsFueled, minConsecMissions: minConsecMissions)
        }
        
        sortTanks()
        
    }
    
    /*
    Adds tank to goodTanks
     */
    func addTank(_ tank: StorageTank) {
        goodTanks.append(tank)
    }
    
    /*
     Adds tank currently being checked to goodTanks
     */
    func addCurrentTank() {
        if let tank = activeTank {
            addTank(tank)
        }
    }
    
    /*
     Print all the tanks in tanksToCheck sequentially
     */
    func printCheckTanks() {
        for tank in tanksToCheck {
            tank.print()
        }
    }
    
    /*
     Print all the tanks in goodTanks if the smallest mission gap is smallestGap
     */
    func printGoodTanks(smallestGap: Int = 0, totalMissions: Int = 0) {
        for tank in goodTanks {
            if tank.minConsecMissions >= smallestGap && tank.totalMissionsFueled >= totalMissions {
                print("Tank before cycle:")
                tank.selfBeforeCycle?.print() ?? Swift.print("selfBeforeCycle doesn't exist for a tank in goodTanks (printGoodTanks)")
                Swift.print("\nTank after cycle:")
                tank.print()
                Swift.print()
            }
        }
        Swift.print("Done printing good tanks")
    }
    
    /*
     Priority of things for a good tank to have:
     1. Lowest totalCyclesCompleted
     2. Highest minConsecMissions
     3. Highest totalMissionsFueled
     4. One of the tanks starts out empty
     */
    func sortTanks() {
        goodTanks.sort() {
            if $0.totalCyclesCompleted == $1.totalCyclesCompleted {
                
                if $0.minConsecMissions == $1.minConsecMissions {
                    
                    if $0.totalMissionsFueled == $1.totalMissionsFueled {
                        
                        if $0.findEmptyTank() != nil && $1.findEmptyTank() != nil {
                            
                            return true
                            
                        } else {
                            
                            if $0.findEmptyTank() == nil {
                                return true
                            } else {
                                return false
                            }
                            
                        }
                        
                    } else {
                        
                        return $0.totalMissionsFueled > $1.totalMissionsFueled
                        
                    }
                    
                } else {
                    
                    return $0.minConsecMissions > $1.minConsecMissions
                    
                }
                
            } else {
                return $0.totalCyclesCompleted < $1.totalCyclesCompleted
            }
            
        }
    }
}

