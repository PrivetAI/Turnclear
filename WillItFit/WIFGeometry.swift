import Foundation
import CoreGraphics

// MARK: - Results

enum WIFVerdict {
    /// Goes through the way the object normally stands.
    case clear
    /// Goes through, but only turned side-on or tilted.
    case rotated
    /// Does not go through at all.
    case blocked

    var title: String {
        switch self {
        case .clear: return "Passes"
        case .rotated: return "Passes turned"
        case .blocked: return "Does not pass"
        }
    }

    var shortTitle: String {
        switch self {
        case .clear: return "Pass"
        case .rotated: return "Turned"
        case .blocked: return "Blocked"
        }
    }

    var rank: Int {
        switch self {
        case .clear: return 0
        case .rotated: return 1
        case .blocked: return 2
        }
    }
}

/// Everything the plan-view turn drawing needs. Corridor A is the strip the object arrives
/// along, corridor B the one it leaves along; the inner corner sits at (B, A).
struct WIFTurnPlan {
    let corridorA: Double
    let corridorB: Double
    let length: Double
    let width: Double
    let angleDeg: Double
    let clearanceMM: Double
}

/// Everything the head-on opening drawing needs.
struct WIFOpeningPlan {
    let openWidth: Double
    let openHeight: Double
    let sideAcross: Double
    let sideUp: Double
    let angleDeg: Double
    let slackWidth: Double
    let slackHeight: Double
}

enum WIFStageDrawing {
    case turn(WIFTurnPlan)
    case opening(WIFOpeningPlan)
}

struct WIFStageOutcome: Identifiable {
    let id: UUID
    let name: String
    let kind: WIFObstacleKind
    let verdict: WIFVerdict
    /// Positive = spare room at the tightest point, negative = how far it overlaps.
    let marginMM: Double
    /// What runs out first, in plain words.
    let binding: String
    /// The angle the tightest moment happens at. Nil where the answer has no angle.
    let angleDeg: Double?
    let poseLabel: String
    let headline: String
    let notes: [String]
    let drawing: WIFStageDrawing?
}

struct WIFCheckResult {
    let stages: [WIFStageOutcome]
    let tightestStageID: UUID?
    let verdict: WIFVerdict
    let effectiveWidth: Double
    let effectiveHeight: Double
    let effectiveDepth: Double
    let effectiveWeight: Double
    let adjustmentNotes: [String]

    var tightestStage: WIFStageOutcome? {
        guard let id = tightestStageID else { return nil }
        return stages.first(where: { $0.id == id })
    }
}

// MARK: - Primitives

enum WIFGeom {
    /// 0.25 degree steps across a quarter turn — 361 samples including both ends.
    static let sweepSteps = 360
    static let sweepStepDeg = 0.25

    static func radians(_ degrees: Double) -> Double { degrees * .pi / 180.0 }

    /// How much spare room a `across` x `up` rectangle has inside an opening `width` x `height`.
    /// With `rotate` the rectangle is allowed to lean over inside the opening, which is what lets
    /// a panel taller than the door go through on the diagonal; the sweep therefore also covers
    /// the plain swapped orientation at 90 degrees.
    static func rectInRect(across: Double,
                           up: Double,
                           width: Double,
                           height: Double,
                           rotate: Bool) -> (angle: Double, slackWidth: Double, slackHeight: Double) {
        if !rotate {
            return (0, width - across, height - up)
        }
        var bestAngle = 0.0
        var bestSlack = -Double.greatestFiniteMagnitude
        var bestW = width - across
        var bestH = height - up

        func consider(_ deg: Double) {
            let t = radians(deg)
            let c = cos(t)
            let s = sin(t)
            let slackW = width - (across * c + up * s)
            let slackH = height - (across * s + up * c)
            let slack = min(slackW, slackH)
            if slack > bestSlack {
                bestSlack = slack
                bestAngle = deg
                bestW = slackW
                bestH = slackH
            }
        }

        var step = 0
        while step <= sweepSteps {
            consider(Double(step) * sweepStepDeg)
            step += 1
        }
        // The best angle sits on a kink, where a sampled sweep can only ever come close. The kink
        // is at a known angle, so it is evaluated exactly as well and the better of the two wins.
        for exact in crossingYaws(across: across, up: up, width: width, height: height) {
            consider(exact)
        }
        return (bestAngle, bestW, bestH)
    }

