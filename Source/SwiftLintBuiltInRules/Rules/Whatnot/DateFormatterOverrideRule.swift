import SwiftSyntax

struct DateFormatterOverrideRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    static let description = RuleDescription(
        identifier: "date_formatter_override",
        name: "DateFormatter Override",
        description: "Please use DateFormatter.whatnotFormatter",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let df = DateFormatter.whatnotFormatter"),
            Example("DateFormatter.whatnotFormatter")
        ],
        triggeringExamples: [
            Example("let df = ↓DateFormatter.init()"),
            Example("let df = ↓DateFormatter()"),
            Example("let df = ↓DateFormatter.anotherStaticInit"),
            Example("↓DateFormatter()"),
            Example("↓DateFormatter.init()"),
            Example("↓DateFormatter.anotherStaticInit")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

extension DateFormatterOverrideRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if let identifierExp = node.base?.as(IdentifierExprSyntax.self),
               identifierExp.identifier.text == "DateFormatter",
               node.name.text != "whatnotFormatter" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExp = node.calledExpression.as(IdentifierExprSyntax.self),
               identifierExp.identifier.text == "DateFormatter",
               node.argumentList.isEmpty {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
