//
//  OTPFieldView.swift
//  OTPFieldView
//
//  Created by Vaibhav Bhasin on 10/09/19.
//  Copyright © 2019 Vaibhav Bhasin. All rights reserved.
//



import UIKit

@objc public protocol OTPFieldViewDelegate: class {
    
    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool
    func enteredOTP(otp: String)
    func hasEnteredAllOTP(hasEnteredAll: Bool) -> Bool
}



@objc public enum KeyboardType: Int {
    case numeric
    case alphabet
    case alphaNumeric
}

@objc public class OTPFieldView: UIStackView {
    
    public var fieldsCount: Int = 4
    public var otpInputType: KeyboardType = .numeric
    public var fieldFont: UIFont = UIFont.systemFont(ofSize: 20)
    public var secureEntry: Bool = false
    public var hideEnteredText: Bool = false
    public var requireCursor: Bool = true
    public var cursorColor: UIColor = UIColor.blue
    public var fieldBorderWidth: CGFloat = 1
    public var shouldAllowIntermediateEditing: Bool = true
    
    public weak var delegate: OTPFieldViewDelegate?
    fileprivate var secureEntryData = [String]()
    
    //MARK:- Configuration Methods
    public func initializeUI() {
        initializeOTPFields()
        self.distribution = .fillEqually
        self.spacing = 8.0
        self.axis = .horizontal
        (viewWithTag(1) as? OTPTextField)?.becomeFirstResponder()
    }
    
    fileprivate func initializeOTPFields() {
        secureEntryData.removeAll()
        
        for index in stride(from: 0, to: fieldsCount, by: 1) {
            let oldOtpField = viewWithTag(index + 1) as? NSTextField
            oldOtpField?.removeFromSuperview()
            
            let otpField = getOTPField(forIndex: index)
            addArrangedSubview(otpField)
            secureEntryData.append("")
        }
    }
    

    fileprivate func getOTPField(forIndex index: Int) -> OTPTextField {
      

        let otpField = OTPTextField()
        otpField.delegate = self
        otpField.tag = index + 1
        otpField.font = fieldFont
        otpField.autocorrectionType = .no
        otpField.textAlignment = .center
        if #available(iOS 12.0, *) {
            otpField.textContentType = .oneTimeCode
        }
        // Set input type for OTP fields
        switch otpInputType {
        case .numeric:
            otpField.keyboardType = .numberPad
        case .alphabet:
            otpField.keyboardType = .alphabet
        case .alphaNumeric:
            otpField.keyboardType = .namePhonePad
        }
        
        if requireCursor {
            otpField.tintColor = cursorColor
        }
        else {
            otpField.tintColor = UIColor.clear
        }
        
        
        return otpField
    }
    

    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        for view in self.arrangedSubviews {
            addUnderlineTo(view)
        }
    }
    
    //MARK:- Custom Implementations
    
    func addUnderlineTo(_ view: UIView ) {
        
        let underlineLayer = CALayer()
        underlineLayer.backgroundColor = UIColor.primaryColor?.cgColor
        underlineLayer.frame = CGRect(x: 0.0, y: Double(view.frame.size.height) - Double(fieldBorderWidth), width: Double(view.frame.size.width), height: Double(fieldBorderWidth))
        view.layer.addSublayer(underlineLayer)
    }
    
    fileprivate func isPreviousFieldsEntered(forTextField textField: UITextField) -> Bool {
        var isTextFilled = true
        var nextOTPField: UITextField?
        
        // If intermediate editing is not allowed, then check for last filled field in forward direction.
        if !shouldAllowIntermediateEditing {
            for index in stride(from: 1, to: fieldsCount + 1, by: 1) {
                let tempNextOTPField = viewWithTag(index) as? UITextField
                
                if let tempNextOTPFieldText = tempNextOTPField?.text, tempNextOTPFieldText.isEmpty {
                    nextOTPField = tempNextOTPField
                    break
                }
            }
            
            if let nextOTPField = nextOTPField {
                isTextFilled = (nextOTPField == textField || (textField.tag) == (nextOTPField.tag - 1))
            }
        }
        
        return isTextFilled
    }
    
    // Helper function to get the OTP String entered
    fileprivate func calculateEnteredOTPSTring(isDeleted: Bool) {
        if isDeleted {
            _ = delegate?.hasEnteredAllOTP(hasEnteredAll: false)
            
            // Set the default enteres state for otp entry
            for index in stride(from: 0, to: fieldsCount, by: 1) {
                var otpField = viewWithTag(index + 1) as? OTPTextField
                
                if otpField == nil {
                    otpField = getOTPField(forIndex: index)
                }
            }
        }
        else {
            var enteredOTPString = ""
            
            // Check for entered OTP
            for index in stride(from: 0, to: secureEntryData.count, by: 1) {
                if !secureEntryData[index].isEmpty {
                    enteredOTPString.append(secureEntryData[index])
                }
            }
            
            if enteredOTPString.count == fieldsCount {
                delegate?.enteredOTP(otp: enteredOTPString)
                
                
                // Set the error state for invalid otp entry
                for index in stride(from: 0, to: fieldsCount, by: 1) {
                    var otpField = viewWithTag(index + 1) as? OTPTextField
                    
                    if otpField == nil {
                        otpField = getOTPField(forIndex: index)
                    }
                }
            }
        }
    }
    
}

//MARK:- UITextFieldDelegate Methods
extension OTPFieldView: UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let shouldBeginEditing = delegate?.shouldBecomeFirstResponderForOTP(otpTextFieldIndex: (textField.tag - 1)) ?? true
        if shouldBeginEditing {
            return isPreviousFieldsEntered(forTextField: textField)
        }
        
        return shouldBeginEditing
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let replacedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
        
        // Check since only alphabet keyboard is not available in iOS
        if !replacedText.isEmpty && otpInputType == .alphabet && replacedText.rangeOfCharacter(from: .letters) == nil {
            return false
        }
        
        if replacedText.count >= 1 {
            // If field has a text already, then replace the text and move to next field if present
            secureEntryData[textField.tag - 1] = string
            
            if hideEnteredText {
                textField.text = " "
            }
            else {
                if secureEntry {
                    textField.text = "•"
                }
                else {
                    textField.text = string
                }
            }
            
            
            let nextOTPField = viewWithTag(textField.tag + 1)
            
            if let nextOTPField = nextOTPField {
                nextOTPField.becomeFirstResponder()
            }
            else {
                textField.resignFirstResponder()
            }
            
            // Get the entered string
            calculateEnteredOTPSTring(isDeleted: false)
        }
        else {
            let currentText = textField.text ?? ""
            
            if textField.tag > 1 && currentText.isEmpty {
                if let prevOTPField = viewWithTag(textField.tag - 1) as? UITextField {
                    deleteText(in: prevOTPField)
                }
            } else {
                deleteText(in: textField)
                
                if textField.tag > 1 {
                    if let prevOTPField = viewWithTag(textField.tag - 1) as? UITextField {
                        prevOTPField.becomeFirstResponder()
                    }
                }
            }
        }
        
        return false
    }
    
    private func deleteText(in textField: UITextField) {
        // If deleting the text, then move to previous text field if present
        secureEntryData[textField.tag - 1] = ""
        textField.text = ""
        
        
        textField.becomeFirstResponder()
        
        // Get the entered string
        calculateEnteredOTPSTring(isDeleted: true)
    }
}