    /// Angles where the width constraint and the height constraint change places.
    ///
    /// The room left across the opening is `width - (across cos t + up sin t)`, which has a single
    /// interior minimum, and the room left up it behaves the same way. So on either side of the one
    /// angle where the two are equal, one of them is strictly falling — which means the best angle
    /// is always 0, 90, or that crossing. Solving `slackWidth = slackHeight` gives
    /// `cos t - sin t = (height - width) / (up - across)`, and `cos t - sin t = sqrt(2) cos(t + 45)`.
    static func crossingYaws(across: Double, up: Double, width: Double, height: Double) -> [Double] {
        let denominator = up - across
        guard abs(denominator) > 0.000001 else { return [] }
        let target = (height - width) / denominator
        let cosine = target / 2.0.squareRoot()
        guard cosine >= -1, cosine <= 1 else { return [] }
        let degrees = (acos(cosine) - .pi / 4) * 180 / .pi
        guard degrees > 0, degrees < 90 else { return [] }
        return [degrees]
    }

    /// Best yaw for a footprint standing on a cabin floor. Turning on the spot is always free, so
    /// this is the same problem as the opening — but it runs inside the tilt sweep, so it is
    /// evaluated only at the three angles that can possibly win rather than swept.
    static func floorSlack(footprint: Double,
                           wide: Double,
                           width: Double,
                           depth: Double) -> (angle: Double, slack: Double) {
        var bestAngle = 0.0
        var best = -Double.greatestFiniteMagnitude
        var angles: [Double] = [0, 90]
        angles.append(contentsOf: crossingYaws(across: footprint, up: wide, width: width, height: depth))
        for deg in angles {
            let t = radians(deg)
            let c = cos(t)
            let s = sin(t)
            let slack = min(width - (footprint * c + wide * s), depth - (footprint * s + wide * c))
            if slack > best {
                best = slack
                bestAngle = deg
            }
        }
        return (bestAngle, best)
    }

    /// The corridor-turn constraint.
    ///
    /// Corridor A is the strip `0 <= y <= a`, corridor B the strip `0 <= x <= b`, so the inner
    /// corner sits at `(b, a)` and the outer walls are the two axes. A rectangle of length `L`
    /// and width `W` turning the corner keeps both of its outer corners on the outer walls, which
    /// pins its outer edge to the segment from `(L cos t, 0)` to `(0, L sin t)`. The signed gap
    /// between its inner edge and the inner corner is then
    ///
    ///     d(t) = a cos t + b sin t - W - L sin t cos t
    ///
    /// Dividing by `sin t cos t` turns `d(t) >= 0` into the familiar
    /// `L <= a/sin t + b/cos t - W/(sin t cos t)`, so this really is the standard constraint —
    /// but as a distance in millimetres, which is what the user can act on. The whole turn is
    /// swept; the answer is the WORST angle, because that is the moment the carry actually jams.
    /// The ends of the sweep are the corridors themselves: `d(0) = a - W`, `d(90) = b - W`.
    static func turnClearance(length: Double,
                              width: Double,
                              corridorA: Double,
                              corridorB: Double) -> (angle: Double, clearance: Double) {
        var worstAngle = 0.0
        var worst = Double.greatestFiniteMagnitude
        var step = 0
        while step <= sweepSteps {
            let deg = Double(step) * sweepStepDeg
            let t = radians(deg)
            let c = cos(t)
            let s = sin(t)
            let gap = corridorA * c + corridorB * s - width - length * s * c
            if gap < worst {
                worst = gap
                worstAngle = deg
            }
            step += 1
        }
        return (worstAngle, worst)
    }

    /// The longest object of this width that can be taken round the corner at all, and the angle
    /// where that limit bites. Returns nil when the object is already too wide for one of the
    /// corridors, in which case length is not the problem.
    static func longestThroughTurn(width: Double,
                                   corridorA: Double,
                                   corridorB: Double) -> (angle: Double, length: Double)? {
        guard width < min(corridorA, corridorB) else { return nil }
        var bestAngle = 45.0
        var best = Double.greatestFiniteMagnitude
        var step = 1
        while step < sweepSteps {
            let deg = Double(step) * sweepStepDeg
            let t = radians(deg)
            let c = cos(t)
            let s = sin(t)
            let limit = corridorA / s + corridorB / c - width / (s * c)
            if limit < best {
                best = limit
                bestAngle = deg
            }
            step += 1
        }
        return (bestAngle, max(0, best))
    }

