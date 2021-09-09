import Foundation

extension String {

    /// Returns the matches of a NSRegularExpression on a string
    /// - Parameter regex: NSRegularExpression to match
    /// - Returns: [[String]], the outer array contains an entry for each match and the inner arrays contain an entry for each capturing group
    public func matchingStrings(regex: NSRegularExpression) -> [[String]] {
        // https://stackoverflow.com/q/27880650/3386893
        regex.matches(in: self, options: [], range: NSRange(self.startIndex..., in: self)).map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound ? String(self[Range(result.range(at: $0), in: self)!]) : ""
            }
        }
    }

    /// Returns the matches and ranges of the matches of a NSRegularExpression on a string
    /// - Parameter regex: NSRegularExpression to match
    /// - Returns: [[(String, Range<String.Index>]], the outer array contains an entry for each match of the regex in the
    ///              string, and the inner arrays contain an entry with the matched text and the range for each capturing group
    func matchingStringsWithRange(regex: NSRegularExpression) -> [[(string: String, range: Range<String.Index>)?]] {
        regex.matches(in: self, options: [], range: NSRange(self.startIndex..., in: self)).map { result in
            (0..<result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                ? (string: String(self[Range(result.range(at: $0), in: self)!]), range: Range(result.range(at: $0), in: self)!)
                : nil
            }
        }
    }

}
