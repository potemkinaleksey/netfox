//
//  NFXRawBodyDetailsController.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

class NFXRawBodyDetailsController: NFXGenericBodyDetailsController, UISearchBarDelegate
{
    var bodyView: UITextView = UITextView()
    private var originalString: String?
    private var copyAlert: UIAlertController?
    private var timer: Timer?
    private let nextButton = UIButton(type: .system)
    private let prevButton = UIButton(type: .system)
    private var currentResult: Int = 0 {
        didSet {
            if searchResults.count == 0 {
                barItem.title = ""
            } else {
                barItem.title = "\(currentResult + 1) из \(searchResults.count)"
            }
            
        }
    }
    private let barItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

    private var searchResults: [NSTextCheckingResult] = []
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "Body details"
        
        let searchBar = UISearchBar()
        searchBar.backgroundImage = UIImage()
        searchBar.placeholder = "Поиск"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.backgroundColor = .clear
        self.view.addSubview(searchBar)
        
        nextButton.setImage(UIImage(data: NFXAssets.getImage(.rightArrow)) , for: .normal)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.isEnabled = false
        nextButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        nextButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(nextButton)
        
        prevButton.setImage(UIImage(data: NFXAssets.getImage(.leftArrow)) , for: .normal)
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        prevButton.isEnabled = false
        prevButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        prevButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(prevButton)
        
        self.bodyView.translatesAutoresizingMaskIntoConstraints = false
        self.bodyView.backgroundColor = UIColor.clear
        self.bodyView.textColor = UIColor.NFXGray44Color()
		self.bodyView.textAlignment = .left
        self.bodyView.isEditable = false
        self.bodyView.isSelectable = false
        self.bodyView.font = UIFont.NFXFont(size: 13)
        self.bodyView.keyboardDismissMode = .onDrag
        self.view.addSubview(self.bodyView)
        
        navigationItem.rightBarButtonItem = barItem

        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.topAnchor.constraint(equalTo: view.topAnchor),
            searchBar.trailingAnchor.constraint(equalTo: prevButton.leadingAnchor),
            
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            nextButton.heightAnchor.constraint(equalTo: searchBar.heightAnchor, multiplier: 0.7),
            nextButton.widthAnchor.constraint(equalTo: nextButton.heightAnchor),
            
            prevButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor),
            prevButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            prevButton.heightAnchor.constraint(equalTo: nextButton.heightAnchor),
            prevButton.widthAnchor.constraint(equalTo: prevButton.heightAnchor),
            
            self.bodyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.bodyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.bodyView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            self.bodyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(NFXRawBodyDetailsController.copyLabel))
        self.bodyView.addGestureRecognizer(lpgr)
        
        switch bodyType {
            case .request:
                self.originalString = self.selectedModel.getRequestBody() as String
            default:
                self.originalString = self.selectedModel.getResponseBody() as String
        }
        self.bodyView.text = originalString
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        keyboarbUpdates(notification: notification)
    }
    
    @objc private func keyboardWillChange(notification: NSNotification) {
        keyboarbUpdates(notification: notification)
    }
    
    private func keyboarbUpdates(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
            else {
                return
        }
        let padding = paddingForFrame(keyboardEndFrame)
        let options = UIView.AnimationOptions(rawValue: (animationCurve as UInt) << 16)
        bodyView.contentInset.bottom = padding
    }

    
    private func paddingForFrame(_ frame: CGRect) -> CGFloat {
        let endYPosition = frame.origin.y
        let keyboardHeight = frame.height
        let windowHeight = UIApplication.shared.keyWindow!.frame.height
        let padding = endYPosition >= windowHeight ? 0.0 : keyboardHeight
        
        return padding
    }

    @objc fileprivate func copyLabel(lpgr: UILongPressGestureRecognizer) {
        guard let text = (lpgr.view as? UITextView)?.text,
              copyAlert == nil else { return }

        UIPasteboard.general.string = text

        let alert = UIAlertController(title: "Text Copied!", message: nil, preferredStyle: .alert)
        copyAlert = alert

        self.present(alert, animated: true) { [weak self] in
            guard let `self` = self else { return }

            Timer.scheduledTimer(timeInterval: 0.45,
                                 target: self,
                                 selector: #selector(NFXRawBodyDetailsController.dismissCopyAlert),
                                 userInfo: nil,
                                 repeats: false)
        }
    }

    @objc fileprivate func dismissCopyAlert() {
        copyAlert?.dismiss(animated: true) { [weak self] in self?.copyAlert = nil }
    }
    
    @objc fileprivate func nextTapped() {
        guard currentResult < searchResults.count - 1 else {
            nextButton.isEnabled = false
            return
        }
        
        prevButton.isEnabled = true
        
        currentResult += 1
        let result = searchResults[currentResult]
        scrollTo(result: result)
                
        if currentResult == searchResults.count - 1 {
            nextButton.isEnabled = false
        }
    }
    
    @objc fileprivate func prevTapped() {
        guard currentResult > 0 else {
            prevButton.isEnabled = false
            return
        }
        
        nextButton.isEnabled = true
        
        currentResult -= 1
        let result = searchResults[currentResult]
        scrollTo(result: result)

        if currentResult == 0 {
            prevButton.isEnabled = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let original = originalString else {
            return
        }
        
        timer?.invalidate()
        
        let attributed = NSMutableAttributedString(string: original, attributes: [
            .foregroundColor: UIColor.NFXGray44Color(),
            .font: UIFont.NFXFont(size: 13)
        ])
        
        guard let regex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive) else {
            bodyView.attributedText = attributed
            prevButton.isEnabled = false
            nextButton.isEnabled = false
            searchResults = []
            currentResult = 0
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] t in
            guard let self = self else { return }
            self.searchResults = regex.matches(in: original, options: [], range: NSRange(location: 0, length: original.utf16.count))
            for match in self.searchResults.enumerated() {
                if match.offset == 0 {
                    self.scrollTo(result: match.element)
                }
                attributed.addAttribute(.backgroundColor, value: UIColor.black.withAlphaComponent(0.4), range: match.element.range)
            }
            self.prevButton.isEnabled = false
            self.nextButton.isEnabled = self.searchResults.count > 1
            self.currentResult = 0
            self.bodyView.attributedText = attributed
        })
    }
    
    private func scrollTo(result: NSTextCheckingResult) {
        let glyphRange = bodyView.layoutManager.glyphRange(forCharacterRange: result.range, actualCharacterRange: nil)
        let rect = bodyView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: bodyView.textContainer)
        let contentOffset = CGPoint(x: 0, y: max(rect.origin.y - 60, 0))
        bodyView.setContentOffset(contentOffset, animated: true)
    }
}

#endif
