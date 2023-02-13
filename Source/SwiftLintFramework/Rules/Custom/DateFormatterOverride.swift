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
        ],
        triggeringExamples: [
            Example("let df = ↓DateFormatter()"),
        ]
    )
    
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

extension DateFormatterOverrideRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let calledExpression = node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text,
               calledExpression == "DateFormatter",
               node.argumentList.isEmpty {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
