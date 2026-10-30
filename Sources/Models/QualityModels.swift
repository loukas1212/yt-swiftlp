// Models for the quality selector "Picker"

enum VideoQuality: String, CaseIterable, Identifiable {
    case best = "Best quality available"
    case p2160 = "2160p (4k)"
    case p1440 = "1440p (2k)"
    case p1080 = "1080p"
    case p720 = "720p"
    case p480 = "480p"
    case p360 = "360p"

    var id: String { rawValue }

    var qualitySelector: String {
        switch self {
            case .best:
                return "bv*+ba/b"
            case .p2160:
                return "bv*[height<=2160]+ba/b[height<=2160]"
            case .p1440:
                return "bv*[height<=1440]+ba/b[height<=1440]"
            case .p1080:
                return "bv*[height<=1080]+ba/b[height<=1080]"
            case .p720:
                return "bv*[height<=720]+ba/b[height<=720]"
            case .p480:
                return "bv*[height<=480]+ba/b[height<=480]"
            case .p360:
                return "bv*[height<=360]+ba/b[height<=360]"
        }
    }
}