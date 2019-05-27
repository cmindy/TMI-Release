//
//  SearchVC.swift
//  TMI
//
//  Created by CHOMINJI on 08/02/2019.
//  Copyright © 2019 momo. All rights reserved.
//

import UIKit
import CoreData
import Photos

class SearchVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    
    
    @IBOutlet weak var searchBarView: UIView!
    
    @IBOutlet weak var searchWordCollectionView: UICollectionView!
    @IBOutlet weak var searchCollectionView: UICollectionView!
    
  
    @IBOutlet weak var collectionViewFlowLayout: SearchGridLayout!
    
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    var searchWordArray = ["Instagram", "민지", "에타", "토스"]
    
    var searchController: UISearchController!
    
    var searchedAssests : PHFetchResult<PHAsset>!
    
    var searchedAssetArray: [PHAsset] = []
    
    var searchImages: [UIImage] = []
    
    var isSearchButtonClicked = false
    
    var fetchedRecordArray = [Screenshot]()
    
    var searchedLocalIdentifiers: [String] = []
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var recordArray = [Screenshot]()
    
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    
    @objc func popSearchs(){
        self.searchController.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        
        let backBTN = UIBarButtonItem(image: UIImage(named: "buttonsArrowBack"),
            style: .plain,
            target: self,
            action: #selector(self.popSearchs))
        navigationItem.leftBarButtonItem = backBTN
        navigationItem.leftBarButtonItem?.tintColor = .black
        navigationController?.interactivePopGestureRecognizer?.delegate = self as? UIGestureRecognizerDelegate
        
        
        setUpSearchController()
        
        searchWordCollectionView.delegate = self
        searchWordCollectionView.dataSource = self
        
        searchCollectionView.delegate = self
        searchCollectionView.dataSource = self
        
        searchCollectionView.contentInset = UIEdgeInsets(top: 34, left: 16, bottom: 0, right: 16)
        
        if let layout = searchCollectionView.collectionViewLayout as? SearchGridLayout {
            layout.delegate = self
        }
        
        searchWordCollectionView.isHidden = false
        searchCollectionView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        var bound = CGRect()
        //        bound = searchController.searchBar.frame
        //        bound.size.width = 343
        //        searchController.searchBar.bounds = bound
        
        let scale = UIScreen.main.scale
        
        let cellSize = collectionViewFlowLayout.collectionViewContentSize
        
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            var bounds: CGRect
            bounds = textField.frame
            bounds.size.height = 60 //(set height whatever you want)
            textField.bounds = bounds
            textField.borderStyle = UITextField.BorderStyle.none
            textField.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
            
            textField.font = UIFont.systemFont(ofSize: 20)
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == searchCollectionView {
            if fetchedRecordArray.count == 0 {
                guard let searchString = searchController.searchBar.text else {
                    return fetchedRecordArray.count
                }
                searchCollectionView.setEmptyMessage("'\(searchString)'에 대한 사진이 없어요")
            } else {
                searchCollectionView.restore()
            }
            return fetchedRecordArray.count
        } else {
            return searchWordArray.count
        }
    }
    
    fileprivate func setCellAppearance(_ cell: UICollectionViewCell) {
        
        if cell is SearchWordCollectionViewCell {
            cell.contentView.layer.cornerRadius = 19
            cell.contentView.layer.borderWidth = 0.5
            cell.contentView.layer.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 4.0)
            cell.layer.shadowRadius = 15.0
            cell.layer.shadowOpacity = 0.05
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.contentView.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        } else if cell is AssetGridViewCell {
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
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == searchCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedAlbumCell", for: indexPath) as? AssetGridViewCell else {
                fatalError("no assetgridviewcell")
            }
        
            setCellAppearance(cell)
        
            let fetchText: Screenshot = fetchedRecordArray[indexPath.item]
        
            let option = PHImageRequestOptions()
        
            let asset = searchedAssests.object(at: indexPath.item)
        
            option.resizeMode = .fast
        
            cell.representedAssetIdentifier = asset.localIdentifier
        
            print("localIdentifier: \(asset.localIdentifier)")
            imageManager.requestImage(for: asset,
                                      targetSize: thumbnailSize,
                                      contentMode: .aspectFill,
                                      options: option, resultHandler: { image, _ in
                                        if cell.representedAssetIdentifier == asset.localIdentifier {
                                            cell.thumbnailImage = image
                                        }
            })
            return cell
        
        } else {

            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchWordCell", for: indexPath) as? SearchWordCollectionViewCell else {
                fatalError("no searchWordCollectionView Cell")
            }
            cell.searchWordLabel.text = searchWordArray[indexPath.item]
            setCellAppearance(cell)
            return cell
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == searchCollectionView {
            guard let assetVC = storyboard?.instantiateViewController(withIdentifier: "AssetVC") as? AssetVC else {
                fatalError("Unexpected ViewController")
            }
            
            self.searchController.dismiss(animated: false, completion: nil)
            self.navigationController?.pushViewController(assetVC, animated: true)
            assetVC.asset = searchedAssests.object(at: indexPath.item)
            
            
        } else {
            guard let currentCell = collectionView.cellForItem(at: indexPath) as? SearchWordCollectionViewCell else {
                fatalError("no cell")
            }
            searchController.searchBar.text = currentCell.searchWordLabel.text
            searchController.searchBar.becomeFirstResponder()
            
        }
    }
    
    
    
    
    func setUpSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.becomeFirstResponder()
        
        
        if #available(iOS 11.0, *) {
            searchController.searchBar.backgroundImage = UIImage(named: "searchBarBackGround")
            searchController.searchBar.tintColor = UIColor.black
            searchController.searchBar.barTintColor = UIColor.red
            
            searchController.searchBar.placeholder = "사진 속의 단어를 검색해보세요"
            if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
                
                let clearButton = textfield.value(forKey: "clearButton") as! UIButton
                clearButton.setImage(UIImage(named: "buttonsCancel"), for: .normal)
                let glassIconView = textfield.leftView as? UIImageView
                glassIconView?.image = glassIconView?.image?.withRenderingMode(.alwaysTemplate)
                glassIconView?.tintColor = UIColor.white
                //                glassIconView?.image = nil
                
            }
        }
        
        searchBarView.addSubview(searchController.searchBar)
        //        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
        //        searchController.searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        //        searchController.searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        //        searchController.searchBar.topAnchor.constraint(equalTo: searchBarView.topAnchor).isActive = true
        searchController.searchBar.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
    }
    
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//            albumGridCollectionView.reloadData()
            
            searchWordCollectionView.reloadData()
        }
    
    func updateSearchResults(for searchController: UISearchController) {
        print("업데이트")
        let searchBar = searchController.searchBar
        
        guard let serachBarText = searchBar.text else {
            return
        }
        
        screenshotSearch(keyword: serachBarText)
        isSearchButtonClicked = false
        hiddenCollectionView()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchBar = searchController.searchBar
        screenshotSearch(keyword: searchBar.text!)
        isSearchButtonClicked = true
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isSearch() -> Bool {
        //        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        if isSearchButtonClicked == true {
            return true
        } else {
            return searchController.isActive && !searchBarIsEmpty()
        }
    }
    
    func hiddenCollectionView() {
        if isSearch() == true {
            searchWordCollectionView.isHidden = true
            searchCollectionView.isHidden = false
        } else {
            searchWordCollectionView.isHidden = false
            searchCollectionView.isHidden = true
        }
    }
    
    func screenshotSearch(keyword: String){
        
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        //SQL query로는 (select * from Text where content LIKE '%keyword%')와 같은 작업
        request.predicate = NSPredicate(format: "text CONTAINS[cd] %@", keyword)
        do {
            fetchedRecordArray = try context.fetch(request) //조건에 맞는 레코드들 저장
        } catch {
            print("coredata fetch error")
        }
        if(fetchedRecordArray.count > 0){
            for textRecord in fetchedRecordArray{
                //각 레코드들의 localIdentifier만 따로 배열에 저장 후 이를 이용해 뷰에 사진 보여주기
                let aTextRecord:Screenshot = textRecord
                searchedLocalIdentifiers.append(aTextRecord.localIdentifier!)
            }
        }
        print("***********검색된 사진의 localIdentifier =")
        print(searchedLocalIdentifiers)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        
        searchedAssetArray.removeAll()
        searchImages.removeAll()
        
        searchedAssests = PHAsset.fetchAssets(withLocalIdentifiers: searchedLocalIdentifiers, options: nil)
        if searchedAssests != nil {
            if searchedAssests.count == searchedLocalIdentifiers.count {
                print("asset count: \(searchedAssests.count)")
                for asset in 0..<searchedAssests.count {
                    let asset = searchedAssests.object(at: asset)
                    searchedAssetArray.append(asset)
                }
            }
        }
        
        searchedLocalIdentifiers.removeAll()
        
        if searchedAssetArray.count == fetchedRecordArray.count {
            searchCollectionView.reloadData()
            searchCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
}
extension SearchVC : SearchGridLayoutDelegate {
    
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


//extension SearchVC: UICollectionViewDelegateFlowLayout {
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width: CGFloat = (view.frame.width) * 0.26
//        let height: CGFloat = (view.frame.height) * 0.06
//        return CGSize(width: width, height: height)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return 8
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//    }
//}


extension UICollectionView {
    
    func setEmptyMessage(_ message: String) {
        let backView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        backView.sizeToFit()

        let emptyImageView = UIImageView()
        emptyImageView.contentMode = .scaleAspectFit
        emptyImageView.image = #imageLiteral(resourceName: "imgError")
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageLabel.sizeToFit()
        
        backView.addSubview(emptyImageView)
        backView.addSubview(messageLabel)
        
        emptyImageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyImageView.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
//            emptyImageView.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            
            NSLayoutConstraint(item: emptyImageView, attribute: .centerY, relatedBy: .equal, toItem: backView, attribute: .centerY, multiplier: 0.5, constant: 0),
            emptyImageView.widthAnchor.constraint(equalTo: backView.widthAnchor, multiplier: 0.32),
            emptyImageView.heightAnchor.constraint(equalTo: emptyImageView.heightAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 24),
            messageLabel.widthAnchor.constraint(equalTo: backView.widthAnchor),
            ])
        
        self.backgroundView = backView;
    }
    
    func restore() {
        self.backgroundView = nil
    }
}
