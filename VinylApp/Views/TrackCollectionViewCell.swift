//
//  CollectionViewCell.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import UIKit

class TrackCollectionViewCell: UICollectionViewCell {
    static let identifier = "TrackCollectionViewCell"
    
    private let albumCoverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let trackNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 18, weight: .regular)
        return label
    }()
    
    private let artistNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 15, weight: .thin)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(albumCoverImageView)
        //contentView.addSubview(artistNameLabel)
        contentView.clipsToBounds = true
        
        trackNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trackNameLabel)
        setupConstraints()
        
        NSLayoutConstraint.activate([
            trackNameLabel.leadingAnchor.constraint(equalTo: albumCoverImageView.trailingAnchor, constant: 10),
            trackNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            trackNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),
            trackNameLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5)
        ])

        trackNameLabel.lineBreakMode = .byTruncatingTail // Enable text truncation

        // Add constraints for artistNameLabel
        artistNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(artistNameLabel)
        
        NSLayoutConstraint.activate([
            artistNameLabel.leadingAnchor.constraint(equalTo: albumCoverImageView.trailingAnchor, constant: 10),
            artistNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            artistNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),
            artistNameLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5)
        ])

        artistNameLabel.lineBreakMode = .byTruncatingTail
    }
    
    private func setupConstraints() {
        contentView.addSubview(albumCoverImageView)
        contentView.addSubview(trackNameLabel)
        contentView.addSubview(artistNameLabel)

        // Set up constraints for albumCoverImageView
        albumCoverImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumCoverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            albumCoverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            albumCoverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            albumCoverImageView.widthAnchor.constraint(equalTo: albumCoverImageView.heightAnchor)
        ])

        // Set up constraints for trackNameLabel
        trackNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trackNameLabel.leadingAnchor.constraint(equalTo: albumCoverImageView.trailingAnchor, constant: 10),
            trackNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            trackNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),
            trackNameLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5)
        ])
        trackNameLabel.lineBreakMode = .byTruncatingTail

        // Set up constraints for artistNameLabel
        artistNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artistNameLabel.leadingAnchor.constraint(equalTo: albumCoverImageView.trailingAnchor, constant: 10),
            artistNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            artistNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),
            artistNameLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5)
        ])
        artistNameLabel.lineBreakMode = .byTruncatingTail
    }

    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        albumCoverImageView.frame = CGRect(
            x: 5,
            y: 2,
            width: contentView.height-4,
            height: contentView.height-4
        )
        trackNameLabel.frame = CGRect(
            x: albumCoverImageView.right + 120,
            y: 0,
            width: contentView.width-albumCoverImageView.right-15,
            height: contentView.height / 2
        )
        artistNameLabel.frame = CGRect(
            x: albumCoverImageView.right + 120,
            y: contentView.height / 2,
            width: contentView.width-albumCoverImageView.right-15,
            height: contentView.height / 2
        )

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        trackNameLabel.text = nil
        albumCoverImageView.image = nil
        artistNameLabel.text = nil
    }
    
    func configure(with viewModel: RecommendedTrackCellViewModel) {
        trackNameLabel.text = viewModel.name
        albumCoverImageView.sd_setImage(with: viewModel.artworkURL, completed: nil)
        artistNameLabel.text = viewModel.artistName
    }
}
