enum EditingLayerInteractivity {
    static func shouldAllowStaticDisplayHitTesting(isEditing: Bool) -> Bool {
        !isEditing
    }

    static func shouldCommitOnEndEditing(
        didBeginEditing: Bool,
        didCommitFromCommand: Bool,
        didCancelFromCommand: Bool
    ) -> Bool {
        didBeginEditing && !didCommitFromCommand && !didCancelFromCommand
    }
}
