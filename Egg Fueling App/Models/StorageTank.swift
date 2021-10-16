//
//  StorageTank.swift (originally Tank.swift)
//  Egg Fueling Demo
//
//  Created by Nathan Chasse on 7/3/21.
//

import Foundation

struct Fuel {
    var amount: Int
    var name: EggCode
}

struct FullCycleData {
    let originalTank: StorageTank?
    let totalMissionsFueled: Int
    let totalCyclesCompleted: Int
    let minConsecMissions: Int
    let successful: Bool
    let individualCycleData: [IndividualCycleData]
}

struct IndividualCycleData {
    let missionsFueled: Int
    let activeFuel: EggCode
    let successful: Bool
}

protocol StorageTankDelegate {
    func updateStorageTankUI(tank: StorageTank)
    func handleEndOfCycle(tank: StorageTank, info: FullCycleData)
    var activeRocket: RocketTank? { get set }
}

class StorageTank {
    //MARK: - Initializers
    var fuels: [Fuel]
    var capacity: Int
    var missionsFueled: Int = 0
    var minConsecMissions: Int
    var decreaseAmounts: [Int]
    var activeFuelID: Int = 0
    var delegate: StorageTankDelegate?
    var selfBeforeCycle: StorageTank?
    var totalCyclesCompleted: Int = 0
    var totalMissionsFueled: Int = 0
    var cycleData: [IndividualCycleData] = []
    var ranOnEmpty: Bool = false
    var UICycleTimer: Timer?
    
    init(fuels: [Fuel], decreaseAmounts: [Int], capacity: Int, isCopy: Bool = false) {
        // Initialize variables
        self.fuels = fuels
        self.capacity = capacity
        self.minConsecMissions = capacity
        self.decreaseAmounts = decreaseAmounts
        
        // Set the activeFuel to the fuel that can supply the least amount of missions
        self.activeFuelID = findMinMissionsLeft()
        
        if !isCopy {
            selfBeforeCycle = self.copy()
        }
    }
    
    func copy() -> StorageTank {
        return StorageTank(fuels: self.fuels, decreaseAmounts: self.decreaseAmounts, capacity: self.capacity, isCopy: true)
    }
    
    //MARK: - Status methods
    /**
     Prints each fuel and their corresponding amount to the console.
     */
    func print() {
        for i in (0..<fuels.count) {
            Swift.print("\(EggNames[fuels[i].name] ?? "Unknown Fuel"): \(fuels[i].amount)     Decrease: \(decreaseAmounts[i])")
        }
        Swift.print("Active fuel: \(EggNames[fuels[activeFuelID].name] ?? "Unknown Fuel")")
        Swift.print("Minimum consecutive missions: \(minConsecMissions)")
        Swift.print("Total missions fueled: \(totalMissionsFueled)")
        Swift.print("Total cycles completed: \(totalCyclesCompleted)")
    }
    
    func updateUI() {
        if self.delegate?.updateStorageTankUI(tank: self) == nil {
            Swift.print("Failed to call updateUI in StorageTank:")
            self.print()
        }
    }
    
    /**
     Returns the amount of missions that the tank can fuel with the fuel stored at fuels[id] based on decreaseAmounts[id].
     */
    func missionsLeft(id: Int) -> Int {
        return(Int(fuels[id].amount/decreaseAmounts[id]))
    }
    
    /**
     Returns the index of the fuel in self.fuels that can supply the least amount of missions.
     */
    func findMinMissionsLeft() -> Int {
        var minMissionsLeft: Int = 100
        for i in (0..<fuels.count) {
            if missionsLeft(id: i) < minMissionsLeft {
                minMissionsLeft = missionsLeft(id: i)
            }
        }
        
        for i in (0..<fuels.count) {
            if missionsLeft(id: i) == minMissionsLeft {
                return i
            }
        }
        
        return -1
    }
    
    /**
     If there is enough fuel to fully supply a mission according to the decreaseAmounts parameters, returns true. Otherwise returns false.
     */
    func canFill() -> Bool {
        for i in (0..<fuels.count) {
            if fuels[i].amount < decreaseAmounts[i] && !(i == activeFuelID) {
                return false
            }
        }
        return true
    }
    
