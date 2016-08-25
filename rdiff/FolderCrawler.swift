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

            guard let uri = URL(string: uriStr.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!) else {
                fatalError()
            }

            parsed[uri] = md5
        }
        return parsed
    }

    private static func loadCache(at folder: URL) -> String? {
        let cachePath = folder.appendingPathComponent(".md5.cache")

        guard let folderMod = FileManager.default.modificationDateForFileAtPath(path: folder.absoluteString),
            let cacheMod = FileManager.default.modificationDateForFileAtPath(path: cachePath.path) else {
                return nil
        }
        
        if case .orderedDescending = cacheMod.addingTimeInterval(TimeInterval(10)).compare(folderMod) {
            return FileManager.default.contents(atPath: cachePath.path).flatMap { String(data: $0, encoding: .utf8) }
        }

        return nil
    }

    private static func saveCache(for files: [File]) throws {
        var buffer = [URL : [String]]()

        for file in files {
            let folder = file.uri.deletingLastPathComponent()

            if buffer[folder] == nil {
                buffer[folder] = [String]()
            }

            buffer[folder]!.append("\(file.md5) \(file.uri.path)")
        }

        for (folder, strBuf) in buffer {
            let joined = strBuf.joined(separator: "\n")
            let cacheFile = folder.appendingPathComponent(".md5.cache")
            try joined.write(toFile: cacheFile.path, atomically: true, encoding: .utf8)
        }
    }

    static func crawl(folder: URL) throws -> [File] {
        guard let folderList = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles), folderList.count > 0 else {
            return []
        }

        var fileList = [File]()

        var regularFiles = [URL]()

        for file in folderList {
            let fileType = try! file.resourceValues(forKeys: [.isDirectoryKey])
            if let _ = fileType.isDirectory {
                let filesInSubDir = try crawl(folder: file)
                fileList.append(contentsOf: filesInSubDir)
            }
            regularFiles.append(file)
        }

        let result: String

        if let cache = loadCache(at: folder) {
            result = cache
        } else {
            result = shell(launchPath: "/sbin/md5", arguments: ["-r"] + regularFiles.map { $0.path })
        }

        let parsed = parseMD5s(output: result)

        for (uri, md5) in parsed {
            fileList.append(File(uri: uri, md5: md5))
        }

        do {
            try saveCache(for: fileList)
        } catch {
            print("ERROR: Failed to save cache!")
        }

        return fileList
    }
}
