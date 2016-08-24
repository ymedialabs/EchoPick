//
//  ProductCollectionCell.swift
//  EchoPick
//
//  Created by Prianka Liz Kariat on 8/18/16.
//  Copyright © 2016 Prianka Liz Kariat. All rights reserved.
//

import UIKit

class ProductCollectionCell: UICollectionViewCell {
    
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var fitName: UILabel!
  @IBOutlet weak var productName: UILabel!
  
  @IBOutlet weak var backView: UIView!
  @IBOutlet weak var productImage: UIImageView!
  
  override func draw(_ rect: CGRect) {
    
    let shadowPath = UIBezierPath(rect: self.backView.bounds)
    
    self.backView.layer.shadowPath = shadowPath.cgPath
    self.backView.layer.shadowColor = UIColor(white: 0.0, alpha: 0.16).cgColor
    self.backView.layer.shadowOffset = CGSize(width: 0.0, height: 10.0)
    self.backView.layer.shadowRadius = 10.0
    self.backView.layer.shadowOpacity = 1.0
    self.backView.layer.shouldRasterize = true
    self.backView.layer.rasterizationScale = UIScreen.main().scale
  }
  
}
