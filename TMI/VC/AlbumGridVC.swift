//
//  ViewController.swift
//  TMI
//
//  Created by CHOMINJI on 2018. 12. 30..
//  Copyright © 2018년 momo. All rights reserved.
//

import UIKit
import Photos
import CoreData

class AlbumGridVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBAction func mlBtn(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "theFirstRun")
    }
    
    @IBOutlet weak var albumGridCollectionView: UICollectionView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    
    var assetsFetchResult: PHFetchResult<PHAsset>!
    
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    let requestOptions = PHImageRequestOptions()
    
    let options = PHImageRequestOptions()
    
    static var albumList: [AlbumModel] = []
    
    var albumDictionary: [String:[PHAsset]] = ["kakaoTalk":[], "everyTime": [], "instagram":[], "others":[]]
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var recordArray = [Screenshot]()
    
    var assetCollection: PHAssetCollection!
    
    var albumFound : Bool = false
    
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    var thumbnailSize: CGSize!
    
    var previousPreheatRect = CGRect.zero
    
    var fetchedRecordArray = [Screenshot]()
    
    var searchedLocalIdentifiers: [String] = []
    
    var searchController: UISearchController!
    
    var searchedAssests : PHFetchResult<PHAsset>!
    
    var searchedAssetArray: [PHAsset] = []
    
    var searchImages: [UIImage] = []
    

    var isSearchButtonClicked = false

    var pixelBufferArray: [CVPixelBuffer] = []
    var maxIndexArray: [Int] = []
    
    let progressBar: ProgressBar
    let loadingView = UIView()

    fileprivate func setCollectionView() {
        DispatchQueue.main.async {
            
            self.activityIndicator.startAnimating()
            
            if UserDefaults.standard.object(forKey: "theFirstRun") != nil {
                self.retrieveAssets()
            } else {
                UserDefaults.standard.set(true, forKey: "theFirstRun")
                //앱 처음 실행
                //TODO: 인트로 부르기
//                self.setProgressBar()
                
                self.GetAlbums()
                
//                if self.progressBar.percentage == self.progressBar.total {
//                    self.navigationController?.setNavigationBarHidden(false, animated: false)
//                    self.loadingView.isHidden = true
//                    self.albumGridCollectionView.isHidden = false
//                }
            }
            
            self.resetCachedAssets()
            
            self.albumGridCollectionView.reloadData()
            
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func authorizatePhotoState() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        //사용자가 사진첩에 접근을 허가했는지
        switch photoAuthorizationStatus {
        case .authorized:
            print("접근 허가됨")
            setCollectionView()
        case .denied:
            print("접근 불허됨")
        case .notDetermined: //허가하는지 안하는지 선택하지 않으면
            print("아직 응답하지 않음")
            PHPhotoLibrary.requestAuthorization({ (status) in //다시 허가 요청
                switch status {
                case .authorized:
                    self.setCollectionView()
                case .denied:
                    print("사용자가 불허함")
                default: break
                }
            })
        case .restricted:
            print("접근 제한")
        }
        
        /* //커스텀 앨범 추가
         let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addAlbum))
         self.navigationItem.rightBarButtonItem = addButton
         */
        
        PHPhotoLibrary.shared().register(self) //포토 라이브러리가 변화될 때마다 델리게이트가 호출됨
    }
    
    required init?(coder aDecoder: NSCoder) {
        progressBar = ProgressBar()
        super.init(coder: aDecoder)
    }
    
    @objc func buttonTapped() {
        progressBar.percentage += 1
    }
    
//    fileprivate func setProgressBar() {
//        albumGridCollectionView.isHidden = true
//        navigationController?.setNavigationBarHidden(true, animated: false)
//
//
//        loadingView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(loadingView)
//        NSLayoutConstraint.activate([
//            loadingView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
//            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            loadingView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
//            ])
//
//        let barImageView = UIImageView(image: UIImage(named: "imgLogoBar32Px"))
//        let folderImageView = UIImageView(image: UIImage(named: "imgFolder"))
//        let infoLabel = UILabel()
//        let progressLabel = UILabel()
//        progressLabel.tag = 99
//
//        infoLabel.text = "갤러리의 스크린샷을\n 정리하고 있어요"
//        infoLabel.lineBreakMode = .byWordWrapping
//        infoLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
//        infoLabel.numberOfLines = 2
//        infoLabel.textAlignment = .center
//        infoLabel.sizeToFit()
//
//
//        loadingView.addSubview(barImageView)
//        loadingView.addSubview(folderImageView)
//        loadingView.addSubview(infoLabel)
//        loadingView.addSubview(progressBar)
//
//
//        barImageView.translatesAutoresizingMaskIntoConstraints = false
//        folderImageView.translatesAutoresizingMaskIntoConstraints = false
//        infoLabel.translatesAutoresizingMaskIntoConstraints = false
//        progressBar.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            barImageView.topAnchor.constraint(equalTo: loadingView.topAnchor),
//            barImageView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
//
//            folderImageView.topAnchor.constraint(equalTo: loadingView.topAnchor, constant: 138),
//            folderImageView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
//
//            infoLabel.topAnchor.constraint(equalTo: folderImageView.bottomAnchor, constant: 24),
//            infoLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
//
//            progressBar.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 24),
//            progressBar.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 24),
//            progressBar.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -24),
//            
//            ])
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        albumGridCollectionView.delegate = self
        albumGridCollectionView.dataSource = self
        albumGridCollectionView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 10, right: 0)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        authorizatePhotoState()
        addButtonsToNavigationBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(deleteItem(_:)),
                                               name: NSNotification.Name("deleteAsset"),
                                               object: nil)
    }
    
    /// - Tag: UnregisterChangeObserver
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name("deleteAsset"),
                                                  object: nil)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        albumGridCollectionView.reloadData()
        
        hideBottomToolbar()
        
        setThumNailSize()
    }
    
    func addButtonsToNavigationBar(){
        let plusButton = UIButton(type: UIButton.ButtonType.custom)
        
        plusButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//        plusButton.addTarget(self, action: "plusButtonTapped", for: .touchUpInside)
        plusButton.setImage(UIImage(named: "buttonsPlus"), for: .normal)
        
        let plusBarButtonItem = UIBarButtonItem(customView: plusButton)
        
        let searchButton = UIButton(type: UIButton.ButtonType.custom)
        searchButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        searchButton.addTarget(self, action: "searchButtonTapped", for: .touchUpInside)
        searchButton.setImage(UIImage(named: "buttonsSearch"), for: .normal)
        
        let userBarButtonItem = UIBarButtonItem(customView: searchButton)
        
        self.navigationItem.leftBarButtonItems = [plusBarButtonItem, userBarButtonItem]
    }
    
    @objc func searchButtonTapped() {
        guard let searchVC = storyboard?.instantiateViewController(withIdentifier: "SearchVC") else {
            fatalError("No searchVC")
        }
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    private func hideBottomToolbar() {
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    private func setThumNailSize() {
        let scale = UIScreen.main.scale
        let cellSize = collectionViewFlowLayout.itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    //MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AlbumGridVC.albumList.count
    }
    
    fileprivate func setCellAppearance(_ cell: AlbumCollectionViewCell) {
        cell.titleImageView.layer.cornerRadius = 8
        cell.titleImageView.layer.borderWidth = 0.5
        cell.titleImageView.layer.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        cell.titleImageView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 5.0)
        cell.layer.shadowRadius = 25.0
        cell.layer.shadowOpacity = 0.15
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.titleImageView.bounds, cornerRadius: cell.titleImageView.layer.cornerRadius).cgPath
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? AlbumCollectionViewCell else {
            fatalError("no albumcollectionviewcell")
        }
        
        setCellAppearance(cell)
            let album: AlbumModel = AlbumGridVC.albumList[indexPath.item]
            cell.thumbnailImage = album.image
            cell.titleLabel.text = album.name
            cell.imageCountLabel.text = String(album.count)
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
//        if isSearch() {
//            guard let assetVC = storyBoard.instantiateViewController(withIdentifier: "AssetVC") as? AssetVC else {
//                fatalError("Unexpected ViewController")
//            }
//
//            self.navigationController?.pushViewController(assetVC, animated: true)
//
//            assetVC.asset = searchedAssests.object(at: indexPath.item)
//
//        } else {
        
            guard let selectedVC = storyBoard.instantiateViewController(withIdentifier: "AssetGridVC") as? AssetGridVC else {
                fatalError("Unexpected ViewController")
            }
            
            self.navigationController?.pushViewController(selectedVC, animated: true)
            
            PopupAlbumGridVC.currentAlbumIndex = indexPath.item
            selectedVC.selectedAlbumTitleString = AlbumGridVC.albumList[indexPath.item].name
            selectedVC.selectedAlbums = AlbumGridVC.albumList[indexPath.item].collection
//        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "AlbumGridHeaderView",
                for: indexPath) as? AlbumGridCollectionReusableView
            else {
                fatalError("Invalid view type")
        }
        var totalScreenshotCount = 0
        for album in AlbumGridVC.albumList {
            totalScreenshotCount += album.count
        }
        headerView.label.text = "\(totalScreenshotCount)개의 스크린샷을"
        
        if let myLabel = headerView.label.text {
            let attributedString = NSMutableAttributedString(string: myLabel)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.neonBlue, range: (attributedString.string as NSString).range(of:"\(totalScreenshotCount)개"))
            headerView.label.attributedText = attributedString
        }
        return headerView
    }
    
    @objc func addAlbum(_ sender: AnyObject) {
        let alertController = UIAlertController(title: NSLocalizedString("New Album", comment: ""), message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = NSLocalizedString("Album Name", comment: "")
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { action in
            let textField = alertController.textFields!.first!
            if let title = textField.text, !title.isEmpty {
                // Create a new album with the entered title.
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                }, completionHandler: { success, error in
                    if !success { print("Error creating album: \(String(describing: error)).") }
                })
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func deleteItem(_ notification: Notification) {
        guard let _: String = notification.userInfo?["selectedAlbum"] as? String else {
            return
        }
        
        guard let selectedAssetIndex: [Int] = notification.userInfo?["selectedAssetIndex"] as? [Int] else {
            return
        }
        
        print("1234567890::::::::::::::::::::::::::::::::::")
        
        for i in selectedAssetIndex{
            print("-----",i)
        }
    }
}

//MARK:- CollectionViewFlowLayout
//cgImage.size = UIImage.size * UIImage.scale
extension AlbumGridVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = (collectionView.frame.width) / 2 - 8
        let height: CGFloat = width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 38 + 8 + 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 28, left: 0, bottom: 10, right: 0)
    }
}

