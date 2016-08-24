//
//  FilterCollectionCell.swift
//  EchoPick
//
//  Created by Prianka Liz Kariat on 8/19/16.
//  Copyright © 2016 Prianka Liz Kariat. All rights reserved.
//

import UIKit

protocol FilterCollectionCellDelegate {
  
  func closeButtonClickedOnCell(collectionCell: UICollectionViewCell)
}

class FilterCollectionCell: UICollectionViewCell {
  
  var delegate: FilterCollectionCellDelegate?
    
  @IBOutlet weak var filterLabel: UILabel!
  
  
  @IBAction func onClickCloseButton(_ sender: AnyObject) {
    
    delegate?.closeButtonClickedOnCell(collectionCell: self)
  }
  
  override func draw(_ rect: CGRect) {
    
    layer.borderColor = UIColor.white().cgColor
    layer.borderWidth = 1.0
  }
}