    /// Leaning a long object inside a closed box (a lift cabin). The long axis tilts away from
    /// vertical inside one vertical plane; at every tilt the resulting footprint is checked
    /// against the cabin floor with free yaw, because turning on the spot always costs nothing.
    /// A tilt of zero is the ordinary standing case, so this one sweep covers both.
    static func leanInside(long: Double,
                           thick: Double,
                           wide: Double,
                           cabinWidth: Double,
                           cabinDepth: Double,
                           cabinHeight: Double,
                           allowTilt: Bool) -> (angle: Double, slack: Double, binding: String) {
        var bestAngle = 0.0
        var bestSlack = -Double.greatestFiniteMagnitude
        var bestBinding = "cabin height"
        let lastStep = allowTilt ? sweepSteps : 0
        var step = 0
        while step <= lastStep {
            let deg = Double(step) * sweepStepDeg
            let t = radians(deg)
            let c = cos(t)
            let s = sin(t)
            let needHeight = long * c + thick * s
            let footprint = long * s + thick * c
            let heightSlack = cabinHeight - needHeight
            let floor = floorSlack(footprint: footprint,
                                   wide: wide,
                                   width: cabinWidth,
                                   depth: cabinDepth)
            let slack = min(heightSlack, floor.slack)
            if slack > bestSlack {
                bestSlack = slack
                bestAngle = deg
                bestBinding = heightSlack <= floor.slack ? "cabin height" : "cabin floor"
            }
            step += 1
        }
        return (bestAngle, bestSlack, bestBinding)
    }
}

// MARK: - Orientations

/// One way of presenting the object to a flat opening: what is across the opening, what is up
/// it, and what travels through. `tilted` marks the ways that need the object tipped off the
/// floor rather than merely turned on the spot.
struct WIFOpeningPose {
    let across: Double
    let up: Double
    let through: Double
    let tilted: Bool
    let label: String
}

/// One way of carrying the object round a turn: what is vertical, and the plan-view rectangle.
struct WIFCarryPose {
    let vertical: Double
    let length: Double
    let width: Double
    let tilted: Bool
    let label: String
}

enum WIFPoses {
    /// Upright, on its feet. Only the yaw changes.
    static func uprightOpening(w: Double, h: Double, d: Double) -> [WIFOpeningPose] {
        [
            WIFOpeningPose(across: w, up: h, through: d, tilted: false, label: "upright, front first"),
            WIFOpeningPose(across: d, up: h, through: w, tilted: false, label: "upright, side first")
        ]
    }

    static func allOpening(w: Double, h: Double, d: Double) -> [WIFOpeningPose] {
        uprightOpening(w: w, h: h, d: d) + [
            WIFOpeningPose(across: w, up: d, through: h, tilted: true, label: "tipped on its back, front first"),
            WIFOpeningPose(across: d, up: w, through: h, tilted: true, label: "tipped on its back, side first"),
            WIFOpeningPose(across: h, up: w, through: d, tilted: true, label: "on its side, front first"),
            WIFOpeningPose(across: h, up: d, through: w, tilted: true, label: "on its side, side first")
        ]
    }

    static func uprightCarry(w: Double, h: Double, d: Double) -> [WIFCarryPose] {
        [
            WIFCarryPose(vertical: h, length: w, width: d, tilted: false, label: "upright, carried lengthwise"),
            WIFCarryPose(vertical: h, length: d, width: w, tilted: false, label: "upright, carried side-on")
        ]
    }

    static func allCarry(w: Double, h: Double, d: Double) -> [WIFCarryPose] {
        uprightCarry(w: w, h: h, d: d) + [
            WIFCarryPose(vertical: w, length: h, width: d, tilted: true, label: "stood on one end, height leading"),
            WIFCarryPose(vertical: w, length: d, width: h, tilted: true, label: "stood on one end, depth leading"),
            WIFCarryPose(vertical: d, length: w, width: h, tilted: true, label: "laid on its back, width leading"),
            WIFCarryPose(vertical: d, length: h, width: w, tilted: true, label: "laid on its back, height leading")
        ]
    }
}

