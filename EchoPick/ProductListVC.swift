//
//  ProductListVC.swift
//  EchoPick
//
//  Created by Prianka Liz Kariat on 8/18/16.
//  Copyright © 2016 Prianka Liz Kariat. All rights reserved.
//

import UIKit

import Speech

struct ProductListVCConstants {
  
  static let saceBetweenCells: CGFloat = 15.0
  static let labelHeight: CGFloat = 20.0
  static let cellFreeSpace: CGFloat = 37.0
  static let cellHeight: CGFloat = 44.0
  static let margin: CGFloat = 15.0
  static let voiceFilterCollectionViewSpace: CGFloat = 20.0
  static let collectionViewSpace: CGFloat = 10.0
}

struct API {
  
  static let accessToken = "5abd3980bf5b411896afe98df28e0478"
}

struct Product {
  
  let type = "jeans"
  var color = "blue"
  var size: Int = 30
  var fit = "comfort"
  var brand = "lee"
  var imageName: String
  var productName: String
  var price: Float
}

struct CurrentFilters {
  
  var color: String?
  var size: Int?
  var fit: String?
  var brand: String?
  var count:Int = 0
  var currentFilterNames: [String] = []
  
}

enum ColorMapping: String {
  
  case Blue = "blue"
  case Red = "red"
  case Black = "black"
  case Brown = "brown"
  case Green = "green"
  
  func resolvedUIColor() -> UIColor {
    switch self {
    case .Blue:
      return UIColor.blue()
    case .Black:
      return UIColor.black()
    case .Red:
      return UIColor.red()
    case .Brown:
      return UIColor.brown()
    case .Green:
      return UIColor.green()
    }
  }
  
}


class ProductListVC: UIViewController {
  
