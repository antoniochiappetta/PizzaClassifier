//
//  CIImagePropertyOrientation.swift
//  PizzaClassifier
//
//  Created by Antonio Chiappetta on 07/02/2020.
//  Copyright © 2020 Antonio Chiappetta. All rights reserved.
//

import UIKit

extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    default: self = .up
    }
  }
}

extension CGImagePropertyOrientation {
  init(_ orientation: UIDeviceOrientation) {
    switch orientation {
    case .portraitUpsideDown: self = .left
    case .landscapeLeft: self = .up
    case .landscapeRight: self = .down
    default: self = .right
    }
  }
}
