import UIKit
import SDWebImage

protocol PlaylistHeaderCollectionReusableViewDelegate: AnyObject {
    func playlistHeaderCollectionReusableViewDidTapPlayAll(_ header: PlaylistHeaderCollectionReusableView)
}

final class PlaylistHeaderCollectionReusableView: UICollectionReusableView {
    
    static let identifier = "PlaylistHeaderCollectionReusableView"
    
    weak var delegate: PlaylistHeaderCollectionReusableViewDelegate?
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail 
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "photo")
        return imageView
    }()
    
    private let playAllButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGreen
        let image = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .regular))
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 30
        button.layer.masksToBounds = true
        return button
    }()
    
    private var descriptionWidthConstraint: NSLayoutConstraint? // Declare a variable to hold the width constraint
    
    //MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubview(imageView)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        addSubview(playAllButton)
        playAllButton.addTarget(self, action: #selector(didTapPlayAll), for: .touchUpInside)
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.rightAnchor.constraint(equalTo: playAllButton.leftAnchor, constant: -20).isActive = true
        
        // Set up the width constraint for the description label
        descriptionWidthConstraint = descriptionLabel.widthAnchor.constraint(equalToConstant: 0)
        descriptionWidthConstraint?.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc private func didTapPlayAll() {
        delegate?.playlistHeaderCollectionReusableViewDidTapPlayAll(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let imageSize: CGFloat = height / 1.8
        imageView.frame = CGRect(x: (width - imageSize) / 2, y: 20, width: imageSize, height: imageSize)

        nameLabel.frame = CGRect(x: 10, y: imageView.bottom + 10, width: width - 20, height: 44)
        
        // Adjust the width constraint for the description label based on the available width
        descriptionWidthConstraint?.constant = width - 20 - (playAllButton.frame.width + 10)
        descriptionLabel.frame = CGRect(x: 10, y: nameLabel.bottom + 5, width: descriptionWidthConstraint?.constant ?? 0, height: 44)

        playAllButton.frame = CGRect(x: width - 80, y: height - 80, width: 60, height: 60)
    }
    
    func configure(with viewModel: PlaylistHeaderViewViewModel) {
        nameLabel.text = viewModel.name
        descriptionLabel.text = viewModel.description
        imageView.sd_setImage(with: viewModel.artworkURL, completed: nil)
    }
        
}