extension AlbumGridVC: PHPhotoLibraryChangeObserver {
    /// - Tag: RespondToChanges
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard assetsFetchResult != nil else {
            return
        }
        
        guard let changes = changeInstance.changeDetails(for: assetsFetchResult) else {
            print("No change in fetchResultChangeDetails")
            return;
        }
        DispatchQueue.main.sync {
            
            print("Contains changes")
            assetsFetchResult = changes.fetchResultAfterChanges
            let insertedObjects = changes.insertedObjects
            if insertedObjects.count > 0 {
                print("Assets have been Inserted while TMI's running")
                for insertedAsset in insertedObjects{
                    imageManager.requestImage(for: insertedAsset,
                                              targetSize: thumbnailSize,
                                              contentMode: .aspectFill,
                                              options: requestOptions,
                                              resultHandler: { image, _ in
                                                
                                                let maxIndex =
                                                    self.screenshotPredict(image: image!)
                                                self.matchPlatform(maxIndex: maxIndex, imageAsset: insertedAsset)
                                                self.getText(screenshot: image!, localIdentifier: insertedAsset.localIdentifier, maxIndex: maxIndex)
                    })
                }//포토라이브러리에서 삽입된 이미지들 디비 저장 및 각 albums 배열에 저장완료
            }
            //삭제된 이미지 처리
            let removedObjects = changes.removedObjects
            if removedObjects.count > 0 {
                print("Assets have been Removed while TMI's running")
                let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
                for removedAsset in removedObjects{
                    request.predicate = NSPredicate(format: "localIdentifier = %@", removedAsset.localIdentifier )
                    do{
                        if let removedRecord:Screenshot = try context.fetch(request).last{
                            context.delete(removedRecord)
                            do{try context.save()}catch{print(error)}
                        }
                    }catch{ print("coredata fetch error when screenshot is deleted in photoLibraryDidChange")}
                }
                for (key, value) in albumDictionary {
                    albumDictionary[key] = value.filter({!(removedObjects.contains($0))})
                }
            }
            
            for album in AlbumGridVC.albumList {
                album.collection = albumDictionary[album.name]!
                album.count = albumDictionary[album.name]!.count
                if let titleImage = albumDictionary[album.name]!.last{
                    imageManager.requestImage(for: titleImage,
                                              targetSize: thumbnailSize,
                                              contentMode: .aspectFill,
                                              options: requestOptions,
                                              resultHandler: { image, _ in
                                                album.image = image!})
                } else {
                    album.image = UIImage(named: "LaunchScreen")!
                    
                }
            }
            self.albumGridCollectionView.reloadData()
            resetCachedAssets()
            
        }
    }
}

