//
//  HomeViewController.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import UIKit

class HomeViewController: UIViewController {
    
    private var playlists: [Playlist] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"),
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
