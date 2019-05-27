//
//  ViewController.swift
//  TMI
//
//  Created by CHOMINJI on 2018. 12. 30..
//  Copyright © 2018년 momo. All rights reserved.
//

import UIKit
import Photos
import CoreGraphics
import CoreML
import CoreData
import Accelerate
import FirebaseMLVision
//import FirebaseDatabase


class AlbumGridVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var albumGridCollectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var assetsFetchResult: PHFetchResult<PHAsset>!
    let imageManager: PHCachingImageManager = PHCachingImageManager() //이미지를 로드해 옴
    private let manager = PHImageManager.default()
    private let requestOptions = PHImageRequestOptions()
    private let availableWidth = UIScreen.main.bounds.size.width
    private let availableHeight = UIScreen.main.bounds.size.height
    
    static var albumList: [AlbumModel] = []
    private var albums: [String:[PHAsset]] = ["kakaoTalk":[], "daumCafe": [], "instagram":[], "others":[]]
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var recordArray = [Screenshot]()
    var fetchedRecordArray = [Screenshot]()
    var searchedLocalIdentifiers: [String] = []
//    private var assetLocalIdentifier: [String] = []
    
    private var smartAlbums: PHFetchResult<PHAssetCollection>!
    private var userCollections: PHFetchResult<PHCollection>!
    
    private var assetCollection: PHAssetCollection!
    private var albumFound : Bool = false
    private var photosAsset: PHFetchResult<PHAsset>!
    private var assetThumbnailSize: CGSize!
    private var collection: PHAssetCollection!
    private var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    
    var searchController: UISearchController!
    var searchAssets: [PHAsset] = []
    var searchImages: [UIImage] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albumGridCollectionView.delegate = self
        albumGridCollectionView.dataSource = self
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        setUpSearchController()
        
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        let defaults = UserDefaults.standard

        //사용자가 사진첩에 접근을 허가했는지
        switch photoAuthorizationStatus {
            case .authorized:
                print("접근 허가됨")
                OperationQueue.main.addOperation {
                    self.activityIndicator.startAnimating()
                    if defaults.object(forKey: "theFirstRun") != nil{
                        //TODO: - 뿌리기
                        print("theFirstRUN 존재함돠")
                        print("recordArray: \(self.recordArray)")
                        
                        self.retrieveAssets()
                        
                    }else{
                        defaults.set(true, forKey: "theFirstRun")
                        //인트로 부르기
                        print("theFirstRUN 존재안혀")
                        self.GetAlbums()
                    }
                    self.albumGridCollectionView.reloadData()
                    self.activityIndicator.stopAnimating()
                    
                }
            case .denied:
                print("접근 불허됨")
            case .notDetermined: //허가하는지 안하는지 선택하지 않으면
                print("아직 응답하지 않음")
                PHPhotoLibrary.requestAuthorization({ (status) in //다시 허가 요청
                    switch status {
                    case .authorized:
                        print("사용자가 허용함")
                        OperationQueue.main.addOperation {
                            //                    self.requestCollection()
                            self.activityIndicator.startAnimating()
                            if defaults.object(forKey: "theFirstRun") != nil{
                                self.retrieveAssets()
                            } else {
                                defaults.set(true, forKey: "theFirstRun")
                                //인트로 부르기
                                self.GetAlbums()
                            }
                            self.albumGridCollectionView.reloadData()
                            self.activityIndicator.stopAnimating()
                        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        albumGridCollectionView.reloadData()

        //메인화면 하단툴바 안보이도록 설정
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    
    
    //MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if isSearch() {
            return fetchedRecordArray.count
        }
        return AlbumGridVC.albumList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AlbumCollectionViewCell
        
        
        if isSearch() {
            let fetchText: Screenshot
            
            fetchText = fetchedRecordArray[indexPath.item]
            
            for searchAsset in searchAssets {
                searchImages.append(convertImageFromAsset(asset: searchAsset))
            }
            
            cell.titleImageView.image = searchImages[indexPath.item]
            cell.titleLabel.text = fetchText.text
            cell.imageCountLabel.text = fetchText.localIdentifier
//            cell.textLabel!.text = fetchText.text
//            cell.detailTextLabel!.text = fetchText.localIdentifier
            
        } else {
            let album: AlbumModel = AlbumGridVC.albumList[indexPath.item]
            cell.titleImageView.image = album.image
            cell.titleLabel.text = album.name
            cell.imageCountLabel.text = String(album.count)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //goto SelectedAlbumImageVC
        //self.performSegue(withIdentifier: "ToDetailAlbum", sender: self)
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        if isSearch() {
            guard let assetVC = storyBoard.instantiateViewController(withIdentifier: "AssetVC") as? AssetVC else { fatalError("Unexpected ViewController") }
            self.navigationController?.pushViewController(assetVC, animated: true)
            assetVC.selectedImage = searchImages[indexPath.item]
            
        } else {
            guard let selectedVC = storyBoard.instantiateViewController(withIdentifier: "AssetGridVC") as? AssetGridVC else { fatalError("Unexpected ViewController") }
            
            self.navigationController?.pushViewController(selectedVC, animated: true)
            PopupAlbumGridVC.currentAlbumIndex = indexPath.item
            selectedVC.selectedAlbums = AlbumGridVC.albumList[indexPath.item].collection
        }
    }
    
    @objc
    func addAlbum(_ sender: AnyObject) {
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
}


extension AlbumGridVC {
    //앱 재실행시 포토라이브러리의 변화 탐지
    func DetectChanges(){
        var photoLibraryArray:[String] = []
        var dbArray: [String] = []
        
        //포토라이브러리에서 스크린샷 패치 => 앱 실행시 한 번만 할 수 있도록 추후에 조정
        let getAlbums : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: PHFetchOptions())
        guard let assetCollection: PHAssetCollection = getAlbums.firstObject else {return}
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        assetsFetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        if assetsFetchResult.count > 0 {
            for i in 0..<assetsFetchResult.count {
                let imageAsset = assetsFetchResult.object(at: i)
                photoLibraryArray.append(imageAsset.localIdentifier)
            }
        }
        
        //디비에서 모든 스크린샷 레코드의 패치 및 로컬아이덴티파이어 배열에 저장
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        do{
            fetchedRecordArray = try context.fetch(request)
        }catch{
            print("coredata fetch error when detectin changes from PhotoLibrary")
        }
        if(fetchedRecordArray.count > 0){
            for record in fetchedRecordArray{
                dbArray.append(record.localIdentifier!)
            }
        }
        
        //포토라이브러리에서 삭제된 스크린샷 디비에서 삭제
        //디비에서 패치된 사진을 기준으로 포토라이브러리에서 패치된 사진을 차집합하고 남은 집합이 앱이 중지된 동안에 삭제된 사진을 의미한다.
        let removedAssetArray = dbArray.filter({!(photoLibraryArray.contains($0))})
        print("삭제된 사진들 : \(removedAssetArray)")
        
        for removedAsset in removedAssetArray{
            for record in fetchedRecordArray{
                if(removedAsset == record.localIdentifier){
                    context.delete(record)
                    do{try context.save()} catch {print("error occurs when record try to be destroyed from db in DetectChanges method : \(error)")}
                    break
                }
            }
        }
        
        //포토라이브러리에 삽입된 스크린샷 디비에 추가
        //포토라이브러리에서 패치된 사진을 기준으로 디비에서 패치된 사진을 차집합하고 남은 집합이 앱이 중지된 동안에 삽입된 사진을 의미한다.
        let insertedAssetArray  = photoLibraryArray.filter({!(dbArray.contains($0))})
        print("삽입된 사진들 : \(insertedAssetArray)")
        
        for insertedAsset in insertedAssetArray{
            for i in 0..<self.assetsFetchResult.count {
                if(insertedAsset == self.assetsFetchResult.object(at: i).localIdentifier){
                    self.manager.requestImage(for: self.assetsFetchResult.object(at: i),targetSize: PHImageManagerMaximumSize,contentMode: .aspectFill,options: self.requestOptions,resultHandler: { image, _ in
                        if let image = image{
                            let maxIndex = self.screenshotPredict(image: image)
                            self.matchPlatform(maxIndex: maxIndex, imageAsset:self.assetsFetchResult.object(at: i))
                            self.getText(screenshot: image, localIdentifier: self.assetsFetchResult.object(at: i).localIdentifier, maxIndex: maxIndex)}})
                    break;
                }
            }
        }
        for album in AlbumGridVC.albumList{
            album.collection = albums[album.name]!
            album.count = albums[album.name]!.count
            if let titleImage = albums[album.name]!.last{
                manager.requestImage(for: titleImage,
                                     targetSize: PHImageManagerMaximumSize,
                                     contentMode: .aspectFill,
                                     options: requestOptions,
                                     resultHandler: { image, _ in
                                        album.image = image!})
            }else{album.image = UIImage(named: "LaunchScreen")!}
        }
        OperationQueue.main.addOperation {self.albumGridCollectionView.reloadData()}
    }
    
    func retrieveAssets() {
        let retrieveGroup = DispatchGroup()
        DispatchQueue.main.async(group: retrieveGroup) {
            self.fetchCoreData(albumName: "kakaoTalk")
            self.fetchCoreData(albumName: "daumCafe")
            self.fetchCoreData(albumName: "instagram")
            self.fetchCoreData(albumName: "others")
        }
        retrieveGroup.notify(queue: .main){
            self.DetectChanges()
        }
    }
    func fetchCoreData(albumName: String) {
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.predicate = NSPredicate(format: "albumName = %@", albumName)
        var assetLocalIdentifiers: [String] = []
        
        do {
            recordArray = try context.fetch(request)
            print("albumName: \(albumName)")
            print("count: \(recordArray.count)")
        } catch {
            print("coredata fetch error")
        }
        
        if(recordArray.count > 0) {
            for assetRecord in recordArray {
                let albumRecord: Screenshot = assetRecord
                assetLocalIdentifiers.append(albumRecord.localIdentifier!)
//                print(albumRecord.localIdentifier)
//                print(albumRecord.albumName)
                
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let assetsFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetLocalIdentifiers, options: fetchOptions)
            
            for i in 0..<assetsFetchResult.count {
                let imageAsset = assetsFetchResult.object(at: i)
                manager.requestImage(for: imageAsset,
                                     targetSize: PHImageManagerMaximumSize,
                                     contentMode: .aspectFill,
                                     options: requestOptions,
                                     resultHandler: { image, _ in
                })
                self.albums[albumName]?.append(imageAsset)
            }
        }
        self.makeAlbumModel(albumTitle: albumName)
    }
    
    func GetAlbums() {
        let options: PHFetchOptions = PHFetchOptions()
        // 스크린샷 앨범만 가져온다.
        let getAlbums : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: options)
        
        if getAlbums.count > 0 {
            guard let assetCollection: PHAssetCollection = getAlbums.firstObject else {return}
            let fetchOptions = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            assetsFetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            if assetsFetchResult.count > 0 {
                requestOptions.isSynchronous = true
                //순차적으로 진행되게 하기위해 true!
                requestOptions.deliveryMode = .highQualityFormat
                for i in 0..<assetsFetchResult.count {
                    //스크린샷 앨범에서 가져온 사진 오브젝트 하나하나 반복
                    let imageAsset = assetsFetchResult.object(at: i)
                    //requestImageForAsset 을 이용해 이미지를 불러온다
                    manager.requestImage(for: imageAsset,
                                         targetSize: PHImageManagerMaximumSize,
                                         //원래의 이미지 사이즈로 가져온다.
                        contentMode: .aspectFill,
                        options: requestOptions,
                        resultHandler: { image, _ in
                            let maxIndex = self.screenshotPredict(image: image!)
                            self.matchPlatform(maxIndex: maxIndex, imageAsset: imageAsset)
                            self.getText(screenshot: image!,localIdentifier: imageAsset.localIdentifier, maxIndex: maxIndex)
                    })//리퀘스트 완료
                }//for문 끝
                makeAlbumModel(albumTitle: "kakaoTalk")
                makeAlbumModel(albumTitle: "daumCafe")
                makeAlbumModel(albumTitle: "instagram")
                makeAlbumModel(albumTitle: "others")
                //각각 어레이를 collection으로 해서 앨범모델을 만들고 albumList에 추가한다.
            }//if문 끝
        }
    }//GetAlbums 메소드 끝
    
    func makeAlbumModel(albumTitle: String){
        requestOptions.isSynchronous = true
        //순차적으로 진행되게하기위해 true로 설정
        requestOptions.deliveryMode = .highQualityFormat
        if let album = albums[albumTitle]{
            let albumCount = album.count
            if let titleImage = album.last{
                //타이틀이미지를 따로 저장하기위해 한 번 더 리퀘스트한다.
                manager.requestImage(for: titleImage,
                                     targetSize: PHImageManagerMaximumSize,
                                     contentMode: .aspectFill,
                                     options: requestOptions,
                                     resultHandler: { image, _ in
                                        let newAlbum = AlbumModel(name: albumTitle ,
                                                                  count: albumCount,
                                                                  image: image!,
                                                                  collection: album)
                                        AlbumGridVC.albumList.append(newAlbum)})
            }else{
                let newAlbum = AlbumModel(name: albumTitle ,
                                          count: albumCount,
                                          image: UIImage(named: "LaunchScreen")!,
                                          collection: album)
                AlbumGridVC.albumList.append(newAlbum)
            }
        }
//        createAlbum(albumTitle: albumTitle) //앨범 추가(shared)
    }
    
    func matchPlatform(maxIndex: Int, imageAsset: PHAsset){
        switch maxIndex{
        //결과에 따라 각각의 어레이에 imageAsset자체를 넣는다(UIImage 타입 아님)
        case 0:
            albums["kakaoTalk"]?.append(imageAsset)
        case 1:
            albums["daumCafe"]?.append(imageAsset)
        case 2:
            albums["instagram"]?.append(imageAsset)
        case 3:
            albums["others"]?.append(imageAsset)
        default:
            print("추론 에러 발생")
        }
    }
    
    func createAlbum(albumTitle: String) {
        //Get PHFetch Options
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        //Check return value - If found, then get the first album out
        if let _: AnyObject = collection.firstObject {
            self.albumFound = true
            assetCollection = collection.firstObject as! PHAssetCollection
        } else {
            //If not found - Then create a new album
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                self.albumFound = success
                
                if (success) {
                    let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.assetCollectionPlaceholder.localIdentifier], options: nil)
                    print(collectionFetchResult)
                    self.assetCollection = collectionFetchResult.firstObject as! PHAssetCollection
                }
            })
        }
    }
    
    func argmax(_ array: UnsafePointer<Double>, count: Int) -> (Int, Double) {
        //tensorflow의 argmax구현
        var maxValue: Double = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxviD(array, 1, &maxValue, &maxIndex, vDSP_Length(count))
        if(maxValue > 0.6){ return (Int(maxIndex), maxValue)}
        else{ return (3, maxValue)}
        
    }

    func resize(image: UIImage, newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func screenshotPredict(image: UIImage) -> Int {
        let model = inception_v3()
        let newSize = CGSize(width: 149.5, height: 149.5) //size 299..?
        //        let newSize = CGSize(width: availableWidth, height: availableHeight)
        let image = resize(image: image, newSize: newSize)
        if let pixelBuffer = ImageProcessor.pixelBuffer(forImage: image.cgImage!) {
            //이미지의 사이즈와 타입을 바꾸기위한 전처리과정 후 추론
            guard let inception_v3Output = try? model.prediction(Mul__0: pixelBuffer) else {
                fatalError("Unexpected runtime error.")}
            let featurePointer = UnsafePointer<Double>(OpaquePointer(inception_v3Output.final_result__0.dataPointer))
            print(inception_v3Output.final_result__0)
            let (maxIndex, maxValue) = argmax(featurePointer, count: 3)
            print("이름은 " + String(maxIndex) + ", 값은 " + String(maxValue))
            return maxIndex
            //추론 성공
        }
        return -1
        //추론 실패
    }
}

