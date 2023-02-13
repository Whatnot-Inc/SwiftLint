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
            Example("let df = ↓DateFormatter()"),
            Example("↓DateFormatter.init()"),
            Example("↓DateFormatter()"),
            Example("let df = ↓DateFormatter.anotherStaticInit"),
        ]
    )
    
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        let vis = Visitor(viewMode: .sourceAccurate)
        return vis
    }
}

extension DateFormatterOverrideRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text == "DateFormatter", node.argumentList.isEmpty {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
            
            if let memberAccessExp = node.calledExpression.as(MemberAccessExprSyntax.self),
               let identifierExp = memberAccessExp.base?.as(IdentifierExprSyntax.self),
               identifierExp.identifier.text == "DateFormatter" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
        
        override func visitPost(_ node: VariableDeclSyntax) {
            for binding in node.bindings {
                if let initializerClause = binding.initializer?.as(InitializerClauseSyntax.self),
                   let memberAccessExp = initializerClause.value.as(MemberAccessExprSyntax.self),
                   let identifierExp = memberAccessExp.base?.as(IdentifierExprSyntax.self),
                   identifierExp.identifier.text == "DateFormatter",
                   memberAccessExp.name.text != "whatnotFormatter"
                {
                    violations.append(memberAccessExp.positionAfterSkippingLeadingTrivia)
                    return
                }
                
                else if let initializerClause = binding.initializer?.as(InitializerClauseSyntax.self),
                        let functionCallExp = initializerClause.value.as(FunctionCallExprSyntax.self),
                        let memberAccessExp = functionCallExp.calledExpression.as(MemberAccessExprSyntax.self),
                        let identifierExp = memberAccessExp.base?.as(IdentifierExprSyntax.self),
                        identifierExp.identifier.text == "DateFormatter"
                {
                    violations.append(memberAccessExp.positionAfterSkippingLeadingTrivia)
                    return
                }
            }
        }
    }
}