// MARK: - Engine

/// One evaluated way through a stage: how much room is left, where it runs out, and the pose
/// that achieved it.
private struct WIFAttempt {
    var slack: Double
    var angle: Double
    var binding: String
    var pose: String
    var drawing: WIFStageDrawing?
    var extra: [String] = []

    static let impossible = WIFAttempt(slack: -Double.greatestFiniteMagnitude,
                                       angle: 0,
                                       binding: "no orientation available",
                                       pose: "-",
                                       drawing: nil)
}

enum WIFEngine {

    // MARK: Effective object

    static func effectiveSize(_ item: WIFItem, _ adjust: WIFAdjustments) -> (w: Double, h: Double, d: Double) {
        var w = max(1, item.widthMM)
        var h = max(1, item.heightMM)
        var d = max(1, item.depthMM)
        if adjust.removePackaging {
            let p = max(0, item.packagingMM)
            w = max(10, w - p)
            h = max(10, h - p)
            d = max(10, d - p)
        }
        if adjust.removeLegs {
            h = max(10, h - max(0, item.legHeightMM))
        }
        return (w, h, d)
    }

    static func effectiveWeight(_ item: WIFItem, _ adjust: WIFAdjustments) -> Double {
        let base = max(0, item.weightKG)
        guard adjust.removeDrawers else { return base }
        return max(0, base - max(0, item.removableWeightKG))
    }

    // MARK: Route

    static func run(item: WIFItem, route: WIFRoute, adjust: WIFAdjustments, unit: WIFUnit) -> WIFCheckResult {
        let size = effectiveSize(item, adjust)
        let stages = route.stops.map { stage(for: $0, size: size, adjust: adjust, unit: unit) }

        var tightest: WIFStageOutcome? = nil
        for outcome in stages {
            guard let current = tightest else { tightest = outcome; continue }
            if outcome.marginMM < current.marginMM { tightest = outcome }
        }

        let worst = stages.map { $0.verdict.rank }.max() ?? 0
        let overall: WIFVerdict = worst == 2 ? .blocked : (worst == 1 ? .rotated : .clear)

        var notes: [String] = []
        if adjust.removePackaging && item.packagingMM > 0 {
            notes.append("Packaging off: every side is " + WIFMeasure.label(item.packagingMM, unit) + " smaller.")
        }
        if adjust.removeLegs && item.legHeightMM > 0 {
            notes.append("Legs off: " + WIFMeasure.label(item.legHeightMM, unit) + " shorter.")
        }
        if adjust.removeDrawers && item.removableWeightKG > 0 {
            notes.append("Drawers and shelves out: " + WIFMeasure.weightText(item.removableWeightKG)
                         + " lighter. Size is unchanged — this only makes the carry easier.")
        }
        if adjust.liftDoorOffHinges {
            notes.append("Door leaves off their hinges: every opening on the route is wider by its own hinge gain.")
        }
        if !adjust.allowTilt {
            notes.append("Tilting is off: the object stays on its feet and may only be turned on the spot.")
        }

        return WIFCheckResult(stages: stages,
                              tightestStageID: tightest?.id,
                              verdict: overall,
                              effectiveWidth: size.w,
                              effectiveHeight: size.h,
                              effectiveDepth: size.d,
                              effectiveWeight: effectiveWeight(item, adjust),
                              adjustmentNotes: notes)
    }

    // MARK: One stage

    static func stage(for obstacle: WIFObstacle,
                      size: (w: Double, h: Double, d: Double),
                      adjust: WIFAdjustments,
                      unit: WIFUnit) -> WIFStageOutcome {
        switch obstacle.kind {
        case .opening:
            return openingStage(obstacle, size, adjust, unit)
        case .turn, .stair:
            return turnStage(obstacle, size, adjust, unit)
        case .elevator:
            return elevatorStage(obstacle, size, adjust, unit)
        }
    }

    // MARK: Opening

