import SwiftUI

class TabBarViewController: UITabBarController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.tintColor = AppColors.jellybeanBlue

        let vc2 = UploadViewController()
        let vc3 = UIHostingController(rootView: LibraryView())

        let nav2 = UINavigationController(rootViewController: vc2)
        let nav3 = UINavigationController(rootViewController: vc3)

        self.viewControllers = [nav3] // Set LibraryView as the main view

        // Customize tabBar appearance
        tabBar.isHidden = true // Hide the tabBar
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let uploadButton = UIButton(type: .custom)
        uploadButton.setImage(UIImage(systemName: "plus"), for: .normal)
        uploadButton.backgroundColor = AppColors.vampireBlack
        uploadButton.tintColor = .white
        uploadButton.layer.cornerRadius = 30
        //uploadButton.layer.shadowColor = UIColor.black.cgColor
        uploadButton.layer.shadowColor = UIColor.white.cgColor
        uploadButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        uploadButton.layer.shadowOpacity = 0.8
        uploadButton.layer.shadowRadius = 6
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)

        var buttonFrame = uploadButton.frame
        buttonFrame.size = CGSize(width: 60, height: 60)
        uploadButton.frame = buttonFrame

        // Position the uploadButton at the bottom center
        uploadButton.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height - 60)
        
        self.view.addSubview(uploadButton)
    }

    @objc func uploadButtonTapped() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true // Enable image editing
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            let uploadVC = UploadViewController()
            uploadVC.selectedImage = selectedImage
            
            if let navController = selectedViewController as? UINavigationController {
                navController.pushViewController(uploadVC, animated: false)
            }
        }
    }

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

struct CustomTitleView: View {
    var body: some View {
        HStack {
            Text("Soundtrak")
                .font(.custom("Outfit-Bold", size: 24))
                .foregroundColor(Color(AppColors.vampireBlack))
                .padding(.leading, 16)
                .padding(.top, -35)
            Spacer()
        }
    }
}