  var isRecording: Bool = false
  
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(localeIdentifier: "en-IN"))!
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  
  private var products: [Product] = []
  private var currentProducts: [Product] = []
  private var currentFilters: CurrentFilters = CurrentFilters()
  private var authorized: Bool = false
  
  @IBOutlet weak var productCollectionViewTop: NSLayoutConstraint!
  @IBOutlet weak var animatedVoiceView: UIImageView!
  @IBOutlet weak var talkToAddFiltersLabel: UILabel!
  @IBOutlet weak var filterCollectionView: UICollectionView!
  @IBOutlet weak var labelToButtonSpace: NSLayoutConstraint!
  @IBOutlet weak var spokenTextLabel: UILabel!
  @IBOutlet weak var voiceFilterView: UIView!
  @IBOutlet weak var productCollectionView: UICollectionView!
  @IBOutlet weak var micButton: UIButton!
  @IBOutlet weak var clearButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.topItem?.title = "JEANS"
    navigationController?.navigationBar.barStyle = .black
    productCollectionViewTop.constant = ProductListVCConstants.collectionViewSpace
    
    buildDataSource()
    clearButton.isHidden = true
    productCollectionView.reloadData()
    
    var animationImages: [UIImage] = []
    
    for i in 200...388 {
      let imageName = "mic00" + "\(i)"
      animationImages.append(UIImage(named: imageName)!)
    }
    
    animatedVoiceView.animationImages = animationImages
    animatedVoiceView.animationDuration = 2.0
    animatedVoiceView.image = UIImage(named: "mic00200")
    
    // Do any additional setup after loading the view.
  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    super.viewDidAppear(animated)
    askForSpeechRecognitionPermissions()
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func onClickSpeakButton(_ sender: AnyObject) {
    
    
    self.navigationController?.isNavigationBarHidden = true
    self.voiceFilterView.isHidden = false
    productCollectionViewTop.constant = ProductListVCConstants.voiceFilterCollectionViewSpace
    labelToButtonSpace.constant = 30.0
    startRecordingAudio()
    
  }
  
  func storeFiltersWithParametersDict(paramDict: [String : String]) {
    
    for param in paramDict {
      
      if param.value.characters.count == 0 {
        continue
      }
      
      switch param.key {
      case "color":
        currentFilters.color = param.value
        currentFilters.count = currentFilters.count + 1
        currentFilters.currentFilterNames.append("Color")
      case "Fit":
        currentFilters.fit = param.value
        currentFilters.count = currentFilters.count + 1
        currentFilters.currentFilterNames.append("Fit")
        
      case "size":
        currentFilters.size = Int(param.value)
        currentFilters.count = currentFilters.count + 1
        currentFilters.currentFilterNames.append("Size")
        
      case "Brand":
        currentFilters.brand = param.value
        currentFilters.count = currentFilters.count + 1
        currentFilters.currentFilterNames.append("Brand")
        
      default:
        break
      }
    }
  }
  
  
  func clearCurrentFilters() {
    currentFilters.color = nil
    currentFilters.brand = nil
    currentFilters.fit = nil
    currentFilters.size = nil
    currentFilters.count = 0
    currentFilters.currentFilterNames = []
  }
  
  func startRecording() throws {
    
    if let recognitionTask = recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
    }
    
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryRecord)
    try audioSession.setMode(AVAudioSessionModeMeasurement)
    try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
    
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
    guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
    
    recognitionRequest.shouldReportPartialResults = true
    
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {[weak self] result, error in
      var isFinal = false
      
      if let result = result {
        
        self?.spokenTextLabel.text = result.bestTranscription.formattedString
        self?.talkToAddFiltersLabel.isHidden = result.bestTranscription.formattedString.characters.count > 0
        isFinal = result.isFinal
        
      }
      
      if error != nil || isFinal {
        self?.stopRecording()
      }
    }
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {[weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
      self?.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    
    try audioEngine.start()
  }
  
  
  func startRecordingAudio()  {
    
    do {
      try startRecording()
      defer {
        spokenTextLabel.isHidden = false
        talkToAddFiltersLabel.isHidden = false
        micButton.isSelected = true
        isRecording = true
        animatedVoiceView.startAnimating()
      }
    }
    catch {
      
    }
  }
  
  func performPostRequestWithSpokenString(string: String) {
    
    let json = [ "query":[string] , "sessionId": NSUUID().uuidString , "lang" : "en"]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    
    // create post request
    let url = URL(string: "https://api.api.ai/v1/query?v=20160518")!
    // let url = URL(string: "https://testflightbox.com:9004/client")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // insert json data to the request
    request.httpBody = jsonData
    request.setValue("Bearer  \(API.accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    
    let task = URLSession.shared().dataTask(with: request) {[weak self] (data, response, error) in
      
      DispatchQueue.main.async(execute: {
        if let responseJSON = try? JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? ([String: AnyObject]){
          
          if let responseJSON = responseJSON?["result"], let parameters = responseJSON["parameters"] as? [String : String]{
            
            self?.storeFiltersWithParametersDict(paramDict: parameters)
            self?.filterCollectionView.reloadData()
            self?.filterResults()
            return
          }
          else {
            self?.micButton.isEnabled = true
          }
        }
        else {
          
          self?.micButton.isEnabled = true
        }
        
      })
    }
    task.resume()
    
  }
  
  
  func filterResults(){
    
    spokenTextLabel.isHidden = true
    spokenTextLabel.text = ""
    
    guard currentFilters.count > 0 else {
      
      currentProducts = products
      productCollectionView.reloadData()
      talkToAddFiltersLabel.isHidden = false
      micButton.isEnabled = true
      clearButton.isHidden = true
      return
    }
    
    micButton.isEnabled = false
    talkToAddFiltersLabel.isHidden = true
    clearButton.isHidden = false
    currentProducts = products.filter { (product) -> Bool in
      
      return shouldIncludeProduct(product: product)
    }
    productCollectionView.reloadData()
  }
  
  private func shouldIncludeProduct(product: Product) -> Bool {
    
    var shouldInclude = true
    
    if let color = currentFilters.color {
      shouldInclude = shouldInclude && product.color.caseInsensitiveCompare(color) == .orderedSame
    }
    
    if let brand = currentFilters.brand {
      shouldInclude = shouldInclude && product.brand.caseInsensitiveCompare(brand) == .orderedSame
    }
    
    if let fit = currentFilters.fit {
      shouldInclude = shouldInclude && product.fit.caseInsensitiveCompare(fit) == .orderedSame
    }
    
    if let size = currentFilters.size {
      shouldInclude = shouldInclude && (size == product.size)
    }
    
    return shouldInclude
    
  }
  
  
  //MARK: Button Actions
  @IBAction func onClickMicButton(_ sender: AnyObject) {
    
    guard micButton.isSelected == true else {
      startRecordingAudio()
      return
    }
    
    if audioEngine.isRunning {
      
      stopRecording()
      micButton.isEnabled = false
      if let spokenText = spokenTextLabel.text {
        self.performPostRequestWithSpokenString(string:spokenText)
      }
    }
    
  }
  
  @IBAction func onClickClearButton(_ sender: AnyObject) {
    
    if audioEngine.isRunning {
      stopRecording()
    }
    
    clearCurrentFilters()
    filterCollectionView.reloadData()
    filterResults()
    startRecordingAudio()
    
  }
  
  
  @IBAction func onClickCloseButton(_ sender: AnyObject) {
    
    self.navigationController?.isNavigationBarHidden = false
    
    if audioEngine.isRunning {
      stopRecording()
    }
    
    voiceFilterView.isHidden = true
    productCollectionViewTop.constant = ProductListVCConstants.collectionViewSpace
    labelToButtonSpace.constant = -39.0
    clearCurrentFilters()
    filterCollectionView.reloadData()
    filterResults()
    
  }
  
  
  //MARK: Private Methods
  
  private func buildDataSource() {
    
    addProductWithColor(color: "blue", size: 32, fit: "Comfort", brand: "Lee", productName: "DEST001", imageName: "jeans_1", price: 100.0)
    addProductWithColor(color: "blue", size: 32, fit: "Comfort", brand: "Lee", productName: "DEST002", imageName: "jeans_2", price: 200.0)
    addProductWithColor(color: "blue", size: 34, fit: "Slim", brand: "Lee", productName: "DEST003", imageName: "jeans_3", price: 100.0)
    addProductWithColor(color: "blue", size: 30, fit: "Skinny", brand: "Lee", productName: "DEST004", imageName: "jeans_4", price: 200.0)
    addProductWithColor(color: "blue", size: 30, fit: "Comfort", brand: "Wrangler", productName: "DEST005", imageName: "jeans_5", price: 200.0)
    addProductWithColor(color: "blue", size: 30, fit: "Slim", brand: "Wrangler", productName: "DEST007", imageName: "jeans_6", price: 100.0)
    addProductWithColor(color: "blue", size: 31, fit: "Skinny", brand: "Wrangler", productName: "DEST008", imageName: "jeans_7", price: 300.0)
    addProductWithColor(color: "blue", size: 33, fit: "Comfort", brand: "Levis", productName: "DEST009", imageName: "jeans_8", price: 200.0)
    addProductWithColor(color: "black", size: 32, fit: "Comfort", brand: "Levis", productName: "DEST010", imageName: "jeans_9", price: 200.0)
    addProductWithColor(color: "blue", size: 32, fit: "Slim", brand: "Levis", productName: "DEST011", imageName: "jeans_10", price: 200.0)
    
    currentProducts = products
    
  }
  
  private func addProductWithColor(color: String, size: Int, fit: String, brand: String, productName: String, imageName: String, price: Float) {
    
    let product =  Product(color: color, size: size, fit: fit, brand: brand, imageName: imageName, productName: productName, price: price)
    products.append(product)
    
  }
  
  private func presentAlertForPresentingSettings() {
    
    let alertController = UIAlertController(title: "Error", message: "This app doesn't have permission to use speech recognition. Please change the privacy settings", preferredStyle: UIAlertControllerStyle.alert)
    
    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
    alertController.addAction(okAction)
    
    let settingsAction = UIAlertAction(title: "SETTINGS", style: UIAlertActionStyle.default, handler: { (alertAction: UIAlertAction) -> Void in
      
      UIApplication.shared().openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    })
    
    alertController.addAction(settingsAction)
    self.present(alertController, animated: true, completion: nil)
  }
  
  private func askForSpeechRecognitionPermissions() {
    
    SFSpeechRecognizer.requestAuthorization {[weak self] (authorizationStatus) in
      
      DispatchQueue.main.async(execute: {
        
        switch authorizationStatus {
          
        case .authorized:
          self?.authorized = true
          break
        case .denied:
          self?.presentAlertForPresentingSettings()
          break
        default:
          break
        }
      })
      
    }
    
  }
  
  private func stopRecording() {
    
    audioEngine.stop()
    recognitionRequest?.endAudio()
    let inputNode = audioEngine.inputNode
    inputNode?.removeTap(onBus: 0)
    self.recognitionRequest = nil
    self.recognitionTask = nil
    
    micButton.isSelected = false
    animatedVoiceView.stopAnimating()
    
  }
  
}


//MARK: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension ProductListVC : UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    if collectionView == productCollectionView {
      return currentProducts.count
    }
    else if collectionView == filterCollectionView {
      
      return currentFilters.count
    }
    
    return 0
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    var cell: UICollectionViewCell?
    
    if collectionView == productCollectionView {
      
      cell = productCollectionViewCellForItemAtIndexPath(indexPath: indexPath)
    }
    else if collectionView == filterCollectionView {
      
      cell = filterCollectionViewCellForItemAtIndexPath(indexPath: indexPath)
      
    }
    
    return cell!
  }
  
  
  func productCollectionViewCellForItemAtIndexPath(indexPath: IndexPath) -> UICollectionViewCell {
    
    let collectionCell = productCollectionView.dequeueReusableCell(withReuseIdentifier: "PRODUCT_CELL", for: indexPath) as! ProductCollectionCell
    
    let product = currentProducts[indexPath.item!]
    collectionCell.productName.text = product.brand
    collectionCell.fitName.text = product.fit
    collectionCell.priceLabel.text = "$\(product.price)"
    collectionCell.productImage.image = UIImage(named: product.imageName)
    
    return collectionCell
  }
  
  func filterCollectionViewCellForItemAtIndexPath(indexPath: IndexPath) -> UICollectionViewCell {
    
    let filterName = currentFilters.currentFilterNames[indexPath.item!]
    
    if filterName == "Color" {
      
      let collectionCell = filterCollectionView.dequeueReusableCell(withReuseIdentifier: "COLOR_CELL", for: indexPath) as! ColorCollectionCell
      collectionCell.delegate = self
      
      var color = UIColor.white()
      if let mappedColor =  ColorMapping(rawValue: currentFilters.color!)?.resolvedUIColor() {
        color = mappedColor
      }
      collectionCell.colorView.backgroundColor = color
      return collectionCell
    }
    else {
      
      let collectionCell = filterCollectionView.dequeueReusableCell(withReuseIdentifier: "FILTER_CELL", for: indexPath) as! FilterCollectionCell
      collectionCell.delegate = self
      collectionCell.filterLabel.text = filterLabelTextAtIndex(index: indexPath.item!)
      return collectionCell
      
    }
    
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    if collectionView == productCollectionView {
      
      let width = (view.bounds.size.width - (ProductListVCConstants.margin * 2.0) - ProductListVCConstants.saceBetweenCells) / 2.0
      return  CGSize(width: width, height: 250.0)
    }
    else if collectionView == filterCollectionView {
      
      var width: CGFloat = 0.0
      
      let filterName = currentFilters.currentFilterNames[indexPath.item!]
      
      if filterName == "Color" {
        width = 63.0
      }
      else
      {
        let labelString = filterLabelTextAtIndex(index: indexPath.item!)
        width = labelString.widthWithConstrainedHeight(height: ProductListVCConstants.labelHeight) + ProductListVCConstants.cellFreeSpace
      }
      return CGSize(width: width, height: ProductListVCConstants.cellHeight)
      
    }
    
    return CGSize(width: 0.0, height: 0.0)
  }
  
  func filterLabelTextAtIndex(index: Int) -> String {
    var filterName: String
    var filterValue: String?
    
    filterName = currentFilters.currentFilterNames[index]
    switch currentFilters.currentFilterNames[index] {
    case "Color":
      filterValue = currentFilters.color
    case "Fit":
      filterValue = currentFilters.fit
    case "Brand":
      filterValue = currentFilters.brand
    case "Size":
      filterValue = "\(currentFilters.size!)"
    default:
      break
    }
    
    return "\(filterName) : \(filterValue!)"
    
  }
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return .lightContent
  }
  
}

//MARK: FilterCollectionCellDelegate
extension ProductListVC: FilterCollectionCellDelegate {
  
  func closeButtonClickedOnCell(collectionCell: UICollectionViewCell) {
    
    let indexPath = filterCollectionView.indexPath(for: collectionCell)
    
    if let item = indexPath?.item {
      removeFilterAtIndex(index: item)
      filterCollectionView.reloadData()
      filterResults()
      
      if currentFilters.count == 0 {
        startRecordingAudio()
      }
    }
  }
  
  
  func removeFilterAtIndex(index: Int) {
    
    switch currentFilters.currentFilterNames[index] {
    case "Color":
      currentFilters.color = nil
    case "Fit":
      currentFilters.fit = nil
    case "Brand":
      currentFilters.brand = nil
    case "Size":
      currentFilters.size = nil
    default:
      break
    }
    
    currentFilters.currentFilterNames.remove(at: index)
    currentFilters.count = currentFilters.count - 1
  }
  
}

//MARK: String Extension
extension String {
  
  func widthWithConstrainedHeight(height: CGFloat) -> CGFloat {
    let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
    
    let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:[NSFontAttributeName : UIFont.systemFont(ofSize: 18.0)], context: nil)
    
    return ceil(boundingBox.width)
  }
}
