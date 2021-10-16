//
//  MathBrain.swift
//  Egg Fueling App
//
//  Created by Nathan Chasse on 7/29/21.
//

import Foundation

/*
 Returns a list of all the unique unordered combinations of integers selected from within the given range of the given size. If not otherwise specified, the integers will be selected with replacement.
 */
func getCombinations(in range: Range<Int>, ofSize size: Int, withReplacement replace: Bool = true) -> [[Int]] {
    // Base case 0: if for some reason the combination size is nonpositive, return an empty result
    if size <= 0 {
        return [[]]
    }
    
    // Base case 1: if combination size is equal to 1, return all the numbers in the range as individual combinations
    // This base case is actually unnecessary with base case 0 but it reduces the size of the call stack significantly
    if size == 1 {
        var combinations: [[Int]] = []
        for i in range {
            combinations.append([i])
        }
        return combinations
    }
    
    // Base case 2: if range size is equal to the combination size, the numbers in the range consecutively form the only combination
    if range.count == size {
        return([range.map { $0 }])
    }
    
    // Initalize combinations array
    var combinations: [[Int]] = []
    
    /*
     Example of what is happening here for the range (2..<7) and size 3:
     
     i = 2 -> get combinations of size 2 from range (3..<7) -> get combinations of size 1 from range (4..<7)
     
     ...
     
     i = 4 -> get combinations of size 2 from range (5..<7) (there is only one)
     
     Stop running here because any further would force an index out of range issue or something
     */
    
    // If the user wants combinations without replacement, the lower bound of the for loop has to be one greater which this corrects for
    var replaceInt: Int
    switch replace {
        case true: replaceInt = 0
        case false: replaceInt = 1
    }
    
    for i in (range.lowerBound..<range.upperBound) {
        for combination in getCombinations(in: (i+replaceInt..<range.upperBound), ofSize: size-1) {
            combinations.append([i] + combination)
        }
    }
    return combinations
}

/*
 Returns a list of all the unique combinations of nums numbers that add up to sum.
 */
func getSumCombinations(sum: Int, nums: Int, max: Int = -1) -> [[Int]] {
    // Base case
    if nums <= 1 {
        return [[sum]]
    }
    
    var returnList: [[Int]] = []
    if max == -1 {
        let minimum = Int(ceil(Float(sum)/Float(nums)))
        for i in (minimum...sum) {
            for combination in getSumCombinations(sum: sum - i, nums: nums - 1, max: i) {
                returnList.append([i] + combination)
            }
        }
    } else {
        let minimum = Int(ceil(Float(sum)/Float(nums)))
        for i in (minimum...min(max, sum)) {
            for combination in getSumCombinations(sum: sum - i, nums: nums - 1, max: i) {
                returnList.append([i] + combination)
            }
        }
    }
    return returnList
}

/*
 Returns all the unique permutations of the integers in startingList.
 
 FUNCTIONAL!
 */
func getPermutations(of ls: [Int]) -> [[Int]] {
    if ls.count <= 1 {
        return [ls]
    } else {
        var returnList: [[Int]] = []
        for i in (0..<ls.count) {
            let item: [Int] = [ls[i]] // Element of startingList at index i
            var shortLs = ls // startingList copy
            shortLs.remove(at: i) // remove item from copy
            
            // Add new permutations (recursive part)
            for permutation in getPermutations(of: shortLs) {
                let newElement = item + permutation
                
                // Don't add duplicate permutations
                if !returnList.contains(newElement) {
                    returnList.append(newElement)
                }
            }
        }
                
        return returnList
    }
}

