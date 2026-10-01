
import LoopKit

final class BasalExportTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1700000000)

    func testScheduledBasisIsPreservedAsNote() throws {
        let dose = DoseEntry(type: .basal, startDate: start, endDate: start.addingTimeInterval(3600),
            value: 0.5, unit: .units, syncIdentifier: "BasalRateSchedule synthetic")
        let treatment = try XCTUnwrap(dose.treatment(enteredBy: "loop://synthetic", withObjectId: nil))
        let dictionary = treatment.dictionaryRepresentation
        XCTAssertEqual(dictionary["eventType"] as? String, "Note")
        XCTAssertNil(dictionary["insulin"])
        XCTAssertNil(dictionary["rate"])
        let data = try XCTUnwrap((dictionary["notes"] as? String)?.data(using: .utf8))
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(payload["basis"] as? String, "scheduleDerived")
        XCTAssertEqual(payload["units"] as? Double, 0.5)
        XCTAssertEqual(dictionary["syncIdentifier"] as? String, "BasalRateSchedule synthetic")
    }

    func testExplicitDeliveredUnitsTakePrecedence() throws {
        let dose = DoseEntry(type: .basal, startDate: start, endDate: start.addingTimeInterval(3600),
            value: 0.5, unit: .units, deliveredUnits: 0.45, syncIdentifier: "synthetic")
        let treatment = try XCTUnwrap(dose.treatment(enteredBy: "loop://synthetic", withObjectId: nil))
        let data = try XCTUnwrap((treatment.dictionaryRepresentation["notes"] as? String)?.data(using: .utf8))
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(payload["units"] as? Double, 0.45)
        XCTAssertEqual(payload["basis"] as? String, "reportedDeliveredUnits")
    }

    func testMutableAndUnidentifiedEntriesAreExcluded() {
        let mutable = DoseEntry(type: .basal, startDate: start, value: 0.5, unit: .units,
            syncIdentifier: "synthetic", isMutable: true)
        let unidentified = DoseEntry(type: .basal, startDate: start, value: 0.5, unit: .units)
        XCTAssertNil(mutable.treatment(enteredBy: "loop://synthetic", withObjectId: nil))
        XCTAssertNil(unidentified.treatment(enteredBy: "loop://synthetic", withObjectId: nil))
    }
}
