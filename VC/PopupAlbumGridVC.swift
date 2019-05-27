//
//  PopupAlbumGridVC.swift
//  TMI
//
//  Created by CHOMINJI on 05/02/2019.
//  Copyright © 2019 momo. All rights reserved.
//

import UIKit
import Photos
import CoreData

class PopupAlbumGridVC: UIViewController {

    @IBOutlet weak var albumCollectionView: UICollectionView!
    var movingAssetIndexs: [Int] = []
    var movingAssets: [PHAsset] = []
    static var currentAlbumIndex: Int = 0
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()

        albumCollectionView.delegate = self
        albumCollectionView.dataSource = self
    }
    
}

extension PopupAlbumGridVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AlbumGridVC.albumList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AlbumCollectionViewCell
        let album: AlbumModel = AlbumGridVC.albumList[indexPath.item]
        cell.titleImageView.image = album.image
        cell.titleLabel.text = album.name
        cell.imageCountLabel.text = String(album.count)
        
        //현재 앨범이면 선택 못하도록
        if (indexPath.item == PopupAlbumGridVC.currentAlbumIndex) {
            cell.alpha = 0.3
            cell.isUserInteractionEnabled = false
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //albumList에 선택한 에셋을 이동시킴(첫 화면에서도 연동 가능하도록)
        var countToUp = AlbumGridVC.albumList[indexPath.item].count
        var countToDown = AlbumGridVC.albumList[PopupAlbumGridVC.currentAlbumIndex].count

        for asset in movingAssets {
            //이동한 앨범에 asset 추가
            AlbumGridVC.albumList[indexPath.item].collection.append(asset)
            countToUp = countToUp + 1

            //현재 선택한 앨범에서 이동한 asset 삭제
            AlbumGridVC.albumList[PopupAlbumGridVC.currentAlbumIndex].collection.removeAll {
                (movingPhoto) -> Bool in
                return movingPhoto == asset
            }
            countToDown = countToDown - 1
            
            //이동한 asset의 데이터베이스 albumName 속성값 변경
            let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
            request.predicate = NSPredicate(format: "localIdentifier = %@", asset.localIdentifier )
            do{
                if let movingRecord:Screenshot = try context.fetch(request).last{
                    movingRecord.albumName  = AlbumGridVC.albumList[indexPath.item].name
                    do{try context.save()}catch{print(error)}
                }
            }catch{ print("coredata fetch error when screenshot is moved")}
        }
        AlbumGridVC.albumList[indexPath.item].count = countToUp
        AlbumGridVC.albumList[PopupAlbumGridVC.currentAlbumIndex].count = countToDown
        self.navigationController?.popToRootViewController(animated: true)
        
    }
}

//MARK:- CollectionViewFlowLayout
extension PopupAlbumGridVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = (view.frame.width) / 2 - 20
        let height: CGFloat = (view.frame.width) / 2 + 28
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}