/*
 Returns a list of all unique permutations of ls not "comparable" relative to the filter. I define "comparable" below.
 
 First, call L1 and L2 the lists to be compared and assume that L1 and L2 have the same length denoted len.
 
 Consider filter F == [k_0, k_1, ... , k_(n-1), k_n] where n = len - 1. For some n_i with 0 <= i <= n, define the "instance list" I of n_i to be the list of indices for which F[index] == n_i. For example, for filter [0, 1, 1, 2, 1], the instance list of n_1 = 1 is [1, 2, 4].
 
 For each instance list I, create two new "correspondence sets" consisting of the values in L1 and L2 respectively at each index in I. For example, with L1 = [0, 4, 3, 6, 7] L2 = [3, 6, 2, 7, 4], and I = [0, 3, 4], the correspondence sets would be {0, 6, 7} and {3, 7, 4} respectively.
 
 DEFINITION: If, for every instance list of a value within S, these correspondence sets are equivalent, L1 and L2 are comparable.
 
 Here are a few demonstrations of this algorithm in action:
 
 L1: [0, 1, 4, 2, 3, 5]
 L2: [3, 4, 1, 5, 0, 2]
 Filter: [0, 2, 2, 1, 0, 1]
 
 Unique values within filter to check instance lists for: [0, 1, 2]
 
 Instance list for 0: [0, 4]
 L1 correspondence: {0, 3}
 L2 correspondence: {3, 0}
 These are equal, continue
 
 Instance list for 1: [3, 5]
 L1 correspondence: {2, 5}
 L2 correspondence: {5, 2}
 These are equal, continue
 
 Instance list for 2: [1, 2]
 L1 correspondence: {1, 4}
 L2 correspondence: {4, 1}
 These are equal, finished! Lists are comparable
 
 
 
 L1: [3, 4, 2, 1]
 L2: [1, 2, 3, 4]
 Filter: [0, 1, 0, 2]
 
 Unique values within filter: [0, 1, 2]
 
 Instance list for 0: [0, 2]
 L1 correspondence: {3, 2}
 L2 correspondence: {1, 3}
 These are not equal, stop. Lists are not comparable
 
 
 L1: [1, 234, 10823]
 L2: [pi, 33333, e]
 Filter: [0, 0, 0]
 
 Unique values within filter: [0]
 
 Instance list for 0: [0, 1, 2]
 L1 correspondence: {1, 234, 10823}
 L2 correspondence: {0, 0, 0}
 These are equal, finished! Lists are comparable (trivial case)
*/
func isComparable(l1: [Int], l2: [Int], filter inputFilter: [Int]) -> Bool {
    var uniqueValues: [Int] = []
    for num in inputFilter {
        if !uniqueValues.contains(num) {
            uniqueValues.append(num)
        }
    }
    
    for value in uniqueValues {
        // Get instance list
        var instanceList: [Int] = []
        for i in (0..<l1.count) {
            if inputFilter[i] == value {
                instanceList.append(i)
            }
        }
        
        // Get correspondence sets
        let corr1 = Set(instanceList.map({ l1[$0] }))
        let corr2 = Set(instanceList.map({ l2[$0] }))
        
        // If unequal, sets aren't comparable; return false
        if corr1 != corr2 {
            return false
        }
    }
    
    // If hasn't returned yet, all correspondence sets were equal so sets are comparable; return true
    return true
}

