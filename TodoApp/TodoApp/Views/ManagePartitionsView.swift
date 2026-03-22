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
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Partition list
            List {
                ForEach(partitions) { partition in
                    HStack(spacing: 10) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(partition.color.color)
                            .frame(width: 10, height: 10)

                        Text(partition.name.isEmpty ? "Untitled" : partition.name)
                            .font(.system(size: 13, weight: .medium))

                        Spacer()

                        Button {
                            partitionToDelete = partition
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
                .onMove { source, destination in
                    partitions.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.inset)

            Divider()

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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 300, maxHeight: 500)
        .frame(width: 320)
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
