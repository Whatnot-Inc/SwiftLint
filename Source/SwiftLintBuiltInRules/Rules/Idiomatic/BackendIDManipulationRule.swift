import SwiftSyntax

@SwiftSyntaxRule
struct BackendIDManipulationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "backend_id_manipulation",
        name: "Backend ID Manipulation",
        description: "Avoid manipulating backend IDs. Use them as opaque values from GQL API",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let userID = user.id"), // Direct usage
            Example("if user.id == otherUser.id { }"), // Direct comparison
            Example("let directUsage = listing.id"), // Direct ID usage
            Example("identity.unsignedIntIDForLiveXP"), // Local Identity struct
            Example("identity.canonicalIDForAnalytics"), // Local Identity struct
            Example("func canonicalId() -> String { }"), // Method definition
            Example("Data(image.jpegData()).base64EncodedString()"), // Non-ID base64
            Example("let split = text.split(separator: \";\")"), // Non-ID string splitting (semicolon)
            Example("let canonical = data.canonicalForm"), // Non-ID canonical usage
        ],
        triggeringExamples: [
            Example("let decoded = userID↓.canonicalId"),
            Example("let numeric = orderID↓.decodedNumericId"),
            Example("let unsigned = categoryID↓.unsignedIntID"),
            Example("let decoded = listingID↓.decodedIdentifier()"),
            Example("let encoded = userID↓.encodedUserId()"),
            Example("let encoded = id↓.encodedIdWithName(\"UserNode\")"),
            Example("@EncodedWhatnotID var ↓userID: String"), // Property wrapper
            Example("EncodedWhatnotID(↓wrappedValue: \"test\")"), // Constructor
            Example("Data(\"UserNode:\\(id)\".utf8)↓.base64EncodedString()"), // Manual encoding
            Example("Data(base64Encoded: idString)↓?.split(separator: \":\")"), // Manual decoding
        ]
    )
}

extension BackendIDManipulationRule {
    private final class Visitor: ViolationsSyntaxVisitor<SeverityConfiguration<BackendIDManipulationRule>> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            checkMemberAccess(node)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            checkFunctionCall(node)
        }

        override func visitPost(_ node: AttributeSyntax) {
            checkAttribute(node)
        }

        // MARK: - ID Decoding/Encoding Method Detection

        private func checkMemberAccess(_ node: MemberAccessExprSyntax) {
            let memberName = node.declName.baseName.text

            // Flag ALL ID manipulation methods - no exceptions
            switch memberName {
            case "canonicalId", "decodedNumericId", "unsignedIntID":
                violations.append(node.declName.positionAfterSkippingLeadingTrivia)
            default:
                break
            }
        }

        private func checkFunctionCall(_ node: FunctionCallExprSyntax) {
            guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) else { return }
            let methodName = memberAccess.declName.baseName.text

            // Flag ALL ID manipulation methods - no exceptions
            switch methodName {
            case "decodedIdentifier", "encodedUserId", "encodedIdWithName":
                violations.append(memberAccess.declName.positionAfterSkippingLeadingTrivia)
            case "base64EncodedString":
                if isManualIDEncoding(memberAccess.base) {
                    violations.append(memberAccess.declName.positionAfterSkippingLeadingTrivia)
                }
            case "split":
                if isManualIDDecoding(node) {
                    violations.append(memberAccess.declName.positionAfterSkippingLeadingTrivia)
                }
            default:
                break
            }
        }

        private func checkAttribute(_ node: AttributeSyntax) {
            guard let identifier = node.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "EncodedWhatnotID" else { return }
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        // MARK: - Context Analysis

        private func isManualIDEncoding(_ base: ExprSyntax?) -> Bool {
            guard let base else { return false }
            let baseText = base.description

            // Look for pattern: Data("ModelName:" + id).base64EncodedString()
            return baseText.contains("Data(") &&
                   baseText.contains("Node:") &&
                   baseText.contains(".utf8")
        }

        private func isManualIDDecoding(_ node: FunctionCallExprSyntax) -> Bool {
            // Look for pattern: base64DecodedData.split(separator: ":")
            guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
                  memberAccess.declName.baseName.text == "split",
                  let args = node.arguments.first,
                  args.label?.text == "separator" else { return false }

            // Check if argument is ":" indicating ID parsing
            let argText = args.expression.description
            return argText.contains("\":\"|") || argText.contains("\":\"")
        }
    }
}
