# egg-inc-rocket-cycle
Over COVID-19, I joined the cult-like following of the idle game Egg, Inc. on Discord. It turns out that there is a market for complicated and unnecessary applications that help you put *less* effort into the game. Of course, creating and maintaining them takes far more time than it saves, but that's besides the point.

## Overview of Egg, Inc. (and the point of all this)
Egg is a traditional incremental idle game. You start out producing normal, cheap eggs, unlocking egg-related research until you can purchase a higher-level egg farm. Eventually, your progress stagnates and you must prestige to get soul eggs, which offer permanent boosts. 

Once you unlock the rocket fuel egg, you can *launch rockets to collect artifacts from space*, each of which gives you a unique permanent boost. The higher level your farm, the higher level rockets you have access to, the highest of which is the long Henerprise mission. It takes 1 trillion tachyon eggs and 3 trillion dilithium, antimatter, and dark matter eggs to fuel, which is 10 trillion total. Each of these missions takes 3 days and you can only run 3 missions at a time.

Here's where this application comes in.

**The "problem":** You can only produce one type of egg at a time, so fueling a rocket is cumbersome. Every time you switch farms, it takes 10-15 minutes (for the highest level players) to get production speed high enough for a mission. To ease the pain of this process, the developers added a fuel tank which can hold up to 100 trillion eggs of any type. But what's the best way to fill it?

**The "solution:** You could just fill it up with 10x the amount of each fuel needed to launch, but that runs out after 10 launches, which isn't many. I wondered if there was a way to fill up the tank just right so that you only had to switch egg farms once on each weekend. That turns over an hour mid-week of filling your fuel tank from scratch into only 10-15 minutes a week on the weekends. 

Turns out, there is! Plenty of ways actually. I used an algorithm I developed specifically for this project to calculate every possible unique fuel tank setup (only considering increments of 1 trillion) and did the math to see how each setup would perform based on a number of metrics. I did this in Swift so that later I could implement a UI to test out the best setups and "practice" using them in the game. 

Link to Discord post I made that demonstrates the best setup (with simple graphics to explain): https://discord.com/channels/455380663013736479/455385659079917569/872239259954839594 

## The Code
I implemented all of this in Swift using the UIKit framework, combining Swift's intuitive protocol-delegate design pattern (similar to abstract classes in Java) as well as the popular model-view-controller design pattern. 

*Note:* I owe all of my Swift knowledge to a phenomenal Udemy course by Angela Yu. I don't think it gets better than that if you want to learn Swift -- I highly recommend it! It also has a modernized SwiftUI module that I'm planning to check out at some point. Link here: https://www.udemy.com/course/ios-13-app-development-bootcamp/ 

### Models

**Enumerations.swift:** This contains my most crucial anti-typo defense system, the EggCode enumeration. Whenever I refer to an egg type, I use this enumeration. CycleState and MissionState are used in the app interface.

**StorageTank.swift:** This stores all of the information for the big 100 trillion capacity fuel tank. It interfaces with the TankBrain, which implements the StorageTankDelegate protocol, to share this information with the user. 

Its main functionality is the recursive cycle() method. The StorageTank "cycles" by running missions until it's out of fuel in one of the tanks, switching farms to the empty tank, and cycling again. It stops when two or more tanks are empty (because that requires switching farms twice in a row, which is cumbersome). Most of the other methods are accessory methods or used within the cycle() method. 

For the most part, everything in it has a withUIUpdates counterpart. This performs cycles in a similar way but uses the protocol-delegate pattern to update the user interface. The updateUI() method is most often used function to update the user interface. It works by passing itself to updateStorageTankUI() of its parent TankBrain object, which then passes the tank up to its parent ViewController through a different updateStorageTankUI(), which then updates all the UI elements with the tank's information. 

It also has a few structs, like FullCycleData, that are used to store information about how a certain tank setup performed. These objects are used later by the TankBrain to sift through all of the different tank setups. 

**RocketTank.swift:** This stores the data about the fuel tank of the rocket currently being launched. It also interfaces with the TankBrain through the RocketTankDelegate protocol. There's not a whole lot to it, but it's especially important for the user interface. Situations often arise when it makes sense to fill the tank partially, switch farms, and then fill it all the way, and this object is necessary to keep track of that. 

**TankBrain.swift:** The TankBrain oversees all the operations of the StorageTank and the RocketTank. It creates all the unique StorageTank configurations at the start of the program based on a few parameters, cycles through all of them, and picks the best ones. The parameters for each of those steps are fairly self-explanatory based on the variable names. It also interfaces with the UI through the TankViewController protocol. 

**MathBrain.swift** This is a helpful collection of all the strictly mathematical/algorithmic functionality used when generating all unique StorageTank configurations. It implements simple getPermutations(), getCombinations(), and getGCD() functions which behave as expected. **This is one of the coolest parts of the program! Check this out if you're interested in algorithms.** The part to look at here is the getPermutations() method that takes a filter as imput--there is very extensive documentation within the file on that function. 

### Views

Main - the main view. Not much to it.

TankView - the custom view I created to represent the tank. Each TankView shows the amount of one type of fuel and can be linked to a StorageTank.

### Controllers

ViewController - the main view controller. Does all the user interface stuff. This section definitely needs the most work out of any section. I might re-do the entire thing in SwiftUI one day if I decide to learn it. It's pretty all over the place, but it does its job. 

## UI usage details (strategy)
You can use the buttons on the screen to practice using the bets StorageTank setup I found. "Start Cycle" starts one run of the cycle() function and goes either until you are out of fuel or stop the cycle yourself. It changes to "Stop Cycle" during the cycle and "Switch Farms" once you run out of fuel. "Fill Rocket" allows you to fill up the current rocket with as much fuel as possible and changes to "Launch Rocket" when the rocket fills up. 

"Abandon Short Voyegger" decreases the dilithium and antimatter amounts in storage by 1 trillioneach (not going below 0) and fills up the tank with fuel from the current farm. The Voyegger is the second to last mission in the game. "Abandon Exhen" does the same thing but decreases tachyon by 1 trillion and dilithium/antimatter/dark matter by 3 trillion. Exhen = extended Henerprise. These techniques are necessary to get maximum value.

By trying different combinations, the most weeks in a row I got with only switching farms every 6 missions (once per weekend) is around 20. I forget the exact number. Either way, the UI is a great way to take good combinations found by brute-force and tweak them to last even longer. 



If you are interested in this project or know Swift and would like to contribute, reach out to me! I would love to see this polished and posted to the App Store at some point.
