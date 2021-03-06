//
//  BlendedNavigationBar.swift
//  VergeiOS
//
//  Created by Swen van Zanten on 05-08-18.
//  Copyright © 2018 Verge Currency. All rights reserved.
//

import UIKit

class BlendedNavigationBar: UINavigationBar {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        DispatchQueue.main.async {
            self.setupLayout()
        }
    }
    
    func setupLayout() {
        self.setColors()

        self.setValue(true, forKey: "hidesShadow")
    }

    func setColors() {
        let font = UIFont.avenir(size: 19).medium()
        
        self.shadowImage = UIImage()
        self.tintColor = ThemeManager.shared.primaryLight()
        self.barTintColor = ThemeManager.shared.backgroundGrey()
        self.backgroundColor = ThemeManager.shared.backgroundGrey()
        self.barStyle = ThemeManager.shared.barStyle()
        self.isTranslucent = false
        self.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: ThemeManager.shared.secondaryDark(),
            kCTFontAttributeName: font
        ] as? [NSAttributedString.Key : Any]
    }
    
}
