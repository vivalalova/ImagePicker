import SwiftUI

public
struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    private let sourceType: UIImagePickerController.SourceType
    private let imagePicked: (UIImage) -> Void
    private let canceled: () -> Void

    public init(sourceType: UIImagePickerController.SourceType, onImagePicked: @escaping (UIImage) -> Void, canceled: @escaping () -> Void = {}) {
        self.sourceType = sourceType
        self.imagePicked = onImagePicked
        self.canceled = canceled
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = self.sourceType
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onDismiss: { self.presentationMode.wrappedValue.dismiss() },
            onImagePicked: self.imagePicked, canceled: self.canceled
        )
    }
}

// MARK: - Coordinator

public extension ImagePickerView {
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let dismiss: () -> Void
        private let imagePicked: (UIImage) -> Void
        private let canceled: () -> Void

        init(onDismiss: @escaping () -> Void, onImagePicked: @escaping (UIImage) -> Void, canceled: @escaping () -> Void) {
            self.dismiss = onDismiss
            self.imagePicked = onImagePicked
            self.canceled = canceled
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            DispatchQueue.main.async {
                self.dismiss()

                if let image = info[.originalImage] as? UIImage {
                    self.imagePicked(image.fixOrientation())
                }
            }
        }

        public func imagePickerControllerDidCancel(_: UIImagePickerController) {
            DispatchQueue.main.async {
                self.dismiss()
                self.canceled()
            }
        }
    }
}

// MARK: - View Extension

public extension View {
    func imagePicker(_ item: Binding<UIImagePickerController.SourceType?>, picked: @escaping (UIImage) -> Void) -> some View {
        self.sheet(item: item) { item in
            ImagePickerView(sourceType: item) { image in
                picked(image)
            }
        }
    }

    func imagePicker(_ presented: Binding<Bool>, sourceType: UIImagePickerController.SourceType = .photoLibrary, picked: @escaping (UIImage) -> Void) -> some View {
        self.sheet(isPresented: presented) {
            ImagePickerView(sourceType: sourceType) { image in
                picked(image)
            }
        }
    }
}

extension UIImagePickerController.SourceType: Identifiable {
    public var id: Int {
        self.rawValue
    }
}

struct ImagePicker_Previews: PreviewProvider {
    struct TestView: View {
        @State var first: UIImagePickerController.SourceType? = nil
        @State var second = false
        @State var third = false

        var body: some View {
            VStack {
                Button("first") { first = .photoLibrary }
                Button("second") { second = true }
                Button("third") { third = true }
            }
            .imagePicker($first) { _ in }
            .imagePicker($second) { _ in }
            .sheet(isPresented: $third) {
                ImagePickerView(sourceType: .photoLibrary) { _ in
                }
            }
        }
    }

    @State static var first: UIImagePickerController.SourceType? = nil
    @State static var second = false

    static var previews: some View {
        TestView()
    }
}
