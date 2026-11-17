import AppKit

/// Menu bar icon: a raised index finger (SF Symbol `hand.point.up.fill`).
/// While blocking is on it flicks left and right now and then, the
/// "no, no" gesture. A blocked tab gets a bigger, faster wag.
/// Template images, so the menu bar tints them.
@MainActor
enum HandIcon {
    struct Frame {
        let image: NSImage
        let duration: TimeInterval
    }

    private static let canvas = NSSize(width: 22, height: 18)
    private static let wristY: CGFloat = 1

    /// Shown while blocking is on.
    static let on = frame("hand.point.up.fill", angle: 0)
    /// Shown while blocking is off (drawn dimmed by the status button).
    static let off = frame("hand.point.up", angle: 0)

    /// Two quick flicks, then about two seconds upright. Loops while on.
    static let idle = flicks(to: [-14, 14, -14, 14, 0], step: 0.03, hold: 0.1, rest: 2.2)

    /// After a block: three wide, fast wags, then back to idle.
    static let block = flicks(to: [-24, 24, -24, 24, -24, 24, 0], step: 0.025, hold: 0.04, rest: 0.3)

    /// Snaps to each angle in three eased steps and holds there briefly.
    private static func flicks(to angles: [Double], step: TimeInterval,
                               hold: TimeInterval, rest: TimeInterval) -> [Frame] {
        var frames: [Frame] = []
        var current = 0.0
        for target in angles {
            for i in 1...3 {
                let p = Double(i) / 3
                let eased = 1 - (1 - p) * (1 - p)
                let angle = current + (target - current) * eased
                frames.append(Frame(image: frame("hand.point.up.fill", angle: angle),
                                    duration: i == 3 ? hold : step))
            }
            current = target
        }
        frames[frames.count - 1] = Frame(image: on, duration: rest)
        return frames
    }

    private static func frame(_ symbolName: String, angle: Double) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)

        let image = NSImage(size: canvas, flipped: false) { rect in
            guard let symbol, let context = NSGraphicsContext.current?.cgContext else { return false }
            let size = symbol.size
            let pivot = CGPoint(x: rect.midX, y: wristY)
            context.translateBy(x: pivot.x, y: pivot.y)
            context.rotate(by: CGFloat(angle) * .pi / 180)
            context.translateBy(x: -pivot.x, y: -pivot.y)
            symbol.draw(in: NSRect(x: rect.midX - size.width / 2, y: wristY,
                                   width: size.width, height: size.height))
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "FxxkScroll"
        return image
    }
}
