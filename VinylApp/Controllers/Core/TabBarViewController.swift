
class TabBarViewController: UITabBarController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.tintColor = UIColor(red: 67/255, green: 128/255, blue: 159/255, alpha: 1.0)

        let vc1 = HomeViewController()
        let vc2 = UploadViewController()
        let vc3 = LibraryViewController()

        vc3.title = "Library"

        vc1.navigationItem.largeTitleDisplayMode = .always
        vc2.navigationItem.largeTitleDisplayMode = .always
        vc3.navigationItem.largeTitleDisplayMode = .always

        let nav1 = UINavigationController(rootViewController: vc1)
        let nav2 = UINavigationController(rootViewController: vc2)
        let nav3 = UINavigationController(rootViewController: vc3)

        nav1.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 1)
        nav3.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "music.note.list"), tag: 2)
        
        self.viewControllers = [nav1, nav2, nav3]
        
        tabBar.layer.shadowColor = AppColors.vampireBlack.cgColor
        tabBar.layer.shadowOpacity = 0.5
        tabBar.layer.shadowOffset = CGSize.zero
        tabBar.layer.shadowRadius = 5
        self.tabBar.layer.borderColor = UIColor.clear.cgColor
        self.tabBar.layer.borderWidth = 0
        self.tabBar.clipsToBounds = false
        self.tabBar.backgroundColor = UIColor.white
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let uploadButton = UIButton(type: .custom)
        uploadButton.setImage(UIImage(systemName: "plus"), for: .normal)
        uploadButton.backgroundColor = AppColors.vampireBlack
        uploadButton.tintColor = .white // plus symbol color
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

