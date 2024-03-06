import SwiftSyntax

@SwiftSyntaxRule
struct UnusedEnumeratedRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unused_enumerated",
        name: "Unused Enumerated",
        description: "When the index or the item is not used, `.enumerated()` can be removed.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("for (idx, foo) in bar.enumerated() { }"),
            Example("for (_, foo) in bar.enumerated().something() { }"),
            Example("for (_, foo) in bar.something() { }"),
            Example("for foo in bar.enumerated() { }"),
            Example("for foo in bar { }"),
            Example("for (idx, _) in bar.enumerated().something() { }"),
            Example("for (idx, _) in bar.something() { }"),
            Example("for idx in bar.indices { }"),
            Example("for (section, (event, _)) in data.enumerated() {}")
        ],
        triggeringExamples: [
            Example("for (↓_, foo) in bar.enumerated() { }"),
            Example("for (↓_, foo) in abc.bar.enumerated() { }"),
            Example("for (↓_, foo) in abc.something().enumerated() { }"),
            Example("for (idx, ↓_) in bar.enumerated() { }")
        ]
    )
}

private extension UnusedEnumeratedRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ForStmtSyntax) {
            guard let tuplePattern = node.pattern.as(TuplePatternSyntax.self),
                  tuplePattern.elements.count == 2,
                  let functionCall = node.sequence.asFunctionCall,
                  functionCall.isEnumerated,
                  let firstElement = tuplePattern.elements.first,
                  let secondElement = tuplePattern.elements.last,
                  case let firstTokenIsUnderscore = firstElement.isUnderscore,
                  case let lastTokenIsUnderscore = secondElement.isUnderscore,
                  firstTokenIsUnderscore || lastTokenIsUnderscore else {
                return
            }

            let position: AbsolutePosition
            let reason: String
            if firstTokenIsUnderscore {
                position = firstElement.positionAfterSkippingLeadingTrivia
                reason = "When the index is not used, `.enumerated()` can be removed"
            } else {
                position = secondElement.positionAfterSkippingLeadingTrivia
                reason = "When the item is not used, `.indices` should be used instead of `.enumerated()`"
            }

            violations.append(ReasonedRuleViolation(position: position, reason: reason))
        }
    }
}

private extension FunctionCallExprSyntax {
    var isEnumerated: Bool {
        guard let memberAccess = calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.base != nil,
              memberAccess.declName.baseName.text == "enumerated",
              hasNoArguments else {
            return false
        }

        return true
    }

    var hasNoArguments: Bool {
           trailingClosure == nil
        && additionalTrailingClosures.isEmpty
        && arguments.isEmpty
    }
}

private extension TuplePatternElementSyntax {
    var isUnderscore: Bool {
        pattern.is(WildcardPatternSyntax.self)
    }
}
