import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true)
struct SerializableEventRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "serializable_event",
        name: "Serializable Events",
        description: "Ensure that all Events are also SerializableEvents",
        kind: .lint,
        nonTriggeringExamples: [
            // Structs
            Example("""
                struct Thing {}
            """),
            Example("""
                struct Thing: SomeOtherProtocol {}
            """),
            Example("""
                struct Thing: SomeOtherProtocolWithEventInTheName {}
            """),
            Example("""
                struct MyEvent: Event, SerializableEvent {}
            """),
            // Classes
            Example("""
                class Thing {}
            """),
            Example("""
                class Thing: SomeOtherProtocol {}
            """),
            Example("""
                class Thing: SomeOtherProtocolWithEventInTheName {}
            """),
            Example("""
                class MyEvent: Event, SerializableEvent {}
            """),
        ],
        triggeringExamples: [
            // Struct
            Example("""
                struct ↓MyEvent: Event {}
            """),
            Example("""
                struct ↓MyEvent: SerializableEvent {}
            """),
            // Class
            Example("""
                class ↓MyEvent: Event {}
            """),
            Example("""
                class ↓MyEvent: SerializableEvent {}
            """),
        ]
    )
}

private extension SerializableEventRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: StructDeclSyntax) {
            guard let inheritedTypes = node.inheritanceClause?.inheritedTypes else { return }
            verify(
                name: node.name.text,
                position: node.name.positionAfterSkippingLeadingTrivia,
                inheritedTypes: inheritedTypes
            )
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            guard let inheritedTypes = node.inheritanceClause?.inheritedTypes else { return }
            verify(
                name: node.name.text,
                position: node.name.positionAfterSkippingLeadingTrivia,
                inheritedTypes: inheritedTypes
            )
        }

        private func verify(
            name: String,
            position: AbsolutePosition,
            inheritedTypes: InheritedTypeListSyntax
        ) {
            // helper funcs; defined inline so they can conveniently capture variables
            func adopts(_ type: String) -> Bool {
                inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.typeName == type })
            }

            func error(_ message: String) {
                violations.append(ReasonedRuleViolation(
                    position: position,
                    reason: "'\(name)' " + message,
                    severity: configuration.severity
                ))
            }

            // Here's the logic
            if adopts("Event") && !adopts("SerializableEvent") {
                error("adopts 'Event', so it must also adopt 'SerializableEvent'")
            }
            if adopts("SerializableEvent") && !adopts("Event") {
                error("adopts 'SerializableEvent', so it must also adopt 'Event'")
            }
        }
    }
}
