//
//  LeafTags.swift
//  
//
//  Created by Cassini17 on 29.05.2023.
//

import Foundation
import Leaf

struct IndexTag: LeafTag {
    
    // This is a ridiculous workaround to index into array that holds an object and get a value of one of its fields using a field name
    func render(_ ctx: LeafContext) throws -> LeafData {
        let placeholder = LeafData(nil)
        if let array = ctx.parameters[0].array, // array
           let index = ctx.parameters[1].int, // index of an object in the array
           let key = ctx.parameters[2].string { // name of the field in the object
            guard array.count > index else { return placeholder }
            
            if let dict = array[index].dictionary, let element = dict[key]?.string {
                return LeafData("\(element)")
            }
        }
        return placeholder
    }
}

