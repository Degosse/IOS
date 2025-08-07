import Foundation

// Test the new parsing logic
let sampleHTML = """
| ma 7 | 00:25 ▲ 3.75 m | 05:31 ▼ 1.27 m | 13:00 ▲ 3.83 m | 17:59 ▼ 1.32 m | ▲ 05:40 | ▼ 22:04 |
| di 8 | 01:17 ▲ 3.87 m | 06:30 ▼ 1.33 m | 13:39 ▲ 3.9 m | 18:57 ▼ 1.28 m | ▲ 05:41 | ▼ 22:04 |
"""

let calendar = Calendar.current
let today = calendar.startOfDay(for: Date())
let todayDay = calendar.component(.day, from: today)
let tomorrowDay = calendar.component(.day, from: calendar.date(byAdding: .day, value: 1, to: today)!)

print("Looking for day \(todayDay) (today) and day \(tomorrowDay) (tomorrow)")

let lines = sampleHTML.components(separatedBy: .newlines)

for line in lines {
    if line.contains("|") && line.contains("▲") && line.contains("▼") {
        // Extract the day number from patterns like "| ma 7 |" or "| di 8 |"
        let dayPattern = #"\|\s*\w+\s+(\d+)\s*\|"#
        if let dayRegex = try? NSRegularExpression(pattern: dayPattern),
           let dayMatch = dayRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)),
           let dayRange = Range(dayMatch.range(at: 1), in: line) {
            
            let dayStr = String(line[dayRange])
            guard let day = Int(dayStr) else { continue }
            
            print("Found day: \(day) in line: \(line)")
            
            // Extract all tides from this line
            let tidePattern = #"(\d{2}:\d{2})\s*([▲▼])\s*([\d,\.]+)\s*m"#
            if let tideRegex = try? NSRegularExpression(pattern: tidePattern) {
                let tideMatches = tideRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
                
                print("  Found \(tideMatches.count) tide matches")
                
                for (index, tideMatch) in tideMatches.enumerated() {
                    guard let timeRange = Range(tideMatch.range(at: 1), in: line),
                          let arrowRange = Range(tideMatch.range(at: 2), in: line),
                          let heightRange = Range(tideMatch.range(at: 3), in: line) else { continue }
                    
                    let timeStr = String(line[timeRange])
                    let arrowStr = String(line[arrowRange])
                    let heightStr = String(line[heightRange]).replacingOccurrences(of: ",", with: ".")
                    
                    print("    Tide \(index + 1): \(timeStr) \(arrowStr) \(heightStr)m")
                }
            }
        }
    }
}