    /**
     Returns the total amount of unused space in the current tank
     */
    func calculateSpace() -> Int {
        var space: Int = self.capacity
        for fuel in fuels {
            space -= fuel.amount
        }
        
        return space
    }
    
    /**
     Returns index of first empty fuel in self.fuels
     If no fuels are empty, return nil
     */
    func findEmptyTank() -> Int? {
        for i in (0..<fuels.count) {
            if fuels[i].amount == 0 {
                return i
            }
        }
        return nil
    }
    
    func getFullCycleData(successful: Bool) -> FullCycleData {
        return FullCycleData(originalTank: selfBeforeCycle, totalMissionsFueled: totalMissionsFueled, totalCyclesCompleted: totalCyclesCompleted, minConsecMissions: minConsecMissions, successful: successful, individualCycleData: cycleData)
    }
    
    func getIndividualCycleData(successful: Bool) -> IndividualCycleData {
        return IndividualCycleData(missionsFueled: missionsFueled, activeFuel: fuels[activeFuelID].name, successful: successful)
    }
    
    func addIndividualCycleData(successful: Bool) {
        cycleData.append(IndividualCycleData(missionsFueled: missionsFueled, activeFuel: fuels[activeFuelID].name, successful: successful))
    }
    
    //MARK: - Cycle methods
    /**
     Decreases all fuel amounts by their corresponding decreaseAmount, fills empty space left over with active fuel, and increases self.consecMissions by 1
     Will decrease fuels below 0 so be careful when using
     */
    func runMission(cyclingWithUIUpdates: Bool = false) {
        for i in (0..<fuels.count) {
            // Make sure rocket currently being fueled isn't already full of this type of fuel
            if cyclingWithUIUpdates {
                if let rocket = delegate?.activeRocket {
                    if !(rocket.fuels[i].amount == rocket.fuelCapacities[i]) {
                        fuels[i].amount -= decreaseAmounts[i]
                    }
                }
            } else {
                fuels[i].amount -= decreaseAmounts[i]
            }
        }
        
        fillActiveFuel()
    }
    
    /**
     Runs a mission. If some fuel amounts go below 0, it sets them back to 0. If exactly one fuel amount was set to 0 (i.e. only one tank was emptied by the mission run), returns the index of the emptied tank. Otherwise returns nil
     */
    func runOnEmpty(cyclingWithUIUpdates: Bool = false) -> Int? {
        runMission(cyclingWithUIUpdates: cyclingWithUIUpdates)
        
        var count: Int = 0
        var id: Int?
        
        for i in (0..<fuels.count) {
            if fuels[i].amount <= 0 {
                // Correct for emptying the tank to negative fuel values (better to run this
                // one time here instead of checking it every time runMission is called?)
                fuels[activeFuelID].amount += fuels[i].amount
                fuels[i].amount = 0
                id = i
                count += 1
            }
        }
        
        fillActiveFuel()
        
        if count == 1 {
            return id!
        } else {
            return nil
        }
    }
    
    /**
     Sets activeFuelID (the index of the tank currently being filled) to tankID.
     */
    func setActiveFuel(tankID: Int) {
        activeFuelID = tankID
    }
    
    /**
     Fills the currently active fuel until the tank is full to capacity.
     */
    func fillActiveFuel() {
        fuels[activeFuelID].amount += self.calculateSpace()
    }
    
