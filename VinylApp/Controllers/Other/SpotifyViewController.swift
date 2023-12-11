import UIKit

class SpotifyViewController: UIViewController {
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to Soundtrak!"
        label.textAlignment = .center
        label.textColor = .black
        if let customFont = UIFont(name: "Outfit-Bold", size: 30) {
            label.font = customFont
        } else {
            label.font = UIFont.boldSystemFont(ofSize: 30)
        }
        return label
    }()
    
    private let signInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitle("Log in with Spotify", for: .normal)
        button.setTitleColor(.black, for: .normal)
        if let customFont = UIFont(name: "ZillaSlab-Light", size: 20) {
            button.titleLabel?.font = customFont
        } else {
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        }
        return button
    }()
    
    private let topImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "spotify_image")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 239.0/255.0, green: 235.0/255.0, blue: 226.0/255.0, alpha: 1.0)
        
        view.addSubview(topImageView)
        view.addSubview(welcomeLabel) // Add the welcome label
        view.addSubview(signInButton)
        
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        
        // Make the button corners rounded
        signInButton.layer.cornerRadius = 20
        signInButton.layer.masksToBounds = true
        
        signInButton.layer.shadowRadius = 5
        signInButton.layer.shadowOpacity = 0.5
        signInButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        signInButton.layer.shadowColor =  UIColor.gray.cgColor
        signInButton.layer.masksToBounds = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let imageSize: CGFloat = view.height * 0.4
        topImageView.frame = CGRect(
            x: 0,
            y: view.safeAreaInsets.top,
            width: view.width,
            height: imageSize
        )
        
        welcomeLabel.frame = CGRect(
            x: 20,
            y: topImageView.frame.maxY + 20,
            width: view.width - 40,
            height: 40
        )
        
        signInButton.frame = CGRect(
            x: (view.bounds.width - 200) / 2,
            y: welcomeLabel.frame.maxY + 60, // button height
            width: 200,
            height: 40
        )
    }
    
    @objc func didTapSignIn() {
        let vc = AuthViewController()
        vc.completionHandler = {[weak self] success in
            DispatchQueue.main.async {
                self?.handleSignIn(success: success)
            }
        }
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func handleSignIn(success: Bool) {
        // Log user in
        guard success else {
            let alert = UIAlertController(title: "Oops", message: "Something went wrong when signing in", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alert, animated: true)
            return
        }
        
        let mainAppUploadController = TabBarViewController()
        mainAppUploadController.modalPresentationStyle = .fullScreen
        present(mainAppUploadController, animated: true)
    }
}
