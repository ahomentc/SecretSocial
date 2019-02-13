//
//  ChannelsTableViewCell.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 2/1/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import UIKit

class ChannelsTableViewCell: UITableViewCell {

    @IBOutlet weak var channelName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
