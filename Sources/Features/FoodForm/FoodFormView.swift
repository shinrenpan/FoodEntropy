import PhotosUI
import SwiftUI

struct FoodFormView: View {
    let viewModel: FoodFormViewModel

    @State private var showImageDialog = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var librarySelection: PhotosPickerItem?

    var body: some View {
        @Bindable var bVM = viewModel

        Form {
            Section {
                TextField("Food name", text: $bVM.state.name)
            }

            Section {
                DatePicker(
                    "Purchase date",
                    selection: purchaseDateBinding(),
                    displayedComponents: .date
                )
                DatePicker(
                    "Expiry date",
                    selection: $bVM.state.expiryDate,
                    in: viewModel.state.purchaseDate...,
                    displayedComponents: .date
                )
                // 價格：選填、只收數值。幣別符號取自 locale 僅供辨識，使用者不輸入符號；
                // 空白即 nil（TextField 的 optional 重載），小數點分隔符由系統依地區處理。
                LabeledContent("Price") {
                    HStack(spacing: 4) {
                        Text(Locale.current.currencySymbol ?? "")
                            .foregroundStyle(.secondary)
                        TextField("Optional", value: $bVM.state.price, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            Section("Photo") {
                ImageRow(imageData: viewModel.state.imageData) {
                    showImageDialog = true
                }
                // 掛在觸發列上（而非 Form 根層），確保 dialog 錨點正確、不會跑到畫面頂部。
                .confirmationDialog("Food Photo", isPresented: $showImageDialog, titleVisibility: .visible) {
                    Button("Take Photo") { showCamera = true }
                    Button("Choose from Library") { showLibrary = true }
                    if viewModel.state.imageData != nil {
                        Button("Remove Photo", role: .destructive) {
                            Task { await viewModel.doAction(.view(.removeImage)) }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }

                // 已有照片時，下方 load 大圖預覽（完整顯示、不裁切）。
                if let data = viewModel.state.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 12))
                        .accessibilityLabel("Food Photo")
                }
            }
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    Task { await viewModel.doAction(.view(.dismissDidTap)) }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await viewModel.doAction(.view(.saveDidTap)) }
                }
                .disabled(!viewModel.state.isSaveEnabled)
            }
        }
        .photosPicker(isPresented: $showLibrary, selection: $librarySelection, matching: .images)
        .onChange(of: librarySelection) { _, newValue in
            handleLibrarySelection(newValue)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { uiImage in
                let data = ImageCompressor.compressedJPEGData(from: uiImage)
                Task { await viewModel.doAction(.view(.imagePicked(data))) }
            }
            .ignoresSafeArea()
        }
        .alert("Discard changes?", isPresented: $bVM.state.showDiscardConfirm) {
            Button("Discard", role: .destructive) {
                Task { await viewModel.doAction(.view(.discardConfirmed)) }
            }
            Button("Keep Editing", role: .cancel) {
                Task { await viewModel.doAction(.view(.discardCancelled)) }
            }
        }
    }

    // 購買日改期帶邏輯（頂推到期日）→ 走 doAction
    private func purchaseDateBinding() -> Binding<Date> {
        Binding(
            get: { viewModel.state.purchaseDate },
            set: { newValue in
                Task { await viewModel.doAction(.view(.purchaseDateChanged(newValue))) }
            }
        )
    }

    private func handleLibrarySelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            if let data, let uiImage = UIImage(data: data) {
                let compressed = ImageCompressor.compressedJPEGData(from: uiImage)
                await viewModel.doAction(.view(.imagePicked(compressed)))
            }
            librarySelection = nil
        }
    }
}

// MARK: - L2 / L3

private extension FoodFormView {
    struct ImageRow: View {
        let imageData: Data?
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    thumbnail()
                    Text(imageData == nil ? "Add Photo" : "Change Photo")
                        .foregroundStyle(.tint)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder private func thumbnail() -> some View {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "camera")
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }
}

// MARK: - CameraPicker（UIImagePickerController 橋接；模擬器無相機）

struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void

        init(onImage: @escaping (UIImage) -> Void) {
            self.onImage = onImage
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("新增") {
    NavigationStack {
        FoodFormView(viewModel: FoodFormViewModel(mode: .add, manager: try! SwiftDataManager(inMemory: true)))
    }
}

#Preview("編輯") {
    NavigationStack {
        FoodFormView(viewModel: FoodFormViewModel(mode: .edit(.mock), manager: try! SwiftDataManager(inMemory: true)))
    }
}
#endif
