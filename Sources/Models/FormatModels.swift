// Models for the Output Format selector "Picker"

enum VideoOutputFormat: String, CaseIterable, Identifiable {
    case mp4 = "mp4"
    case mkv = "mkv"
    case webm = "webm"
    case mov = "mov"
    case avi = "avi"
    case flv = "flv"

    var id: String { rawValue }

    var videoFormatSelector: String {
        switch self {
            case .mp4: return "mp4"
            case .mkv: return "mkv"
            case .webm: return "webm"
            case .mov: return "mov"
            case .avi: return "avi"
            case .flv: return "flv"
        }
    }
}