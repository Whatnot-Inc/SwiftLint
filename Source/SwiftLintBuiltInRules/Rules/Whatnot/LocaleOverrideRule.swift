import SwiftSyntax

struct LocaleOverrideRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    static let description = RuleDescription(
        identifier: "locale_override",
        name: "Locale Override",
        description: "Please use Locale.overriddenOrCurrent",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let df = Locale.overriddenOrCurrent"),
            Example("Locale.overriddenOrCurrent"),
            Example("locale: .overriddenOrCurrent"),
        ],
        triggeringExamples: [
            Example("let locale = ↓Locale.init()"),
            Example("let locale = ↓Locale()"),
            Example("let locale = ↓Locale.current"),
            Example("↓Locale()"),
            Example("↓Locale.init()"),
            Example("↓Locale.current"),
            Example("↓locale: .current"),
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

extension LocaleOverrideRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if let identifierExp = node.base?.as(IdentifierExprSyntax.self),
               identifierExp.identifier.text == "Locale",
               node.name.text != "overriddenOrCurrent" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExp = node.calledExpression.as(IdentifierExprSyntax.self),
               identifierExp.identifier.text == "Locale",
               node.argumentList.isEmpty {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            } else if node.argumentList.contains(where: { element in
                element.label?.text == "locale" && element.expression.as(MemberAccessExprSyntax.self)?.name.text == "current"
            }) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
