//
//  Helper.swift
//  rdiff
//
//  Created by Matthew Wo on 8/25/16.
//  Copyright © 2016 rrdev. All rights reserved.
//

import Foundation

extension URL {
    func deletingBase(path base: String) -> URL? {
        guard let deleteRange = self.absoluteString.range(of: base) else {
            return nil
        }

        var selfStr = self.absoluteString
        selfStr.removeSubrange(deleteRange)

        return URL(string: selfStr)
    }
}