    private static func openingWidth(_ obstacle: WIFObstacle, _ adjust: WIFAdjustments) -> Double {
        obstacle.openWidthMM + (adjust.liftDoorOffHinges ? max(0, obstacle.hingeGainMM) : 0)
    }

    private static func openingAttempt(poses: [WIFOpeningPose],
                                       width: Double,
                                       height: Double,
                                       rotate: Bool) -> WIFAttempt {
        var best = WIFAttempt.impossible
        for pose in poses {
            let fit = WIFGeom.rectInRect(across: pose.across,
                                         up: pose.up,
                                         width: width,
                                         height: height,
                                         rotate: rotate)
            let slack = min(fit.slackWidth, fit.slackHeight)
            if slack > best.slack {
                let plan = WIFOpeningPlan(openWidth: width,
                                          openHeight: height,
                                          sideAcross: pose.across,
                                          sideUp: pose.up,
                                          angleDeg: fit.angle,
                                          slackWidth: fit.slackWidth,
                                          slackHeight: fit.slackHeight)
                best = WIFAttempt(slack: slack,
                                  angle: fit.angle,
                                  binding: fit.slackWidth <= fit.slackHeight ? "opening width" : "opening height",
                                  pose: pose.label,
                                  drawing: .opening(plan))
            }
        }
        return best
    }

    private static func openingStage(_ obstacle: WIFObstacle,
                                     _ size: (w: Double, h: Double, d: Double),
                                     _ adjust: WIFAdjustments,
                                     _ unit: WIFUnit) -> WIFStageOutcome {
        let width = openingWidth(obstacle, adjust)
        let height = obstacle.openHeightMM
        let upright = WIFPoses.uprightOpening(w: size.w, h: size.h, d: size.d)
        let all = WIFPoses.allOpening(w: size.w, h: size.h, d: size.d)

        let natural = openingAttempt(poses: [upright[0]], width: width, height: height, rotate: false)
        let yawed = openingAttempt(poses: upright, width: width, height: height, rotate: false)
        let free = adjust.allowTilt
            ? openingAttempt(poses: all, width: width, height: height, rotate: true)
            : yawed

        let (verdict, chosen) = classify(natural: natural, yawed: yawed, free: free)

        var notes: [String] = []
        notes.append("Opening " + WIFMeasure.pair(width, height, unit)
                     + (adjust.liftDoorOffHinges && obstacle.hingeGainMM > 0
                        ? " (leaf off, +" + WIFMeasure.label(obstacle.hingeGainMM, unit) + ")" : ""))
        notes.append("Best carry: " + chosen.pose
                     + (chosen.angle > 0.01 && chosen.angle < 89.99
                        ? ", leaned over " + WIFMeasure.angleText(chosen.angle) : ", square on"))
        if case .opening(let plan) = chosen.drawing {
            notes.append("Needs " + WIFMeasure.label(plan.openWidth - plan.slackWidth, unit)
                         + " across and " + WIFMeasure.label(plan.openHeight - plan.slackHeight, unit)
                         + " up.")
        }
        if verdict == .blocked {
            notes.append("Tightest point: " + chosen.binding + ", over by "
                         + WIFMeasure.label(abs(chosen.slack), unit) + ".")
        }

        let headline: String
        switch verdict {
        case .clear:
            headline = "Goes straight through with "
                + WIFMeasure.label(chosen.slack, unit) + " to spare."
        case .rotated:
            headline = "Only fits " + chosen.pose + ". Spare room: "
                + WIFMeasure.label(chosen.slack, unit) + "."
        case .blocked:
            headline = "Too big for this opening by "
                + WIFMeasure.label(abs(chosen.slack), unit) + " on the "
                + chosen.binding.replacingOccurrences(of: "opening ", with: "") + "."
        }

        return WIFStageOutcome(id: obstacle.id,
                               name: obstacle.name,
                               kind: obstacle.kind,
                               verdict: verdict,
                               marginMM: chosen.slack,
                               binding: chosen.binding,
                               angleDeg: chosen.angle,
                               poseLabel: chosen.pose,
                               headline: headline,
                               notes: notes,
                               drawing: chosen.drawing)
    }

    // MARK: Turn and stairwell

