//
//  MyPlantTableViewCell.swift
//  E-Plant
//
//  Created by 郁雨润 on 1/11/17.
//  Copyright © 2017 Monash University. All rights reserved.
//

import UIKit

class MyPlantTableViewCell: UITableViewCell {
    
   
    @IBOutlet weak var plantImage: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    
    @IBOutlet weak var conditionLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
