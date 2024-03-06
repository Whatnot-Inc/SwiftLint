import SwiftSyntax
import SwiftLintCore

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
            Example("""
                let locale = ↓Locale(identifier: "en_US")
            """),
            Example("let locale = ↓Locale.current"),
            Example("↓Locale()"),
            Example("↓Locale.init()"),
            Example("↓Locale.current"),
            Example("""
                Decimal(string: "123", ↓locale: .current)
            """),
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension LocaleOverrideRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if isReferencingCurrentLocale(node) {
                violations.append(reason(position: node.positionAfterSkippingLeadingTrivia))
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if isLocaleInitializer(node) {
                violations.append(reason(position: node.positionAfterSkippingLeadingTrivia))
            } else if let localeArgument = currentLocaleAsFunctionArgument(node) {
                violations.append(reason(position: localeArgument.positionAfterSkippingLeadingTrivia))
            }
        }
    }
}

private extension LocaleOverrideRule.Visitor {
    func isReferencingCurrentLocale(_ node: MemberAccessExprSyntax) -> Bool {
        if let identifierExp = node.base?.as(IdentifierExprSyntax.self),
           identifierExp.identifier.text == "Locale",
           node.name.text == "current" {
            return true
        }

        return false
    }

    func isLocaleInitializer(_ node: FunctionCallExprSyntax) -> Bool {
        if let identifierExp = node.calledExpression.as(IdentifierExprSyntax.self),
           identifierExp.identifier.text == "Locale" {
            return true
        }

        return false
    }

    func currentLocaleAsFunctionArgument(_ node: FunctionCallExprSyntax) -> TupleExprElementListSyntax.Element? {
        node.argumentList.first(where: { element in
            element.label?.text == "locale" && element.expression.as(MemberAccessExprSyntax.self)?.name.text == "current"
        })
    }
}

private extension LocaleOverrideRule.Visitor {
    func reason(position: AbsolutePosition) -> ReasonedRuleViolation {
        .init(
            position: position,
            reason: "Locale.overriddenOrCurrent allows us to override the locale for testing purposes; prefer it over other instances of Locale",
            severity: .warning
        )
    }
}
