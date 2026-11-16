import Foundation

enum TextExporter {
    static func text(for entry: Entry, categoryName: String) -> String {
        var lines: [String] = [entry.title]
        if let subtitle = entry.subtitle.nonEmpty {
            lines.append(subtitle)
        }
        lines.append(categoryName)
        lines.append("")
        for section in entry.sections {
            lines.append(section.title.uppercased())
            for block in section.blocks {
                switch block.kind {
                case "bullet":
                    lines.append("- \(block.text)")
                case "step", "numbered":
                    let number = block.number ?? 0
                    lines.append("\(number). \(block.text)")
                default:
                    lines.append(block.text)
                }
                lines.append("")
            }
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    /// Replaces characters that are unsafe in a file name. "A/B: C?" becomes "A-B- C.txt".
    static func fileName(_ title: String) -> String {
        let forbidden = Set("/:\\?%*|\"<>")
        var cleaned = ""
        for character in title {
            if forbidden.contains(character) {
                if let last = cleaned.last, last != "-", last != " " {
                    cleaned.append("-")
                } else if cleaned.isEmpty {
                    cleaned.append("-")
                }
            } else {
                cleaned.append(character)
            }
        }
        let trimmed = cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-.")))
        let base = trimmed.isEmpty ? "Recipe" : trimmed
        return base + ".txt"
    }
}
