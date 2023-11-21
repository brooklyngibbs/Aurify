//
//  ActionLabelView.swift
//  VinylApp
//
//  Created by Brooklyn Gibbs on 10/23/23.
//

import UIKit

struct ActionLabelViewViewModel {
    let text: String
    let actionTitle: String
}

class ActionLabelView: UIView {
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        clipsToBounds = true
        addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 0, y: 0, width: width, height: height-45)
    }
    
    func configure(with viewModel: ActionLabelViewViewModel){
        label.text = viewModel.text
    }

}
