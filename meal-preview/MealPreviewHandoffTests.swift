
import XCTest
import LoopKit
import HealthKit
@testable import Loop

final class MealPreviewHandoffTests: XCTestCase {
    func testActivityRoundTripPreservesReviewedMeal() throws {
        let now = Date(timeIntervalSince1970: 1800000000)
        let mealDate = now.addingTimeInterval(-120)
        let cases: [(Double, Double)] = [(20, 30), (20.5, 180), (99, 300), (250, 480)]
        for (grams, minutes) in cases {
            let url = try XCTUnwrap(URL(string: "Loop://meal-preview?v=1&grams=\(grams)&absorption_minutes=\(minutes)&meal_time=\(mealDate.timeIntervalSince1970)"))
            let preview = try XCTUnwrap(MealPreview(url: url, now: now,
                                                  minAbsorption: LoopConstants.minCarbAbsorptionTime,
                                                  maxAbsorption: LoopConstants.maxCarbAbsorptionTime))
            // This is the production factory called by the URL receiver.
            let activity = NSUserActivity.forNewCarbEntry()
            activity.update(from: preview.carbEntryForReview)
            let restored = try XCTUnwrap(activity.newCarbEntry)
            XCTAssertEqual(restored.quantity.doubleValue(for: .gram()), grams, accuracy: 0.000001)
            XCTAssertEqual(try XCTUnwrap(restored.absorptionTime), minutes * 60, accuracy: 0.000001)
            XCTAssertEqual(restored.date, mealDate)
            XCTAssertEqual(restored.startDate, mealDate)
            XCTAssertFalse(activity.entryisMissedMeal)
        }
    }
}
