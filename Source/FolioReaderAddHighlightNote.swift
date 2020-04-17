//
//  FolioReaderAddHighlightNote.swift
//  FolioReaderKit
//
//  Created by ShuichiNagao on 2018/05/06.
//

import UIKit
import RealmSwift

class FolioReaderAddHighlightNote: UIViewController {

    var textView: UITextView = UITextView()
    var highlightLabel: UILabel = UILabel()
    var containerView = UIView()
    var highlight: Highlight!
    var highlightSaved = false
    var isEditHighlight = false
    var resizedTextView = false
    
    private var folioReader: FolioReader
    private var readerConfig: FolioReaderConfig
    
    init(withHighlight highlight: Highlight, folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.folioReader = folioReader
        self.highlight = highlight
        self.readerConfig = readerConfig
        
        super.init(nibName: nil, bundle: Bundle.frameworkBundle())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    // MARK: - life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCloseButton(withConfiguration: readerConfig)
        prepareViews()
        layoutViews()
        
        configureNavBar()
        configureKeyboardObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.becomeFirstResponder()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !highlightSaved && !isEditHighlight {
            guard let currentPage = folioReader.readerCenter?.currentPage else { return }
            currentPage.webView?.js("removeThisHighlight()")
        }
    }
    
    // MARK: - private methods
    
    private func prepareViews(){
        view.addSubview(containerView)
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        highlightLabel.translatesAutoresizingMaskIntoConstraints = false
        highlightLabel.numberOfLines = 3
        highlightLabel.font = UIFont.systemFont(ofSize: 15)
        highlightLabel.text = highlight.content.stripHtml().truncate(250, trailing: "...").stripLineBreaks()
        
        containerView.addSubview(highlightLabel)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = .black
        textView.backgroundColor = .clear
        textView.font = UIFont.boldSystemFont(ofSize: 15)
        containerView.addSubview(textView)
        
        if isEditHighlight {
             textView.text = highlight.noteForHighlight
        }
        
        self.textView.textContainerInset = UIEdgeInsets.zero
        self.textView.textContainer.lineFragmentPadding = 0
    }
    
    private func layoutViews() {
        NSLayoutConstraint.activate([
            highlightLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            highlightLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),
            highlightLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            highlightLabel.heightAnchor.constraint(equalToConstant: 70),
        ])
        
        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            textView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            textView.topAnchor.constraint(equalTo: highlightLabel.bottomAnchor),
        ])
    }
    
    private func configureNavBar() {
        let navBackground = folioReader.isNight(self.readerConfig.nightModeNavBackground, self.readerConfig.daysModeNavBackground)
        let tintColor = readerConfig.tintColor
        let navText = folioReader.isNight(UIColor.white, UIColor.black)
        let font = UIFont(name: "Avenir-Light", size: 17)!
        setTranslucentNavigation(false, color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
        
        let titleAttrs = [NSAttributedString.Key.foregroundColor: readerConfig.tintColor]
        let saveButton = UIBarButtonItem(title: readerConfig.localizedSave, style: .plain, target: self, action: #selector(saveNote(_:)))
        saveButton.setTitleTextAttributes(titleAttrs, for: UIControl.State())
        navigationItem.rightBarButtonItem = saveButton
    }
    
    private func configureKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        self.textView.contentInset.bottom = keyboardFrame.size.height
        self.textView.scrollIndicatorInsets.bottom = keyboardFrame.size.height
    }
    
    @objc private func keyboardWillHide(notification:NSNotification){
        let contentInset: UIEdgeInsets = .zero
        self.textView.contentInset = contentInset
        self.textView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func saveNote(_ sender: UIBarButtonItem) {
        if !textView.text.isEmpty {
            if isEditHighlight {
                let realm = try! Realm(configuration: readerConfig.realmConfiguration)
                realm.beginWrite()
                highlight.noteForHighlight = textView.text
                highlightSaved = true
                try! realm.commitWrite()
            } else {
                highlight.noteForHighlight = textView.text
                highlight.persist(withConfiguration: readerConfig)
                highlightSaved = true
            }
        }
        
        dismiss()
    }
}
