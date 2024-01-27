import SwiftUI

class TabBarViewController: UITabBarController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    var uploadButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.tintColor = AppColors.jellybeanBlue

        let vc3 = UIHostingController(rootView: LibraryView(tabBarViewController: self))

        let nav3 = UINavigationController(rootViewController: vc3)

        self.viewControllers = [nav3]

        if let items = self.tabBar.items {
            for item in items {
                item.isEnabled = false
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showUploadButton()
    }
    
    func showUploadButton() {
        uploadButton = UIButton(type: .custom)
        uploadButton.setImage(UIImage(systemName: "plus"), for: .normal)
        uploadButton.backgroundColor = AppColors.vampireBlack
        uploadButton.tintColor = .white
        uploadButton.layer.cornerRadius = 30
        uploadButton.layer.shadowColor = UIColor.black.cgColor
        uploadButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        uploadButton.layer.shadowOpacity = 0.3
        uploadButton.layer.shadowRadius = 4
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)

        var buttonFrame = uploadButton.frame
        buttonFrame.size = CGSize(width: 60, height: 60)
        uploadButton.frame = buttonFrame

        var center = self.tabBar.center
        center.y -= 40
        uploadButton.center = center

        self.view.addSubview(uploadButton)
    }
    
    func hideUploadButton() {
        uploadButton?.isHidden = true
        tabBar.isHidden = true
    }

    func unhideUploadButton() {
        uploadButton?.isHidden = false
        tabBar.isHidden = false
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
            
            if let navController = selectedViewController as? UINavigationController {
                self.hideUploadButton()
                let uploadView = UploadView(im: selectedImage) { playlist in
                    DispatchQueue.main.async {
                        navController.popViewController(animated: true) // Pop the current view controller
                        self.hideUploadButton() // Hide the button when transitioning to Playlist2VC
                        let hostingController = UIHostingController(rootView: Playlist2VC(playlist: playlist, userID: UserDefaults.standard.value(forKey: "user_id") as! String, tabBarViewController: self))
                        navController.navigationBar.tintColor = UIColor.black
                        navController.pushViewController(hostingController, animated: false)
                        navController.isNavigationBarHidden = false
                    }
                }
                let uploadVC = UIHostingController(rootView: uploadView)
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
            Text("Aurify")
                .font(.custom("Outfit-Bold", size: 24))
                .foregroundColor(Color(AppColors.vampireBlack))
                .padding(.leading, 16)
                .padding(.top, -35)
            Spacer()
        }
    }
}