/*
 This function gets all the non-comparable permutations of ls based on inputFilter.
 
 Importantly, it does NOT work by getting the unique permutations of ls and then calling isComparable() on each iteratively to remove comparable duplicates; that would take ages. Something like O(n^2 * n!)?
 
 Instead, this function works by slightly re-modeling the getPermutations() function with no filter parameter in its signature. Look at the recursive step of that function and specifically the part where it removes values from the list, one at a time, to recursively generate new permutations with the remaining values. The re-model is here. Rather than removing one value at a time, this function removes potentially multiple values based on the filter. This is explained later in section EXPLAINED LATER.
 
 To simplify the problem, the filter is sorted in increasing order at the start of the function, and the original indices of each filter item is stored. The permutations are then generated with this sorted filter and re-ordered based on the original indices at the end so that they "line up" properly.
 
 For example, the filter [2, 1, 2, 3, 3, 1, 3] would become [1, 1, 2, 2, 3, 3, 3], and the "original index list" (call it L) would be [1, 5, 0, 2, 3, 4, 6]. Let P be a permutation generated from the original list and *sorted* filter, and Pf be that permutation after reordering. The item Pf[i] is equivalent to P[L[i]]. For example, Pf[0] would be P[L[0]] = P[1]. If desired, this reordering step happens at the top of the call stack, which is the call in which the reorder parameter is equal to true. When the function calls itself, it sets reorder to false.
 
 EXPLAINED LATER: Instead of removing one element at a time and adding that to the permutations of the remaining elements, the function would remove n elements at a time where n is the number of the leftmost element in the filter. For example, in the first call of getUniquePermutations() on the list [1, 2, 3, 4, 5, 6, 7], the first elements removed would be
 
 [1, 2], [1, 3], [1, 4], ... [2, 3], [2, 4], ... [6, 7]
 
 rather than simply 1, 2, 3, 4, 5, 6, 7 as in the original getPermutations. Rather than storing a list of lists of the elements to be removed, the function stores a list of lists of the INDICES of the elements to removed. In the previous case, this would look something like
 
 [0, 1], [0, 2], [0, 3], ... [4, 5], [4, 6], [5, 6].
 
 This list can be generated by calling getCombinations() where the input set is (0..<n) where n is the length of the entire list and the size of the combinations is defined by the amount of identical elements in the left side of the filter (as described earlier).
 
 The base case of the recursive step is when all the elements left in the filter are the same. In this case, the function simply returns the input list.
*/
func getPermutations(of ls: [Int], filter inputFilter: [Int], reorder: Bool = true) -> [[Int]] {
    // Get sorted filter
    var filter = inputFilter
    var filterMapping: [Int] = []
    if reorder {
        filter = filter.sorted(by: {
            let count1 = countInstances(ls: filter, item: $0)
            let count2 = countInstances(ls: filter, item: $1)
            if count1 == count2 {
                return ($0 < $1)
            } else {
                return (count1 < count2)
            }
        })
        
        // Store the mappings of the input filter to the sorted filter for re-sorting all the permutations at the end
        // For example: with filter [1, 1, 1, 3, 3] and sorted filter [3, 3, 1, 1, 1],
        // the mapping would be [3, 4, 0, 1, 2] (i.e. the item at index 3 in the permutations would be at index 0 if the filter wasn't sorted)
        var filterCopy = inputFilter
        for i in (0..<filter.count) {
            let index = filterCopy.firstIndex(of: filter[i])!
            filterCopy[index] = -1
            filterMapping.append(index)
        }
    }
    
    // Get the # of identical elements at the beginning of the filter
    let groupSize = countInstances(ls: filter, item: filter.first!)
    
    // Base case: when all elements of the filter are the same
    if groupSize == filter.count {
        return [ls]
    }
    
    var shortFilter = filter // Copy original filter
    shortFilter.removeFirst(groupSize) // Remove starting identical elements and store the remaining filter
    
    
    // Initalize list of permutations to return
    var returnList: [[Int]] = []
    
    // Get a list of index groupings to remove from the input list based on the filter group size (they are unordered, so combinations are used versus permutations)
    let combinations = getCombinations(in: (0..<ls.count), ofSize: groupSize, withReplacement: false)
    
    for combination in combinations {
        // Get a list of the items in the input list at the indices described by each combination
        let items: [Int] = combination.map { ls[$0] }
        
        // Copy input list and remove all the items at the described indices from it
        var shortLs = ls
        
        for i in (0..<combination.count) {
            shortLs.remove(at: combination[i] - i)
        }
        
        // Get all the permutations of the shortened list filtered by the shortened filter and generate permutations from the result
        for permutation in getPermutations(of: shortLs, filter: shortFilter, reorder: false) {
            let newElement = items + permutation
            
            // Don't add duplicate permutations
            // NOTE: THIS IS THE MOST INEFFICIENT PART OF THE PROGRAM! FIX THIS!
            if !returnList.contains(newElement) {
                returnList.append(newElement)
            }
        }
    }
    
    // Return list should only be mapped back to the original filter order at the very end (i.e. at the top of the call stack which is at the very first call of the function)
    if reorder {
        
        var sortedList: [[Int]] = []
        for list in returnList {
            var newElement: [Int] = list
            for i in (0..<list.count) {
                newElement[filterMapping[i]] = list[i]
            }
            sortedList.append(newElement)
        }
        return sortedList
        
    } else {
        return returnList
    }
}

/*
 Returns the number of times item appears in ls.
 */
func countInstances(ls: [Int], item: Int) -> Int {
    
    var count = 0
    for value in ls {
        if item == value {
            count += 1
        }
    }
    
    return count
    
}

/*
 Returns the GCD of the integers in ints. Uses Euclidean Algorithm.
 
 FUNCTIONAL!
 */
func getGCD(of nums: [Int]) -> Int {
    if nums.count == 1 {
        
        return nums[0]
        
    } else if nums.count == 2 {
        
        
        if nums[0] == nums[1] {
            return nums[0]
            
        } else {
            // Euclidean algorithm with 2 integers
            var m = nums.max()!
            let n = nums.min()!
            
            while m > n {
                m -= n
            }
            
            return getGCD(of: [m,n])
        }
        
    } else if nums.count > 2 {
        
        // Return GCD of the last element of nums and the GCD of the remaining elements
        return(getGCD(of: [nums.last!, getGCD(of: nums.dropLast())]))
        
    } else {
        // Just in case something goes wrong
        return -1
    }
}