    private static func turnAttempt(poses: [WIFCarryPose],
                                    obstacle: WIFObstacle,
                                    unit: WIFUnit) -> WIFAttempt {
        var best = WIFAttempt.impossible
        let headroom = max(0, obstacle.headroomMM)
        for pose in poses {
            let headSlack = headroom > 0 ? headroom - pose.vertical : Double.greatestFiniteMagnitude
            let turn = WIFGeom.turnClearance(length: pose.length,
                                             width: pose.width,
                                             corridorA: obstacle.corridorAMM,
                                             corridorB: obstacle.corridorBMM)
            let slack = min(headSlack, turn.clearance)
            if slack > best.slack {
                let plan = WIFTurnPlan(corridorA: obstacle.corridorAMM,
                                       corridorB: obstacle.corridorBMM,
                                       length: pose.length,
                                       width: pose.width,
                                       angleDeg: turn.angle,
                                       clearanceMM: turn.clearance)
                var extra: [String] = []
                if let limit = WIFGeom.longestThroughTurn(width: pose.width,
                                                          corridorA: obstacle.corridorAMM,
                                                          corridorB: obstacle.corridorBMM) {
                    extra.append("At " + WIFMeasure.label(pose.width, unit)
                                 + " across, the longest object this corner takes is "
                                 + WIFMeasure.label(limit.length, unit) + ".")
                } else {
                    extra.append("The object is wider than one of the corridors, so no length fits.")
                }
                best = WIFAttempt(slack: slack,
                                  angle: turn.angle,
                                  binding: headSlack < turn.clearance ? "headroom" : "inner corner",
                                  pose: pose.label,
                                  drawing: .turn(plan),
                                  extra: extra)
            }
        }
        return best
    }

    private static func turnStage(_ obstacle: WIFObstacle,
                                  _ size: (w: Double, h: Double, d: Double),
                                  _ adjust: WIFAdjustments,
                                  _ unit: WIFUnit) -> WIFStageOutcome {
        let upright = WIFPoses.uprightCarry(w: size.w, h: size.h, d: size.d)
        let all = WIFPoses.allCarry(w: size.w, h: size.h, d: size.d)

        let natural = turnAttempt(poses: [upright[0]], obstacle: obstacle, unit: unit)
        let yawed = turnAttempt(poses: upright, obstacle: obstacle, unit: unit)
        let free = adjust.allowTilt ? turnAttempt(poses: all, obstacle: obstacle, unit: unit) : yawed

        let (verdict, chosen) = classify(natural: natural, yawed: yawed, free: free)

        var notes: [String] = []
        notes.append("Corridors " + WIFMeasure.pair(obstacle.corridorAMM, obstacle.corridorBMM, unit)
                     + (obstacle.headroomMM > 0
                        ? ", headroom " + WIFMeasure.label(obstacle.headroomMM, unit) : ""))
        notes.append("Best carry: " + chosen.pose + ".")
        if chosen.binding == "inner corner" {
            if chosen.angle <= 0.26 {
                notes.append("The tightest moment is before the turn even starts — the object is "
                             + "as wide as the first corridor allows.")
            } else if chosen.angle >= 89.74 {
                notes.append("The tightest moment is after the turn — the object is as wide as the "
                             + "second corridor allows.")
            } else {
                notes.append("Worst angle: " + WIFMeasure.angleText(chosen.angle)
                             + " into the turn. That is the moment the corner bites.")
            }
        } else {
            notes.append("The headroom runs out before the corner does.")
        }
        notes.append(contentsOf: chosen.extra)

        let headline: String
        switch verdict {
        case .clear:
            headline = "Turns the corner with " + WIFMeasure.label(chosen.slack, unit)
                + " to spare at its worst angle."
        case .rotated:
            headline = "Turns only " + chosen.pose + " — "
                + WIFMeasure.label(chosen.slack, unit) + " to spare at the worst angle."
        case .blocked:
            headline = chosen.binding == "headroom"
                ? "Too tall for the headroom by " + WIFMeasure.label(abs(chosen.slack), unit) + "."
                : "Jams at the inner corner: it overlaps by "
                    + WIFMeasure.label(abs(chosen.slack), unit) + " at "
                    + WIFMeasure.angleText(chosen.angle) + "."
        }

        return WIFStageOutcome(id: obstacle.id,
                               name: obstacle.name,
                               kind: obstacle.kind,
                               verdict: verdict,
                               marginMM: chosen.slack,
                               binding: chosen.binding,
                               angleDeg: chosen.angle,
                               poseLabel: chosen.pose,
                               headline: headline,
                               notes: notes,
                               drawing: chosen.drawing)
    }

