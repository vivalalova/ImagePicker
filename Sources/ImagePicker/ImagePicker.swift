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

        @State var image: Image?

        var body: some View {
            ZStack {
                image?
                    .resizable()
                    .blur(radius: 12)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Button("First") { first = .photoLibrary }
                    Button("Second") { second = true }
                    Button("Third") { third = true }
                }
                .padding()
                .background(Color.white)
                .font(.title.bold())
            }
            .imagePicker($first) { image = $0.image }
            .imagePicker($second) { image = $0.image }
            .sheet(isPresented: $third) {
                ImagePickerView(sourceType: .photoLibrary) { image = $0.image }
            }
        }
    }

    static var previews: some View {
        TestView()
    }
}
