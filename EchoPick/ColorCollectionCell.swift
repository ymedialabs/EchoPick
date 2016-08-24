//
//  ColorCollectionCell.swift
//  EchoPick
//
//  Created by Prianka Liz Kariat on 8/24/16.
//  Copyright © 2016 Prianka Liz Kariat. All rights reserved.
//

import UIKit

class ColorCollectionCell: UICollectionViewCell {
  
  var delegate: FilterCollectionCellDelegate?
  
  @IBOutlet weak var colorView: UIView!
  
  @IBAction func onClickCloseButton(_ sender: AnyObject) {
    
    delegate?.closeButtonClickedOnCell(collectionCell: self)
  }
  
  override func draw(_ rect: CGRect) {
    
    layer.borderColor = UIColor.white().cgColor
    layer.borderWidth = 1.0
  }

}