    // MARK: Lift

    private static func cabinAttempt(w: Double, h: Double, d: Double,
                                     obstacle: WIFObstacle,
                                     level: Int) -> WIFAttempt {
        // level 0 = square on the walls, 1 = free to turn on the spot, 2 = free to lean as well.
        if level == 0 {
            let heightSlack = obstacle.cabinHeightMM - h
            let acrossSlack = obstacle.cabinWidthMM - w
            let depthSlack = obstacle.cabinDepthMM - d
            let slack = min(heightSlack, min(acrossSlack, depthSlack))
            var binding = "cabin height"
            if acrossSlack <= heightSlack && acrossSlack <= depthSlack { binding = "cabin width" }
            else if depthSlack <= heightSlack { binding = "cabin depth" }
            return WIFAttempt(slack: slack, angle: 0, binding: binding, pose: "standing square", drawing: nil)
        }

        if level == 1 {
            let heightSlack = obstacle.cabinHeightMM - h
            let floor = WIFGeom.floorSlack(footprint: w,
                                           wide: d,
                                           width: obstacle.cabinWidthMM,
                                           depth: obstacle.cabinDepthMM)
            let slack = min(heightSlack, floor.slack)
            return WIFAttempt(slack: slack,
                              angle: floor.angle,
                              binding: heightSlack <= floor.slack ? "cabin height" : "cabin floor",
                              pose: floor.angle > 0.01 && floor.angle < 89.99
                                  ? "standing on the diagonal" : "standing square",
                              drawing: nil)
        }

        var best = WIFAttempt.impossible
        let axes: [(Double, Double, Double, String)] = [
            (h, d, w, "leaned back on its own height"),
            (h, w, d, "leaned sideways on its own height"),
            (w, h, d, "up on one end"),
            (w, d, h, "up on one end, turned"),
            (d, h, w, "up on its back edge"),
            (d, w, h, "up on its back edge, turned")
        ]
        for axis in axes {
            let lean = WIFGeom.leanInside(long: axis.0,
                                          thick: axis.1,
                                          wide: axis.2,
                                          cabinWidth: obstacle.cabinWidthMM,
                                          cabinDepth: obstacle.cabinDepthMM,
                                          cabinHeight: obstacle.cabinHeightMM,
                                          allowTilt: true)
            if lean.slack > best.slack {
                let pose = lean.angle < 0.26 ? "standing upright" : axis.3
                best = WIFAttempt(slack: lean.slack,
                                  angle: lean.angle,
                                  binding: lean.binding,
                                  pose: pose,
                                  drawing: nil)
            }
        }
        return best
    }

