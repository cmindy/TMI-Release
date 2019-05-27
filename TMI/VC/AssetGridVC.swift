//
//  SelectedAlbumImageVC.swift
//  TMI
//
//  Created by CHOMINJI on 2019. 1. 18..
//  Copyright © 2019년 momo. All rights reserved.
//

import UIKit
import Photos

class AssetGridVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var detailCollectionView: UICollectionView!
    @IBOutlet var moveButton: UIBarButtonItem!
    @IBOutlet var trashButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!
    @IBOutlet var space: UIBarButtonItem!
    
    @IBOutlet weak var collectionViewFlowLayout: AssetGridLayout!
    
    
    var selectedAssetIndex: [Int] = []
    var selectedAlbums: [PHAsset] = []
    var selectedIndexPath: [IndexPath] = []
    var selectedAlbumTitleString = String()
    var collectionCheckStatus = false
    
    var currentAlbumIndex: Int = 0
    var fetchResult: PHFetchResult<PHAsset>!
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    var assetCollection: PHAssetCollection!
    
    var availableWidth: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailCollectionView.delegate = self
        detailCollectionView.dataSource = self
        
        //        setNavigationBar()
        setBackBtn(color: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))

        
        let selectButton = UIBarButtonItem(title: "선택", style: .plain, target: self, action: #selector(self.selectAssets))
        self.navigationItem.rightBarButtonItem = selectButton
        
        moveButton.isEnabled = false
        trashButton.isEnabled = false
        shareButton.isEnabled = false
        
        detailCollectionView.contentInset = UIEdgeInsets(top: 30, left: 10, bottom: 10, right: 10)
        if let layout = detailCollectionView.collectionViewLayout as? AssetGridLayout {
            layout.delegate = self
        }
        let headerNib = UINib(nibName: "AssetGridCollectionReusableView", bundle: nil)
        detailCollectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        
//        detailCollectionView.contentInset = UIEdgeInsets(top: 23, left: 10, bottom: 10, right: 10)
    
    }
    
    override func viewWillLayoutSubviews() {
         super.viewWillLayoutSubviews()
        
        let isNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        view.backgroundColor = isNavigationBarHidden ? .black : .white
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = true
        navigationController?.hidesBarsOnTap = false
        navigationController?.navigationBar.tintColor = .black
        navigationController?.toolbar.tintColor = UIColor.neonBlue
        navigationController?.title = nil
       
        
        toolbarItems = [ shareButton, space, moveButton, space, trashButton]
        
        let scale = UIScreen.main.scale
        
        let cellSize = collectionViewFlowLayout.collectionViewContentSize        
        
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedAlbums.count
    }
    
    fileprivate func setCellAppearance(_ cell: AssetGridViewCell) {
        cell.contentView.layer.cornerRadius = 19
        cell.contentView.layer.borderWidth = 0.5
        cell.contentView.layer.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 5.0)
        cell.layer.shadowRadius = 25.0
        cell.layer.shadowOpacity = 0.15
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as? AssetGridCollectionReusableView else {return .init()}
            
            headerView.albumNameLabel.text = selectedAlbumTitleString
            headerView.albumCountLabel.text = "\(selectedAlbums.count)"
            
            return headerView
            
        default://I only needed a header so if not header I return an empty view
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = selectedAlbums[indexPath.item]
        
        guard let cell = detailCollectionView.dequeueReusableCell(withReuseIdentifier: "SelectedAlbumCell", for: indexPath) as? AssetGridViewCell else {
            fatalError("no assetGridViewCell")
        }
        setCellAppearance(cell)
        
        cell.emptyCheckImageView.isHidden = true
        cell.checkImageView.isHidden = true
        
        guard let sublayers = cell.contentView.layer.sublayers else {
            return .init()
        }
        
        for layer in sublayers {
            if layer.name == "blueLayer" {
                layer.removeFromSuperlayer()
            }
        }
        
        
        if collectionCheckStatus == true {
            cell.emptyCheckImageView.isHidden = false
        } else {
            cell.emptyCheckImageView.isHidden = true
            cell.checkImageView.isHidden = true
        }
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard detailCollectionView.allowsMultipleSelection else {
            
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            
            guard let _ = storyBoard.instantiateViewController(withIdentifier: "AssetVC") as? AssetVC else {
                return
            }
            
            guard let dashBoard = storyBoard.instantiateViewController(withIdentifier: "DashBoard") as? DashBoard else {
                return
            }
            
            dashBoard.selectedAlbums = selectedAlbums
            dashBoard.albumIndex = indexPath
            dashBoard.selectedIndex = indexPath.row
            dashBoard.fetchResult = fetchResult
            dashBoard.navBarTitle = selectedAlbumTitleString
            
            self.navigationController?.pushViewController(dashBoard, animated: true)
//            present(dashBoard, animated: true , completion: nil)
            
            
//            guard let pageNav = storyboard?.instantiateViewController(withIdentifier: "PageNavigation") as? UINavigationController else {
//                fatalError("no nav")
//            }
//            pageNav.pushViewController(dashBoard, animated: true)
//            present(pageNav, animated: false, completion: nil)
            
            return
        }
        
        guard let currentCell = collectionView.cellForItem(at: indexPath) as? AssetGridViewCell else {
            return
        }
        
        let blueLayer = CALayer()
        blueLayer.name = "blueLayer"
        blueLayer.frame = currentCell.contentView.bounds
        blueLayer.backgroundColor = UIColor.neonBlue.withAlphaComponent(0.7).cgColor
        
        
        
        if currentCell.isChecked {
            print("해제할것")
            currentCell.isChecked = false
            
            currentCell.checkImageView.isHidden = true
            currentCell.emptyCheckImageView.isHidden = false
            
            guard let sublayers = currentCell.contentView.layer.sublayers else {
                return
            }
            
            for layer in sublayers {
                if layer.name == "blueLayer" {
                    layer.removeFromSuperlayer()
                }
            }
            
//            currentCell.layoutSublayers(of: currentCell.contentView.layer)
            
            if let indexPath = collectionView.indexPath(for: currentCell) {
                selectedIndexPath.removeAll { (index) -> Bool in
                    return index == indexPath
                }
            }
            
        } else {
            currentCell.isChecked = true
            print("선택됨")
            currentCell.checkImageView.isHidden = false
            currentCell.emptyCheckImageView.isHidden = true
            
            currentCell.contentView.layer.insertSublayer(blueLayer, below: currentCell.checkImageView.layer)
            
            
        
            
            if let indexPath = collectionView.indexPath(for: currentCell) {
                selectedIndexPath.append(indexPath)
                print(selectedIndexPath)
            }
        }
        
        //이동버튼 활성화 비활성화
        if selectedIndexPath.count > 0 {
            
            moveButton.isEnabled = true
            trashButton.isEnabled = true
            shareButton.isEnabled = true
            moveButton.target = self
            moveButton.action = #selector(moveToAlbumGridView(_:))
            shareButton.target = self
//            shareButton.action
            
            trashButton.target = self
            trashButton.action = #selector(deleteSelectAlbum(_:))
            
        } else {
            moveButton.isEnabled = false
            trashButton.isEnabled = false
            shareButton.isEnabled = false
        }
    }
    
    @objc func share(sender:UIView){
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let textToShare = "TMI"
        
        if let myWebsite = URL(string: "http://itunes.apple.com") {//Enter link to your app here
            let objectsToShare = [textToShare, myWebsite, image ?? #imageLiteral(resourceName: "app-logo")] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.mail
            ]
            //
            
            activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @objc
    func selectAssets(_ sender: UIBarButtonItem) {
        
        detailCollectionView.allowsMultipleSelection = true
        
        if sender.title == "선택" {
            sender.title = "취소"
            collectionCheckStatus = true
            navigationController?.isToolbarHidden = false
            detailCollectionView.reloadData()
            
            
        } else {
            sender.title = "선택"
            collectionCheckStatus = false
            
            navigationController?.isToolbarHidden = true
            detailCollectionView.allowsMultipleSelection = false
            selectedAssetIndex.removeAll()
            
            for index in selectedIndexPath {
                if let currentCell = detailCollectionView.cellForItem(at: index) as? AssetGridViewCell {
                    currentCell.isChecked = false
                    currentCell.checkImageView.isHidden = true
                }
            }
            UIView.performWithoutAnimation {
                detailCollectionView.reloadData()
            }
            selectedIndexPath.removeAll()
        }
    }
    
    //trashButton
    @objc func deleteSelectAlbum(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: nil, message: "remove", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
            var count = AlbumGridVC.albumList[self.currentAlbumIndex].count
            
            for i in self.selectedAssetIndex {
                
                let indexPath = IndexPath(row: i, section: 0)
                
                self.selectedAlbums.remove(at: indexPath.item)
                
                self.detailCollectionView.deleteItems(at: [indexPath])
                
                AlbumGridVC.albumList[self.currentAlbumIndex].collection.remove(at: i)
                
                count = count - 1
            }
            
            AlbumGridVC.albumList[self.currentAlbumIndex].count = count
            
            var userInfo: [String: Any] = [:]
            
            userInfo["selectedAlbum"] = "others"
            
            userInfo["selectedAssetIndex"] = self.selectedAssetIndex
            
            NotificationCenter.default.post(
                name: NSNotification.Name("deleteAsset"),
                object: nil, userInfo: userInfo)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func moveToAlbumGridView(_ sender: UIBarButtonItem) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let popVC = storyBoard.instantiateViewController(withIdentifier: "PopupAlbumGridVC") as? PopupAlbumGridVC else {
            return
        }
        
        self.addChild(popVC)
        popVC.view.frame = self.view.frame
        self.view.addSubview(popVC.view)
        popVC.didMove(toParent: self)
        
        for i in selectedIndexPath {
            print("selectedImage: \(selectedAlbums[i.item])")
            popVC.movingAssets.append(selectedAlbums[i.item])
        }
    }
}


//MARK:- CollectionViewFlowLayout
extension AssetGridVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let insets = collectionView.contentInset
        let width: CGFloat = collectionView.bounds.width - (insets.left + insets.right) - 20
        let columnWidth = width / CGFloat(2)
        
        var height: CGFloat = CGFloat()
        let number = indexPath.item % 4
        
        if number == 0 {
            height = view.frame.height * 0.42
        } else if number == 1{
            height = view.frame.height * 0.25
        } else if number == 2 {
            height = view.frame.height * 0.19
        } else if number == 3 {
            height = view.frame.height * 0.42
        }
        
        return CGSize(width: columnWidth, height: height)
    }
    
    
}

extension AssetGridVC : AssetGridLayoutDelegate {
    
    // 1. Returns the photo height
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
        
        let number = indexPath.item % 4
        
        if number == 0 {
            return view.frame.height * 0.42
        } else if number == 1{
            return view.frame.height * 0.25
        } else if number == 2 {
            return view.frame.height * 0.19
        } else if number == 3 {
            return view.frame.height * 0.42
        }
        
        return CGFloat()
    }
    
}
