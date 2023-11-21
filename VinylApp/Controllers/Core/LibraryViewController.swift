//
//  SearchViewController.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/22/23.
//

import UIKit

class LibraryViewController: UIViewController {
    
    var playlists = [Playlist]()
    
    private let noPlaylistsView = ActionLabelView()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(PlaylistCollectionViewCell.self, forCellWithReuseIdentifier: PlaylistCollectionViewCell.identifier)
        return collectionView
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: (view.bounds.width - 4) / 3, height: (view.bounds.width - 4) / 3)
        layout.minimumInteritemSpacing = 2 // columns
        layout.minimumLineSpacing = 2 //rows
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        view.addSubview(collectionView)
        view.addSubview(noPlaylistsView)
        
        noPlaylistsView.configure(with: ActionLabelViewViewModel(text: "You Don't Have Any Playlists Yet", actionTitle: "Create"))
        
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData() // Fetch data whenever the view is about to appear
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        noPlaylistsView.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        noPlaylistsView.center = view.center
    }
    
    private func fetchData() {
        APICaller.shared.getCurrentUserPlaylists { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let playlists):
                    self?.playlists = playlists
                    self?.updateUI()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func updateUI() {
        if playlists.isEmpty {
            //show label
            noPlaylistsView.isHidden = false
            collectionView.isHidden = true
        } else {
            //show table
            noPlaylistsView.isHidden = true
            collectionView.isHidden = false
            collectionView.reloadData()
        }
    }
}

extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playlists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaylistCollectionViewCell.identifier, for: indexPath) as! PlaylistCollectionViewCell
        let playlist = playlists[indexPath.row]
        cell.configure(with: playlist)
        return cell
    }
}


extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        // Get the selected playlist
        let selectedPlaylist = playlists[indexPath.row]
        
        // Create a PlaylistViewController instance with the selected playlist
        let playlistVC = PlaylistViewController(playlist: selectedPlaylist)
        
        // Push the PlaylistViewController onto the navigation stack
        navigationController?.pushViewController(playlistVC, animated: true)
    }
}
