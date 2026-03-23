import SwiftUI

struct PartitionEditView: View {
    let partition: Partition
    let onSave: (String, PartitionColor) -> Void

    @State private var editName: String
    @State private var editColor: PartitionColor
    @FocusState private var isNameFocused: Bool

    init(partition: Partition, onSave: @escaping (String, PartitionColor) -> Void) {
        self.partition = partition
        self.onSave = onSave
        _editName = State(initialValue: partition.name)
        _editColor = State(initialValue: partition.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                TextField("Partition Name", text: $editName, onCommit: {
                    onSave(editName.isEmpty ? "Untitled" : editName, editColor)
                })
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .bold))
                .focused($isNameFocused)

                Button {
                    onSave(editName.isEmpty ? "Untitled" : editName, editColor)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                ForEach(PartitionColor.allCases, id: \.self) { c in
                    Circle()
                        .fill(c.color)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .strokeBorder(editColor == c ? Color.blue : Color.clear, lineWidth: 2)
                                .padding(-2)
                        )
                        .onTapGesture {
                            editColor = c
                        }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.background.opacity(0.5))
        .onAppear {
            isNameFocused = true
        }
    }
}
