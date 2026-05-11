import SwiftUI

struct ManagePartitionsView: View {
    @Environment(\.interfaceDensity) private var density

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
                    .font(DesignTokens.Typography.modalTitle(in: density))
                    .foregroundStyle(DesignTokens.ColorRole.primaryText)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(DesignTokens.Typography.caption(in: density))
                        .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.scaledModalHorizontal(in: density))
            .padding(.vertical, DesignTokens.Spacing.scaledModalHeaderVertical(in: density))

            Divider().opacity(DesignTokens.Stroke.dividerOpacity)

            // Partition list
            List {
                ForEach(partitions) { partition in
                    HStack(spacing: DesignTokens.scaled(10, in: density)) {
                        Image(systemName: "line.3.horizontal")
                            .font(DesignTokens.Typography.micro(in: density))
                            .foregroundStyle(DesignTokens.ColorRole.secondaryText)

                        Text(partition.name.isEmpty ? "Untitled" : partition.name)
                            .font(DesignTokens.Typography.bodyMedium(in: density))
                            .foregroundStyle(DesignTokens.ColorRole.primaryText)

                        Spacer()

                        Button {
                            guard canDeletePartitions else { return }
                            partitionToDelete = partition
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(DesignTokens.Typography.caption(in: density))
                                .foregroundStyle(
                                    canDeletePartitions
                                        ? DesignTokens.ColorRole.secondaryText
                                        : DesignTokens.ColorRole.tertiaryText
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canDeletePartitions)
                        .help(
                            canDeletePartitions
                                ? "Delete partition"
                                : "At least one partition is required"
                        )
                    }
                    .padding(.vertical, DesignTokens.Spacing.scaledModalListRowVertical(in: density))
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
            .padding(.horizontal, DesignTokens.Spacing.scaledModalHorizontal(in: density))
            .padding(.vertical, DesignTokens.Spacing.scaledModalFooterVertical(in: density))
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .frame(minHeight: DesignTokens.Size.scaledModalMinHeight(in: density), maxHeight: DesignTokens.Size.scaledModalMaxHeight(in: density))
        .frame(width: DesignTokens.Size.scaledModalWidth(in: density))
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

    private var canDeletePartitions: Bool {
        partitions.count > 1
    }
}
