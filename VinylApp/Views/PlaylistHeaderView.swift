import UIKit

protocol PlaylistHeaderViewDelegate: AnyObject {
    func playButtonTapped()
}

class PlaylistHeaderView: UIView {
    
    weak var delegate: PlaylistHeaderViewDelegate?
    
    private let playlistImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // Set your playlist image here
        imageView.image = UIImage(named: "your_playlist_image")
        return imageView
    }()
    
    private let transparentOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.6) // Adjust transparency as needed
        view.layer.cornerRadius = 20 // Rounded corners
        view.clipsToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black // Set text color
        // Set playlist title text here
        label.text = "Your Playlist Title"
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .white // Set play button color
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with viewModel: PlaylistHeaderViewViewModel) {
        // Load data from viewModel and set up the header view
        titleLabel.text = viewModel.name
        // You can similarly set other properties using the viewModel data
        // Example: playlistImageView.image = viewModel.artworkImage
        
        // Ensure to handle cases where the viewModel data might be nil
    }
    
    private func setupViews() {
        addSubview(playlistImageView)
        addSubview(transparentOverlay)
        transparentOverlay.addSubview(titleLabel)
        transparentOverlay.addSubview(playButton)
        
        // Add constraints for playlist image view
        playlistImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playlistImageView.topAnchor.constraint(equalTo: topAnchor),
            playlistImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playlistImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playlistImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5) // Top half of the screen
        ])
        
        // Add constraints for transparent overlay
        transparentOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            transparentOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            transparentOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            transparentOverlay.bottomAnchor.constraint(equalTo: playlistImageView.bottomAnchor),
            transparentOverlay.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.4) // 40% of the screen height
        ])
        
        // Add constraints for title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: transparentOverlay.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: transparentOverlay.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: transparentOverlay.trailingAnchor, constant: -20)
        ])
        
        // Add constraints for play button
        playButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: transparentOverlay.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: transparentOverlay.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func playButtonTapped() {
        delegate?.playButtonTapped()
    }
}
