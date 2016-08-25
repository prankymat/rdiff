//
//  FolderCrawler.swift
//  rdiff
//
//  Created by Matthew Wo on 8/24/16.
//  Copyright © 2016 rrdev. All rights reserved.
//

import Foundation

extension FileManager {

    func modificationDateForFileAtPath(path:String) -> Date? {
        guard let attributes = try? self.attributesOfItem(atPath: path) else { return nil }
        return attributes[FileAttributeKey.modificationDate] as? Date
    }

    func creationDateForFileAtPath(path:String) -> Date? {
        guard let attributes = try? self.attributesOfItem(atPath: path) else { return nil }
        return attributes[FileAttributeKey.creationDate] as? Date
    }
    

}

struct FolderCrawler {
    private static func shell(launchPath: String, arguments: [String]) -> String {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        return output
    }

    private static func parseMD5s(output: String) -> [URL: MD5] {
        let lines = output.components(separatedBy: NSCharacterSet.newlines).filter{!$0.isEmpty}

        var parsed = [URL: MD5]()
        for line in lines {
            let md5 = line.substring(to: line.index(line.startIndex, offsetBy: 32))
            let uriStr = line.substring(from: line.index(line.startIndex, offsetBy: 33))

            guard let uri = URL(string: uriStr.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) else {
                fatalError()
            }

            parsed[uri] = md5
        }
        return parsed
    }

    private static func loadCache(at folder: URL) -> String? {
        let cachePath = "\(folder)/.md5.cache"

        guard let folderMod = FileManager.default.modificationDateForFileAtPath(path: folder.absoluteString),
            let cacheMod = FileManager.default.modificationDateForFileAtPath(path: cachePath) else {
                return nil
        }
        
        if case .orderedDescending = cacheMod.addingTimeInterval(TimeInterval(10)).compare(folderMod) {
            return FileManager.default.contents(atPath: cachePath).flatMap { String(data: $0, encoding: .utf8) }
        }

        return nil
    }

    static func crawl(folder: URL) throws -> [File] {
        let fileList = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).map { $0.path }

        guard fileList.count > 0 else {
            return []
        }

        let result: String
        if let cache = loadCache(at: folder) {
            result = cache
        } else {
            result = shell(launchPath: "/sbin/md5", arguments: ["-r"] + fileList)
            try? result.write(toFile: "\(folder)/.md5.cache", atomically: true, encoding: .utf8)
        }

        let parsed = parseMD5s(output: result)

        var files = [File]()

        for (uri, md5) in parsed {
            files.append(File(uri: uri, md5: md5))
        }

        return files.filter { $0.uri.lastPathComponent != ".md5.cache" }
    }
}
