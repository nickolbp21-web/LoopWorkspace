
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


final class PreciseTempBasalExportTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1700000000.123456)
    private func metadata(_ dose: DoseEntry) throws -> ([String: Any], [String: Any]) {
        let treatment = try XCTUnwrap(dose.treatment(enteredBy: "loop://synthetic", withObjectId: nil))
        let dictionary = treatment.dictionaryRepresentation
        let raw = try XCTUnwrap((dictionary["notes"] as? String)?.data(using: .utf8))
        return (dictionary, try XCTUnwrap(JSONSerialization.jsonObject(with: raw) as? [String: Any]))
    }
    func testExactTimesAndActualZeroSurvive() throws {
        let end = start.addingTimeInterval(300.234567)
        let dose = DoseEntry(type: .tempBasal, startDate: start, endDate: end,
            value: 0.55, unit: .unitsPerHour, deliveredUnits: 0, syncIdentifier: "synthetic")
        let (row, note) = try metadata(dose)
        XCTAssertEqual(row["eventType"] as? String, "Temp Basal")
        XCTAssertEqual(row["amount"] as? Double, 0)
        XCTAssertEqual(row["rate"] as? Double, 0.55)
        XCTAssertEqual(note["units"] as? Double, 0)
        XCTAssertEqual(note["startUnixSeconds"] as? Double, start.timeIntervalSince1970)
        XCTAssertEqual(note["endUnixSeconds"] as? Double, end.timeIntervalSince1970)
        XCTAssertEqual(note["basis"] as? String, "reportedDeliveredUnits")
    }
    func testPendingOrUnknownDeliveryDoesNotGainEvidence() throws {
        for mutable in [false, true] {
            let dose = DoseEntry(type: .tempBasal, startDate: start, endDate: start.addingTimeInterval(300),
                value: 0.55, unit: .unitsPerHour, syncIdentifier: "synthetic", isMutable: mutable)
            let treatment = try XCTUnwrap(dose.treatment(enteredBy: "loop://synthetic", withObjectId: nil))
            XCTAssertNil(treatment.dictionaryRepresentation["notes"])
            XCTAssertNil(treatment.dictionaryRepresentation["amount"])
        }
    }
    func testRecordedSuspendStaysZeroWithProvenance() throws {
        let dose = DoseEntry(type: .suspend, startDate: start, endDate: start.addingTimeInterval(300),
            value: 0, unit: .units, syncIdentifier: "synthetic-suspend")
        let (row, note) = try metadata(dose)
        XCTAssertEqual(row["reason"] as? String, "suspend")
        XCTAssertNil(row["amount"])
        XCTAssertEqual(note["units"] as? Double, 0)
        XCTAssertEqual(note["basis"] as? String, "recordedUnits")
    }
}
