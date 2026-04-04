import SwiftUI

struct ManagePartitionsView: View {
    @Binding var partitions: [Partition]
    let onDelete: (String) -> Void
    let onDismiss: () -> Void

    @State private var partitionToDelete: Partition? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Partitions")
                    .font(DesignTokens.Typography.modalTitle)
                    .foregroundStyle(DesignTokens.ColorRole.primaryText)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.modalHorizontal)
            .padding(.vertical, DesignTokens.Spacing.modalHeaderVertical)

            Divider().opacity(DesignTokens.Stroke.dividerOpacity)

            // Partition list
            List {
                ForEach(partitions) { partition in
                    HStack(spacing: 10) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(partition.color.color)
                            .frame(width: DesignTokens.Size.modalPartitionDot, height: DesignTokens.Size.modalPartitionDot)

                        Text(partition.name.isEmpty ? "Untitled" : partition.name)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundStyle(DesignTokens.ColorRole.primaryText)

                        Spacer()

                        Button {
                            partitionToDelete = partition
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, DesignTokens.Spacing.modalListRowVertical)
                }
                .onMove { source, destination in
                    partitions.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.inset)

            Divider().opacity(DesignTokens.Stroke.dividerOpacity)

            // Footer buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    onDismiss()
                }
                .controlSize(.small)

                Button("Save Order") {
                    onDismiss()
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, DesignTokens.Spacing.modalHorizontal)
            .padding(.vertical, DesignTokens.Spacing.modalFooterVertical)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .frame(minHeight: DesignTokens.Size.modalMinHeight, maxHeight: DesignTokens.Size.modalMaxHeight)
        .frame(width: DesignTokens.Size.modalWidth)
        .alert("Delete Partition?", isPresented: $showDeleteConfirmation, presenting: partitionToDelete) { partition in
            Button("Cancel", role: .cancel) {
                partitionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                onDelete(partition.id)
                partitionToDelete = nil
            }
        } message: { partition in
            Text("Are you sure you want to delete \"\(partition.name.isEmpty ? "Untitled" : partition.name)\"? All tasks inside this partition will also be deleted. This action cannot be undone.")
        }
    }
}
