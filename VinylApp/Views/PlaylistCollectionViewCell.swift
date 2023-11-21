import UIKit

class PlaylistCollectionViewCell: UICollectionViewCell {
    static let identifier = "PlaylistCollectionViewCell"
    
    private let playlistImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let playlistNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(playlistImageView)
        contentView.addSubview(playlistNameLabel)
        
        // Configure the layout of the subviews
        playlistImageView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.width)
        playlistNameLabel.frame = CGRect(x: 0, y: contentView.bounds.width, width: contentView.bounds.width, height: contentView.bounds.height - contentView.bounds.width)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with playlist: Playlist) {
        // Set the playlist image and name
        if let imageUrlString = playlist.images.first?.url, let imageUrl = URL(string: imageUrlString) {
            playlistImageView.sd_setImage(with: imageUrl, completed: nil)
        } else {
            // Use a default image if the playlist doesn't have an image
            playlistImageView.image = UIImage(systemName: "questionmark")
            playlistImageView.contentMode = .scaleAspectFit
            playlistImageView.tintColor = .secondaryLabel
            playlistImageView.backgroundColor = .secondarySystemBackground
        }
    }
}
