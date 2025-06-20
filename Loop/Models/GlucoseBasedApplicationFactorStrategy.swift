//
//  GlucoseBasedApplicationFactorStrategy.swift
//  Loop
//
//  Created by Jonas Björkert on 2023-06-03.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation
import HealthKit
import LoopKit
import LoopCore

struct GlucoseBasedApplicationFactorStrategy: ApplicationFactorStrategy {
    // Make the strategy more aggressive by increasing the min and max application factors
    static let minPartialApplicationFactor = 0.50 // increased from 0.20
    static let maxPartialApplicationFactor = 1.25 // increased from 0.80

    // Optionally reduce the sliding scale range to apply more correction sooner
    static let minGlucoseDeltaSlidingScale = 5.0  // reduced from 10.0 to make response more aggressive
    static let maxGlucoseSlidingScale = 160.0     // reduced from 200.0

    func calculateDosingFactor(
        for glucose: HKQuantity,
        correctionRangeSchedule: GlucoseRangeSchedule,
        settings: LoopSettings
    ) -> Double {
        // Calculate current glucose and lower bound target
        let currentGlucose = glucose.doubleValue(for: .milligramsPerDeciliter)
        let correctionRange = correctionRangeSchedule.quantityRange(at: Date())
        let lowerBoundTarget = correctionRange.lowerBound.doubleValue(for: .milligramsPerDeciliter)

        // Calculate minimum glucose sliding scale and scaling fraction
        let minGlucoseSlidingScale = GlucoseBasedApplicationFactorStrategy.minGlucoseDeltaSlidingScale + lowerBoundTarget

        // Protect against divide-by-zero or negative range
        guard GlucoseBasedApplicationFactorStrategy.maxGlucoseSlidingScale > minGlucoseSlidingScale else {
        return GlucoseBasedApplicationFactorStrategy.maxPartialApplicationFactor
        }

        let scalingFraction = (GlucoseBasedApplicationFactorStrategy.maxPartialApplicationFactor - GlucoseBasedApplicationFactorStrategy.minPartialApplicationFactor) / (GlucoseBasedApplicationFactorStrategy.maxGlucoseSlidingScale - minGlucoseSlidingScale)
        let scalingGlucose = max(currentGlucose - minGlucoseSlidingScale, 0.0)

        // Calculate effectiveBolusApplicationFactor
        let effectiveBolusApplicationFactor = min(GlucoseBasedApplicationFactorStrategy.minPartialApplicationFactor + scalingGlucose * scalingFraction, GlucoseBasedApplicationFactorStrategy.maxPartialApplicationFactor)

        return effectiveBolusApplicationFactor
    }
}