//MARK:- OCR
extension AlbumGridVC {
    //ocr로 텍스트 추출하고 디비에 localIdentifier&text&albumName을 함께 저장하는 메소드
    func getText(screenshot: UIImage, localIdentifier: String, maxIndex: Int){
        
        let vision = Vision.vision()// https://cloud.google.com/vision/docs/languages => 언어 약자 확인하는 사이트
        let options = VisionCloudTextRecognizerOptions()
        options.languageHints = ["ko", "en"] //ocr에게 어떤 언어인지 미리 힌트 주는거
        let textRecognizer = vision.cloudTextRecognizer(options: options)//위의 힌트옵션 추가해서 textRecognizer 생성
        let visionImage = VisionImage(image: screenshot)

        textRecognizer.process(visionImage) { result, error in
            //textRecognizer Run!
            guard error == nil, let result = result else {
                print("OCR textRecognizer error")
                return
            }
            let resultText = result.text
            print(resultText)
            let newRecord = Screenshot(context: self.context) //텍스트모델의 레코드가 될 변수 생성
            
            //텍스트 모델의 attribute 저장
            newRecord.localIdentifier = localIdentifier
            newRecord.text = resultText
            switch maxIndex{
                case 0:
                    newRecord.albumName = "kakaoTalk"
                case 1:
                    newRecord.albumName = "daumCafe"
                case 2:
                    newRecord.albumName = "instagram"
                case 3:
                    newRecord.albumName = "others"
                default:
                    print("앨범이름 디비 저장 에러 발생")
            }
            //textArray에 레코드들 추가하기
            self.recordArray.append(newRecord)
            self.saveRecord()
            self.recordArray.removeAll()
        }
    }
    
