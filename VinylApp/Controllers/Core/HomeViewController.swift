import UIKit

class HomeViewController: UIViewController {
    
    private var playlists: [Playlist] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Create a flexible space item to add space before the title label
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Create a custom label for "Soundtrak"
        let titleLabel = UILabel()
        titleLabel.text = "Soundtrak"
        titleLabel.textColor = UIColor(red: 11/255, green: 0, blue: 20/255, alpha: 1)
        if let customFont = UIFont(name: "Outfit-Bold", size: 24) {
            titleLabel.font = customFont
        } else {
            titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        }
        titleLabel.sizeToFit()

        let titleItem = UIBarButtonItem(customView: titleLabel)
        
        // Adding flexible space before and after the title label to adjust its position
        navigationItem.leftBarButtonItems = [flexibleSpace, titleItem, flexibleSpace]

        view.backgroundColor = .systemBackground
        
        // Change the color of the gear image
        let gearImage = UIImage(systemName: "gear")?.withTintColor(UIColor(red: 11/255, green: 0, blue: 20/255, alpha: 1), renderingMode: .alwaysOriginal)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: gearImage,
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(didTapSettings))
    }
    
    @objc func didTapSettings() {
        let vc = SettingsViewController()
        vc.title = "Settings"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}
