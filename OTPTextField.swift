//
//  OTPTextField.swift
//  OTPFieldView
//
//  Created by Vaibhav Bhasin on 10/09/19.
//  Copyright © 2019 Vaibhav Bhasin. All rights reserved.
//



import UIKit


@objc class OTPTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func deleteBackward() {
        super.deleteBackward()
        _ = delegate?.textField?(self, shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: "")
    }
}
