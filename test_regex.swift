import Foundation

let folderName = "Test - 002220AA-1234-5678-9ABC-DEF012345678"
let uuidPattern = " - [0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}"

do {
    let regex = try NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive)
    let range = NSRange(location: 0, length: folderName.utf16.count)
    
    if let match = regex.firstMatch(in: folderName, options: [], range: range) {
        let projectPart = String(folderName.prefix(match.range.location))
        print("✅ Extracted project name: \"\(projectPart)\"")
    } else {
        print("❌ No match found")
    }
} catch {
    print("❌ Regex error: \(error)")
}
