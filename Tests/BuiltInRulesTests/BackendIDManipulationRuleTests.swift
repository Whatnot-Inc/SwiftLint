@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class BackendIDManipulationRuleTests: SwiftLintTestCase {
    func testDirectIDUsageDoesNotTrigger() {
        let nonTriggeringExamples = [
            Example("let userID = user.id"),
            Example("if user.id == otherUser.id { }"),
            Example("let directUsage = listing.id"),
            Example("Data(image.jpegData()).base64EncodedString()"),
            Example("let split = text.split(separator: \";\")"),
            Example("let canonical = data.canonicalForm"),
        ]

        for example in nonTriggeringExamples {
            XCTAssertEqual(
                violations(example).count, 0,
                "Should not trigger for: \(example.code)"
            )
        }
    }

    func testIDDecodingMethodsTriggered() {
        let triggeringExamples = [
            Example("let decoded = userID.canonicalId"),
            Example("let numeric = orderID.decodedNumericId"),
            Example("let unsigned = categoryID.unsignedIntID"),
            Example("let decoded = listingID.decodedIdentifier()"),
        ]

        for example in triggeringExamples {
            XCTAssertEqual(
                violations(example).count, 1,
                "Should trigger for: \(example.code)"
            )
        }
    }

    func testIDEncodingMethodsTriggered() {
        let triggeringExamples = [
            Example("let encoded = 123.encodedUserId()"),
            Example("let encoded = id.encodedIdWithName(\"UserNode\")"),
        ]

        for example in triggeringExamples {
            XCTAssertEqual(
                violations(example).count, 1,
                "Should trigger for: \(example.code)"
            )
        }
    }

    func testEncodedWhatnotIDPropertyWrapperTriggered() {
        let example = Example("@EncodedWhatnotID var userID: String")
        XCTAssertEqual(violations(example).count, 1)
    }
}