    /**
     Fuels rockets and switches the active fuel when necessary until either the tank has cycled cyclesLeft times or two or more fuels are empty at once. Returns a custom FullCycleData object containing all relevant information about the cycles completed by this method. See comments within the function for more extensive documentation.
     */
    func cycle(cyclesLeft: Int) -> FullCycleData {
        
        // Run missions until there isn't enough fuel in one or more of the tanks
        
        missionsFueled = 0
        
        // The mission partially fueled at the end of the last cycle needs to be counted, but it shouldn't be counted until it is fully fueled which is why it is counted at the beginning of the following cycle
        if ranOnEmpty {
            missionsFueled += 1
            ranOnEmpty = false
        }
         
        // Run missions until at least one of the tanks can't supply another mission
        while self.canFill() {
            self.runMission()
            missionsFueled += 1
            totalMissionsFueled += 1
        }
        
        // Update the minimum number of missions completed consecutively in a single cycle if necessary
        if missionsFueled < minConsecMissions {
            minConsecMissions = missionsFueled
        }
        
        // Update total number of cycles completed
        totalCyclesCompleted += 1
        
        // runOnEmpty() fills up the current mission with whatever fuel is available and activeTank with space left. If two or more tanks are empty after doing that, runOnEmpty() will return nil and go to the else clause. There should never be more than one empty tank after a cycle because that would require switching farms twice
        if let id = self.runOnEmpty() {
            
            ranOnEmpty = true
            
            // Add the data for this cycle
            addIndividualCycleData(successful: true)
            
            // Set the new active fuel to the empty tank found in runOnEmpty(). This is done after adding the data for this cycle because the cycle data should reflect the active fuel during the cycle, not the active fuel of the next cycle
            self.setActiveFuel(tankID: id)
            
            if cyclesLeft > 1 {
                // If all fuel types haven't been cycled through yet, keep cycling
                // This is > 1 and not > 0 because when this function is called with cyclesLeft = 1 (i.e. > 0), it should stop after that cycle is done and if it was > 0 the function would perform 1 more cycle
                
                return(self.cycle(cyclesLeft: cyclesLeft - 1)) // This is the recursive part. The "base cases" are either this tank successfully finishes cycling or it has an unsuccessful cycle and stops (the else clauses)
                
            } else {
                // This is a successful configuration. Stop cycling and return the full cycle data
                return getFullCycleData(successful: true)
            }
            
        } else {
            
            addIndividualCycleData(successful: false)
            
            // This is a bad configuration. Stop cycling and return full cycle data
            return getFullCycleData(successful: false)
        }
    }
    
    /**
     Runs a full tank cycle and updates the console with print statements every step of the way. Refer to cycle() for more extensive documentation. The function is identical other than the print statements.
     */
    func cycleWithConsoleUpdates(cyclesLeft: Int) -> FullCycleData {
        
        missionsFueled = 0
        
        Swift.print("Beginning cycle with tank:")
        self.print()
        Swift.print("\n-- Running missions --")
        
        // The mission partially fueled at the end of the last cycle needs to be counted, but it shouldn't be counted until it is fully fueled which is why it is counted at the beginning of the following cycle
        if ranOnEmpty {
            missionsFueled += 1
            totalMissionsFueled += 1
            Swift.print("\nNote: This cycle started with a partially fueled rocket from last cycle that was filled at the start of this cycle")
            ranOnEmpty = false
        }
        
        while self.canFill() {
            
            Swift.print("\nMissions fueled so far: \(missionsFueled)\n")
            
            self.runMission()
            missionsFueled += 1
            totalMissionsFueled += 1
            
            self.print()
            
        }
        
        if missionsFueled < minConsecMissions {
            minConsecMissions = missionsFueled
        }
        
        totalCyclesCompleted += 1
        
        if let id = self.runOnEmpty() {
            
            ranOnEmpty = true
            
            self.addIndividualCycleData(successful: true)
            self.setActiveFuel(tankID: id)
            
            Swift.print("\nTotal missions done: \(missionsFueled)\n")
            Swift.print("-- Done running missions -- \n")
            Swift.print("Minimum consecutive missions: \(minConsecMissions)\n")
            
            if cyclesLeft > 0 {
                
                // Successful cycle but not done cycling
                Swift.print("End of cycle. Current tank configuration:")
                self.print()
                Swift.print("\n-- Starting new cycle --\n")
                return(self.cycleWithConsoleUpdates(cyclesLeft: cyclesLeft - 1))
                
            } else {
                
                // Successful configuration
                Swift.print("Final tank configuration:")
                self.print()
                Swift.print("\nSuccessful configuration!\n")
                Swift.print("=========================\n")
                
                return getFullCycleData(successful: true)
            }
            
        } else {
            
            // Unsuccessful configuration
            
            Swift.print("\nMissions fueled this cycle: \(missionsFueled)\n")
            Swift.print("-- Done running missions -- \n")
            Swift.print("Minimum consecutive missions: \(minConsecMissions)\n")
        
            Swift.print("Final tank configuration:")
            self.print()
            Swift.print("\nUnsuccessful configuration\n")
            Swift.print("-------------------------\n")
            
            addIndividualCycleData(successful: false)
            return getFullCycleData(successful: false)
        }
    }
    
