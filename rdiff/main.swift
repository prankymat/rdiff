//
//  main.swift
//  rdiff
//
//  Created by Matthew Wo on 8/24/16.
//  Copyright © 2016 rrdev. All rights reserved.
//

import Foundation

var args = CommandLine.arguments
args.removeFirst()

if args.count > 0 && args[0] == "-v" {
    // Print version then exit
    print("rdiff - Raccoon Diff (v. 0.2)\nAuthor: Matthew Wo (9029537@gmail.com) © 2016")
    exit(EXIT_SUCCESS)
}

let folders = args.filter { URL(string: $0) != nil }

guard folders.count == 2 else {
    print("Please provide exactly 2 folders to rdiff.\nExample: rdiff ./src ./dst")
    exit(EXIT_FAILURE)
}

let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)

let src = URL(fileURLWithPath: folders[0], relativeTo: currentDir)
let dst = URL(fileURLWithPath: folders[1], relativeTo: currentDir)

print("Crawling folders...")

guard let srcFolder = try? FolderCrawler.crawl(folder: src),
      let dstFolder = try? FolderCrawler.crawl(folder: dst) else {
    print("Failed to locate folders!")
    exit(EXIT_FAILURE)
}

let difference = Set(srcFolder).subtracting(dstFolder)

if difference.count > 0 {
    let sortedDifference = difference.sorted(by: { (a, b) -> Bool in
        a.uri.deletingLastPathComponent().absoluteString < b.uri.deletingLastPathComponent().absoluteString
    })

    let result = sortedDifference.flatMap { $0.uri.deletingBase(path: "\(src.path)/")?.absoluteString }
                                 .flatMap { $0.removingPercentEncoding }

    print("Please copy these files from \(src.path) to \(dst.path):")
    for path in result {
        print(path)
    }
} else {
    print("Folder contents are synced!")
}