    //키워드로 스크린샷 서치
/*   func screenshotSearch(keyword: String){
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        request.predicate = NSPredicate(format: "content CONTAINS[cd] %@", keyword)
        do{
            fetchedRecordArray = try context.fetch(request) //조건에 맞는 레코드들 저장
        }catch{
            print("coredata fetch error")
        }
        if(fetchedRecordArray.count > 0){
            for textRecord in fetchedRecordArray{
                //각 레코드들의 localIdentifier만 따로 배열에 저장 후 이를 이용해 뷰에 사진 보여주기
                let aTextRecord:Screenshot = textRecord
                searchedLocalIdentifier.append(aTextRecord.localIdentifier!)
            }
        }
        fetchedRecordArray.removeAll()
        searchedLocalIdentifier.removeAll()
    }
 */
    
    func saveRecord(){
        do{ //디비에 변화 저장하는 메소드
            try context.save()
        }catch{
            print("coredata save error")
        }
    }
}

//MARK:- CollectionViewFlowLayout
//cgImage.size = UIImage.size * UIImage.scale
extension AlbumGridVC: UICollectionViewDelegateFlowLayout {
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




extension AlbumGridVC: PHPhotoLibraryChangeObserver {
    /// - Tag: RespondToChanges
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        let fetchResultChangeDetails = changeInstance.changeDetails(for: assetsFetchResult)
        guard (fetchResultChangeDetails) != nil else {
            print("No change in fetchResultChangeDetails")
            return;
        }
        print("Contains changes")
        assetsFetchResult = (fetchResultChangeDetails?.fetchResultAfterChanges)!
        if let insertedObjects = fetchResultChangeDetails?.insertedObjects{
            print("Assets have been Inserted while TMI's running")
            for insertedAsset in insertedObjects{
                manager.requestImage(for: insertedAsset,
                                     targetSize: PHImageManagerMaximumSize,
                                     contentMode: .aspectFill,
                                     options: requestOptions,
                                     resultHandler: { image, _ in
                                        let maxIndex = self.screenshotPredict(image: image!)
                                        self.matchPlatform(maxIndex: maxIndex, imageAsset: insertedAsset)
                                        self.getText(screenshot: image!, localIdentifier: insertedAsset.localIdentifier, maxIndex: maxIndex)
                })
            }//포토라이브러리에서 삽입된 이미지들 디비 저장 및 각 albums 배열에 저장완료
        }
        //삭제된 이미지 처리
        if let removedObjects = fetchResultChangeDetails?.removedObjects{
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
            for (key, value) in albums {
                albums[key] = value.filter({!(removedObjects.contains($0))})
            }
        }
        for album in AlbumGridVC.albumList{
            album.collection = albums[album.name]!
            album.count = albums[album.name]!.count
            if let titleImage = albums[album.name]!.last{
                manager.requestImage(for: titleImage,
                                     targetSize: PHImageManagerMaximumSize,
                                     contentMode: .aspectFill,
                                     options: requestOptions,
                                     resultHandler: { image, _ in
                                        album.image = image!})
            }else{album.image = UIImage(named: "LaunchScreen")!}
        }
        OperationQueue.main.addOperation {self.albumGridCollectionView.reloadData()}
    }
}

