//
//  BTTableViewCell.swift
//  test121
//
//  Created by Jake Lin on 2017/4/6.
//  Copyright © 2017年 AIC NEXCOM. All rights reserved.
//

import UIKit

class BTTableViewCell: UITableViewCell {

    
    
    @IBOutlet weak var BTdeviceLabel: UILabel!
    
    @IBOutlet weak var BTidLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