extension AlbumGridVC {
    // MARK: UIScrollView
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: Asset Caching
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    /// - Tag: UpdateAssets
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        guard assetsFetchResult != nil else { return }
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: albumGridCollectionView!.contentOffset, size: albumGridCollectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in albumGridCollectionView.indexPathsForElements(in: rect) }
            .map { indexPath in assetsFetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in albumGridCollectionView.indexPathsForElements(in: rect) }
            .map { indexPath in assetsFetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}


class ProgressBar: UIView {
    private let progressView: UIView
    private var progressBarWidth: NSLayoutConstraint? = nil
    private let progressLabel: UILabel
    
    var total: Double = 0
    var progressRate: Double = 0
    
    var percentage: Double = 0 {
        didSet {
            updateProgress()
        }
    }
    
    
    init() {
        progressView = UIView()
        progressLabel = UILabel()
        super.init(frame: .zero)
        setupBackgroundBar()
        setupProgressView()
        setupProgreeLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupBackgroundBar() {
        self.heightAnchor.constraint(equalToConstant: 6).isActive = true
        self.backgroundColor = UIColor.init(red: 239, green: 239, blue: 239, alpha: 1)
    }
    
    private func setupProgressView(){
        self.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        progressView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        progressView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        progressView.backgroundColor = UIColor.cyan
    }
    
    func setupProgreeLabel() {
        self.addSubview(progressLabel)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        progressLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive = true
        progressLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
    }
    
    func updateProgress() {
        let progressMultiplier = CGFloat(percentage/total)
        
        DispatchQueue.main.async {
            let intMul = Int(self.percentage/self.total) * 100
            self.progressLabel.text = "\(intMul)%"
            
            UIView.animate(withDuration: 1.0) {
            if let progressConstraint = self.progressBarWidth {
                NSLayoutConstraint.deactivate([progressConstraint])
            }
            self.progressBarWidth = self.progressView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: progressMultiplier)
            self.progressBarWidth?.isActive = true
            self.layoutIfNeeded()
         }
        }
    }
}
