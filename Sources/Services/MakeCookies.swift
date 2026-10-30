// Make arguments for cookies

import Foundation

func makeCookieArguments(source: String, path: String) -> [String] {
    switch source {
    case "none": return []
    case "file": return path.isEmpty ? [] : ["--cookies", path]
    case "zen":  return path.isEmpty ? [] : ["--cookies-from-browser", "firefox:\(path)"]
    default:     return ["--cookies-from-browser", source]
    }
}