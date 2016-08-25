//
//  File.swift
//  rdiff
//
//  Created by Matthew Wo on 8/24/16.
//  Copyright © 2016 rrdev. All rights reserved.
//

import Foundation

typealias MD5 = String

struct File: Hashable {
    let uri: URL
    let md5: MD5

    var hashValue: Int {
        get {
            return md5.hashValue
        }
    }
}

func ==(lhs: File, rhs: File) -> Bool {
    return lhs.md5 == rhs.md5
}