    private static func elevatorStage(_ obstacle: WIFObstacle,
                                      _ size: (w: Double, h: Double, d: Double),
                                      _ adjust: WIFAdjustments,
                                      _ unit: WIFUnit) -> WIFStageOutcome {
        let doorWidth = openingWidth(obstacle, adjust)
        let doorHeight = obstacle.openHeightMM
        let upright = WIFPoses.uprightOpening(w: size.w, h: size.h, d: size.d)
        let all = WIFPoses.allOpening(w: size.w, h: size.h, d: size.d)

        // The door and the cabin are independent: whatever pose gets the object through the
        // doorway, it can be turned again once it is inside. So each half takes its own best.
        let doorNatural = openingAttempt(poses: [upright[0]], width: doorWidth, height: doorHeight, rotate: false)
        let doorYawed = openingAttempt(poses: upright, width: doorWidth, height: doorHeight, rotate: false)
        let doorFree = adjust.allowTilt
            ? openingAttempt(poses: all, width: doorWidth, height: doorHeight, rotate: true)
            : doorYawed

        let cabinNatural = cabinAttempt(w: size.w, h: size.h, d: size.d, obstacle: obstacle, level: 0)
        let cabinYawed = cabinAttempt(w: size.w, h: size.h, d: size.d, obstacle: obstacle, level: 1)
        let cabinFree = adjust.allowTilt
            ? cabinAttempt(w: size.w, h: size.h, d: size.d, obstacle: obstacle, level: 2)
            : cabinYawed

        let natural = combine(doorNatural, cabinNatural, doorLabel: "door", cabinLabel: "cabin")
        let yawed = combine(doorYawed, cabinYawed, doorLabel: "door", cabinLabel: "cabin")
        let free = combine(doorFree, cabinFree, doorLabel: "door", cabinLabel: "cabin")

        let (verdict, chosen) = classify(natural: natural, yawed: yawed, free: free)

        // The drawing always shows the door, because that is the half with a picture. Least effort
        // first: never describe a pose that needs tilting when the object walks straight through.
        let doorAttempt = [doorNatural, doorYawed, doorFree].first(where: { $0.slack >= 0 }) ?? doorFree

        var notes: [String] = []
        notes.append("Door " + WIFMeasure.pair(doorWidth, doorHeight, unit) + ", cabin "
                     + WIFMeasure.triple(obstacle.cabinWidthMM, obstacle.cabinDepthMM,
                                         obstacle.cabinHeightMM, unit) + ".")
        notes.append("Through the door: " + doorAttempt.pose
                     + (doorAttempt.angle > 0.01 && doorAttempt.angle < 89.99
                        ? ", leaned over " + WIFMeasure.angleText(doorAttempt.angle) : ", square on")
                     + " — " + WIFMeasure.signedLabel(doorAttempt.slack, unit) + " to spare.")
        let cabin = adjust.allowTilt ? cabinFree : cabinYawed
        notes.append("Inside the cabin: " + cabin.pose
                     + (cabin.angle > 0.26 && cabin.angle < 89.74
                        ? " at " + WIFMeasure.angleText(cabin.angle) : "")
                     + " — " + WIFMeasure.signedLabel(cabin.slack, unit) + " to spare.")
        notes.append("Tightest of the two: " + chosen.binding + ".")

        let headline: String
        switch verdict {
        case .clear:
            headline = "Goes in and stands up with " + WIFMeasure.label(chosen.slack, unit) + " to spare."
        case .rotated:
            headline = "Fits, but only " + chosen.pose + " — "
                + WIFMeasure.label(chosen.slack, unit) + " to spare."
        case .blocked:
            headline = "Will not fit: short of the " + chosen.binding + " by "
                + WIFMeasure.label(abs(chosen.slack), unit) + "."
        }

        return WIFStageOutcome(id: obstacle.id,
                               name: obstacle.name,
                               kind: obstacle.kind,
                               verdict: verdict,
                               marginMM: chosen.slack,
                               binding: chosen.binding,
                               angleDeg: chosen.angle,
                               poseLabel: chosen.pose,
                               headline: headline,
                               notes: notes,
                               drawing: doorAttempt.drawing)
    }

    // MARK: Shared helpers

    private static func combine(_ door: WIFAttempt,
                                _ cabin: WIFAttempt,
                                doorLabel: String,
                                cabinLabel: String) -> WIFAttempt {
        if door.slack <= cabin.slack {
            return WIFAttempt(slack: door.slack,
                              angle: door.angle,
                              binding: door.binding,
                              pose: door.pose + " through the " + doorLabel,
                              drawing: door.drawing)
        }
        return WIFAttempt(slack: cabin.slack,
                          angle: cabin.angle,
                          binding: cabin.binding,
                          pose: cabin.pose + " in the " + cabinLabel,
                          drawing: door.drawing)
    }

    /// Three escalating levels of effort. The first that clears decides the verdict, so the app
    /// never tells someone to tilt a wardrobe that would have walked straight through.
    private static func classify(natural: WIFAttempt,
                                 yawed: WIFAttempt,
                                 free: WIFAttempt) -> (WIFVerdict, WIFAttempt) {
        if natural.slack >= 0 { return (.clear, natural) }
        if yawed.slack >= 0 { return (.rotated, yawed) }
        if free.slack >= 0 { return (.rotated, free) }
        var best = natural
        if yawed.slack > best.slack { best = yawed }
        if free.slack > best.slack { best = free }
        return (.blocked, best)
    }
}