    /**
     Performs a cycle similarly to cycle() but updates the UI every time a mission is called and does not switch active tank until the user clicks a button. See cycle() for more extensive documentation. Function is identical except for UI updates and timer-oriented structure.
     */
    func cycleWithUIUpdates(allAtOnce: Bool = false) {
        
        // Update the delegate StorageTankBrain (which updates the UI) with the initial tank state
        self.updateUI()
        
        missionsFueled = 0
        
        if ranOnEmpty {
            missionsFueled += 1
            totalMissionsFueled += 1
            ranOnEmpty = false
        }
        
        if allAtOnce {
            // Fuels one mission per timer tick
            UICycleTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) {timer in
                
                if self.canFill() {
                    
                    self.runMission(cyclingWithUIUpdates: true)
                    self.missionsFueled += 1
                    self.totalMissionsFueled += 1
                    
                    self.updateUI()
                    
                } else {
                    // Cycle ending. Stop timer
                    timer.invalidate()
                    
                    if self.missionsFueled < self.minConsecMissions {
                        self.minConsecMissions = self.missionsFueled
                    }
                    
                    self.totalCyclesCompleted += 1
                    
                    if let id = self.runOnEmpty(cyclingWithUIUpdates: true) {
                        
                        self.ranOnEmpty = true
                        
                        // Add the data for this cycle
                        self.addIndividualCycleData(successful: true)
                        
                        // Update the UI
                        self.updateUI()
                        
                        // Change the active fuel to the empty tank found by runOnEmpty()
                        self.setActiveFuel(tankID: id)
                        
                        self.delegate?.handleEndOfCycle(tank: self, info: self.getFullCycleData(successful: true))
                        
                    } else {
                        self.updateUI()
                        
                        self.addIndividualCycleData(successful: false)
                        self.delegate?.handleEndOfCycle(tank: self, info: self.getFullCycleData(successful: false))
                    }
                }
            }
        } else {
            UICycleTimer = Timer.init(timeInterval: 0.7, repeats: true) {timer in
                
                if self.canFill() {
                    
                    self.runMission(cyclingWithUIUpdates: true)
                    self.missionsFueled += 1
                    self.totalMissionsFueled += 1
                    
                    self.updateUI()
                    
                } else {
                    // Cycle ending. Stop timer
                    timer.invalidate()
                    
                    if self.missionsFueled < self.minConsecMissions {
                        self.minConsecMissions = self.missionsFueled
                    }
                    
                    self.totalCyclesCompleted += 1
                    
                    if let id = self.runOnEmpty(cyclingWithUIUpdates: true) {
                        
                        self.ranOnEmpty = true
                        
                        // Add the data for this cycle
                        self.addIndividualCycleData(successful: true)
                        
                        // Update the UI
                        self.updateUI()
                        
                        // Change the active fuel to the empty tank found by runOnEmpty()
                        self.setActiveFuel(tankID: id)
                        
                        self.delegate?.handleEndOfCycle(tank: self, info: self.getFullCycleData(successful: true))
                        
                    } else {
                        self.updateUI()
                        
                        self.addIndividualCycleData(successful: false)
                        self.delegate?.handleEndOfCycle(tank: self, info: self.getFullCycleData(successful: false))
                    }
                }
            }
        }
    }


    /**
     Called if user decides to cut a cycle short manually during a UI cycle.
     */
    func stopUICycle() {
        UICycleTimer?.invalidate()
        self.totalCyclesCompleted += 1
        self.addIndividualCycleData(successful: true)
        
        self.setActiveFuel(tankID: findMinMissionsLeft())
        
        self.delegate?.handleEndOfCycle(tank: self, info: self.getFullCycleData(successful: true))
    }
}


