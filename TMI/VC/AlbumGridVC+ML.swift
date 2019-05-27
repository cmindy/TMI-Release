//
//  AlbumGridVC+ML.swift
//  TMI
//
//  Created by CHOMINJI on 13/03/2019.
//  Copyright © 2019 momo. All rights reserved.
//

import UIKit
import Photos
import CoreGraphics
import CoreML
import CoreData
import Accelerate
import FirebaseMLVision
//import FirebaseDatabase

extension AlbumGridVC {
    
    private func setFetchOption() -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return fetchOptions
    }
    
    //포토라이브러리에서 스크린샷 패치 => 앱 실행시 한 번만 할 수 있도록 추후에 조정
    private func appendPhotoLibraryArray(_ photoLibraryArray: inout [String], fetchOptions: PHFetchOptions) {
        
        let getAlbums : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                                subtype: .smartAlbumScreenshots,
                                                                                options: PHFetchOptions())
        
        guard let assetCollection: PHAssetCollection = getAlbums.firstObject else {
            return
        }
        
        assetsFetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        
        if assetsFetchResult.count > 0 {
            for i in 0..<assetsFetchResult.count {
                let imageAsset = assetsFetchResult.object(at: i)
                photoLibraryArray.append(imageAsset.localIdentifier)
            }
        }
    }
    
    private func appendDBArray(_ dbArray:inout [String]) {
        if fetchedRecordArray.count > 0 {
            for fetchedRecord in fetchedRecordArray{
                
                guard let fetchedRecordLocalIdentifer = fetchedRecord.localIdentifier else {
                    return
                }
                
                dbArray.append(fetchedRecordLocalIdentifer)
            }
        }
    }
    
    //포토라이브러리에서 삭제된 스크린샷 디비에서 삭제
    //디비에서 패치된 사진을 기준으로 포토라이브러리에서 패치된 사진을 차집합하고 남은 집합이 앱이 중지된 동안에 삭제된 사진을 의미한다.
    private func saveContext(_ dbArray: [String], photoLibraryArray: [String]) {
        
        let removedAssetArray = dbArray.filter({!(photoLibraryArray.contains($0))})
        print("삭제된 사진들 : \(removedAssetArray)")
        
        for removedAsset in removedAssetArray{
            for fetchedRecord in fetchedRecordArray{
                if removedAsset == fetchedRecord.localIdentifier {
                    context.delete(fetchedRecord)
                    do{
                        try context.save()
                    } catch {
                        print("error occurs when record try to be destroyed from db in DetectChanges method : \(error)")
                    }
                    break
                }
            }
        }
    }
    
    private func matchPlatformAndGetText(_ photoLibraryArray: [String], dbArray: [String]) {
        
        //포토라이브러리에 삽입된 스크린샷 디비에 추가
        //포토라이브러리에서 패치된 사진을 기준으로 디비에서 패치된 사진을 차집합하고 남은 집합이 앱이 중지된 동안에 삽입된 사진을 의미한다.
        let insertedAssetArray  = photoLibraryArray.filter({!(dbArray.contains($0))})
        print("삽입된 사진들 : \(insertedAssetArray)")
        
        for insertedAsset in insertedAssetArray{
            for i in 0..<self.assetsFetchResult.count {
                if insertedAsset == self.assetsFetchResult.object(at: i).localIdentifier {
                    self.imageManager.requestImage(for: self.assetsFetchResult.object(at: i),
                                                   targetSize: thumbnailSize,
                                                   contentMode: .aspectFill,
                                                   options: self.options,
                                                   resultHandler: { image, _ in
                                                    if let image = image{
                                                        
                                                        let maxIndex = self.screenshotPredict(image: image)
                                                        
                                                        self.matchPlatform(maxIndex: maxIndex,
                                                                           imageAsset:self.assetsFetchResult.object(at: i))
                                                        self.getText(screenshot: image,
                                                                     localIdentifier: self.assetsFetchResult.object(at: i).localIdentifier,
                                                                     maxIndex: maxIndex)
                                                    }})
                    break
                }
            }
        }
    }
    
    private func requestImage() {
        for album in AlbumGridVC.albumList{
            
            album.collection = albumDictionary[album.name]!
            
            album.count = albumDictionary[album.name]!.count
            
            if let titleImage = albumDictionary[album.name]!.last {
                imageManager.requestImage(for: titleImage,
                                          targetSize: thumbnailSize,
                                          contentMode: .aspectFill,
                                          options: options,
                                          resultHandler: {
                                            image, _ in
                                            album.image = image!
                })
            } else {
                album.image = UIImage(named: "LaunchScreen")!
            }
        }
        OperationQueue.main.addOperation {
            self.albumGridCollectionView.reloadData()
        }
    }
    
    private func fetchCoreData() {
        do{//디비에서 모든 스크린샷 레코드의 패치 및 로컬아이덴티파이어 배열에 저장
            fetchedRecordArray = try context.fetch(Screenshot.fetchRequest())
        }catch{
            print("coredata fetch error when detectin changes from PhotoLibrary")
        }
    }
    
    //앱 재실행시 포토라이브러리의 변화 탐지
    private func DetectChanges() {
        
        var photoLibraryArray:[String] = []
        
        var dbArray: [String] = []
        
        appendPhotoLibraryArray(&photoLibraryArray, fetchOptions: setFetchOption())
        
        fetchCoreData()
        
        appendDBArray(&dbArray)
        
        saveContext(dbArray, photoLibraryArray: photoLibraryArray)
        
        matchPlatformAndGetText(photoLibraryArray, dbArray: dbArray)
        
        options.resizeMode = .fast
        
        requestImage()
    }
    
    func retrieveAssets() {
        let retrieveGroup = DispatchGroup()
        
        DispatchQueue.main.async(group: retrieveGroup) {
            guard let kakaoTalk = Category(rawValue: "kakaoTalk") else {
                return
            }
            
            guard let everyTime = Category(rawValue: "everyTime") else {
                return
            }
            
            guard let instagram = Category(rawValue: "instagram") else {
                return
            }
            
            guard let others = Category(rawValue: "others") else {
                return
            }
            
            self.fetchCoreData(albumNameCategory: kakaoTalk)
            self.fetchCoreData(albumNameCategory: everyTime)
            self.fetchCoreData(albumNameCategory: instagram)
            self.fetchCoreData(albumNameCategory: others)
        }
        
        retrieveGroup.notify(queue: .main){
            self.DetectChanges()
        }
    }
    
    func fetchCoreData(albumNameCategory: Category) {
        
        let albumName = albumNameCategory.rawValue
        
        let request: NSFetchRequest<Screenshot> = Screenshot.fetchRequest()
        
        request.predicate = NSPredicate(format: "albumName = %@", albumName)
        
        var assetLocalIdentifierArray: [String] = []
        
        do {
            recordArray = try context.fetch(request)
            print("albumName: \(albumName)")
            print("count: \(recordArray.count)")
        } catch {
            print("coredata fetch error")
        }
        
        if recordArray.count > 0 {
            for assetRecord in recordArray {
                let albumRecord: Screenshot = assetRecord
                if let identifier = albumRecord.localIdentifier {
                    assetLocalIdentifierArray.append(identifier)
                }
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let assetsFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetLocalIdentifierArray, options: fetchOptions)
            
            for asset in 0..<assetsFetchResult.count {
                let imageAsset = assetsFetchResult.object(at: asset)
                self.albumDictionary[albumName]?.append(imageAsset)
            }
        }
        
        self.makeAlbumModel(albumTitle: albumName)
    }
    
    
    func GetAlbums() {
        let fetchOptions: PHFetchOptions = PHFetchOptions()
        
        // 스크린샷 앨범만 가져온다.
        let getAlbums : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                                subtype: .smartAlbumScreenshots,
                                                                                options: fetchOptions)
        
        if getAlbums.count > 0 {
            
            guard let assetCollection: PHAssetCollection = getAlbums.firstObject else {
                return
            }
            
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            
            assetsFetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            
            if assetsFetchResult.count > 0 {
                requestOptions.isSynchronous = true //순차적으로 진행되게 하기위해 true!
                
                requestOptions.deliveryMode = .opportunistic
                requestOptions.resizeMode = .fast

                for index in 0..<assetsFetchResult.count {
                  
                    //스크린샷 앨범에서 가져온 사진 오브젝트 하나하나 반복
                  
                    let imageAsset = assetsFetchResult.object(at: index)
                    //requestImageForAsset 을 이용해 이미지를 불러온다
                    
                    imageManager.requestImage(for: imageAsset,
                                              targetSize: thumbnailSize,
                                              contentMode: .aspectFill,
                                              options: requestOptions,
                                              resultHandler: { image, _ in
                                                let newSize = CGSize(width: 149.5, height: 149.5)
                                                let newImage = self.resize(image: image!, newSize: newSize)
                                                
                                                if let pixelBuffer = ImageProcessor.pixelBuffer(forImage: newImage.cgImage!) {                                                self.pixelBufferArray.append(pixelBuffer)
                                                }
//                                                let maxIndex = self.screenshotPredict(image: image!)
//                                                self.matchPlatform(maxIndex: maxIndex, imageAsset: imageAsset)
//                                                self.getText(screenshot: image!, localIdentifier: imageAsset.localIdentifier, maxIndex: maxIndex)
                    })
                }
                
                batchScreenshotPredict()
                
                for index in 0..<assetsFetchResult.count {
                    //스크린샷 앨범에서 가져온 사진 오브젝트 하나하나 반복
                    let imageAsset = assetsFetchResult.object(at: index)
                    //requestImageForAsset 을 이용해 이미지를 불러온다
                    imageManager.requestImage(for: imageAsset,
                                              targetSize: thumbnailSize,
                                              contentMode: .aspectFill,
                                              options: requestOptions,
                                              resultHandler: { image, _ in
                                                    self.matchPlatform(maxIndex: self.maxIndexArray[index], imageAsset: imageAsset)
                                                    self.getText(screenshot: image!, localIdentifier: imageAsset.localIdentifier, maxIndex: self.maxIndexArray[index])
                                                
                                                
                    })
                }
                
                makeAlbumModel(albumTitle: "kakaoTalk")
                makeAlbumModel(albumTitle: "everyTime")
                makeAlbumModel(albumTitle: "instagram")
                makeAlbumModel(albumTitle: "others")
                //
                //                if let kakao = albumDictionary["kakaoTalk"] {
                //                kakaoTalkCollection = PHAssetCollection.transientAssetCollection(with: kakao, title: "카카오톡")
                //                }
                //
                //                if let every = albumDictionary["everyTime"] {
                //                    everyTimeCollection = PHAssetCollection.transientAssetCollection(with: every, title: "에브리타임")
                //                }
                //
                //                if let insta = albumDictionary["instagram"] {
                //                    instagramCollection = PHAssetCollection.transientAssetCollection(with: insta, title: "인스타그램")
                //                }
                //
                //                if let other = albumDictionary["others"] {
                //                    othersCollection = PHAssetCollection.transientAssetCollection(with: other, title: "기타")
                //                }
                //
                //
                //각각 어레이를 collection으로 해서 앨범모델을 만들고 albumList에 추가한다.
            }//if문 끝
        }
    }//GetAlbums 메소드 끝
    
    func makeAlbumModel(albumTitle: String) {
        //순차적으로 진행되게하기위해 true로 설정
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .opportunistic
        
        guard let album = albumDictionary[albumTitle] else {
            return
        }
        
        guard let titleImage = album.last else {
            let newAlbum = AlbumModel(name: albumTitle ,
                                      count: album.count,
                                      image: UIImage(named: "LaunchScreen")!,
                                      collection: album)
            
            AlbumGridVC.albumList.append(newAlbum)
            return
        }
        
        imageManager.requestImage(for: titleImage,
                                  targetSize: thumbnailSize,
                                  contentMode: .aspectFill,
                                  options: requestOptions,
                                  resultHandler: { image, _ in
                                    let newAlbum = AlbumModel(name: albumTitle ,
                                                              count: album.count,
                                                              image: image!,
                                                              collection: album)
                                    AlbumGridVC.albumList.append(newAlbum)
        })
        
        //createAlbum(albumTitle: albumTitle) //앨범 추가(shared)
    }
    
    func matchPlatform(maxIndex: Int, imageAsset: PHAsset){
        switch maxIndex{
        //결과에 따라 각각의 어레이에 imageAsset자체를 넣는다(UIImage 타입 아님)
        case 0:
            albumDictionary["everyTime"]?.append(imageAsset)
        case 1:
            albumDictionary["instagram"]?.append(imageAsset)
        case 2:
            albumDictionary["kakaoTalk"]?.append(imageAsset)
        case 3:
            albumDictionary["others"]?.append(imageAsset)
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
        if let _ : AnyObject = collection.firstObject {
            self.albumFound = true
            
            guard let phAssetCollection = collection.firstObject else {
                return
            }
            
            assetCollection = phAssetCollection
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
                    
                    guard let phAssetCollection = collection.firstObject else {
                        return
                    }
                    
                    self.assetCollection = phAssetCollection
                }
            })
        }
    }
    
    func argmax(_ array: UnsafePointer<Double>, count: Int) -> (Int, Double) {
        //tensorflow의 argmax구현
        var maxValue: Double = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxviD(array, 1, &maxValue, &maxIndex, vDSP_Length(count))
        if(maxValue > 0.8){ return (Int(maxIndex), maxValue)}
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
        let model = final_v3()
        let newSize = CGSize(width: 149.5, height: 149.5)
        let image = resize(image: image, newSize: newSize)
        
        guard let cgImage = image.cgImage else {
            return -1//추론 실패
        }
        
        guard let pixelBuffer = ImageProcessor.pixelBuffer(forImage: cgImage) else {
            return -1//추론 실패
        }
        
        guard let final_v3Output = try? model.prediction(Mul__0: pixelBuffer) else{
            fatalError("error")
        }
        
        let featurePointer = UnsafePointer<Double>(OpaquePointer(final_v3Output.final_result__0.dataPointer))
        
        let (maxIndex, maxValue) = argmax(featurePointer, count: 3)
        
        print("이름은 " + String(maxIndex) + ", 값은 " + String(maxValue))
        
        return maxIndex//추론 성공
    }
    
    func batchScreenshotPredict(){
        let model = final_v3()
        var finalInputArray: [final_v3Input] = []
        for i in pixelBufferArray {
            finalInputArray.append(final_v3Input(Mul__0: i))
        }
        
        guard let final_v3OutputArray = try? model.predictions(inputs: finalInputArray) else {
            fatalError("predictions error")
        }
        let totalCount = final_v3OutputArray.count
//        progressBar.total = Double(totalCount)
        
        for final_v3Output in final_v3OutputArray {
            let featurePointer = UnsafePointer<Double>(OpaquePointer(final_v3Output.final_result__0.dataPointer))
            let (maxIndex, maxValue) = argmax(featurePointer, count: 3)
            print("batch 이름 " + String(maxIndex) + ", 값은 " + String(maxValue))
            
//                self.progressBar.percentage += 1
            
            
            maxIndexArray.append(maxIndex)
        }
    }
}

//MARK:- OCR
extension AlbumGridVC {
    //ocr로 텍스트 추출하고 디비에 localIdentifier&text&albumName을 함께 저장하는 메소드
    func getText(screenshot: UIImage, localIdentifier: String, maxIndex: Int){
        
        let vision = Vision.vision()// https://cloud.google.com/vision/docs/languages => 언어 약자 확인하는 사이트
        let options = VisionCloudTextRecognizerOptions()
        options.languageHints = ["ko", "en"]//ocr에게 어떤 언어인지 미리 힌트 주는거
        
        let textRecognizer = vision.cloudTextRecognizer(options: options)//위의 힌트옵션 추가해서 textRecognizer 생성
        let visionImage = VisionImage(image: screenshot)
        
        textRecognizer.process(visionImage) { result, error in
            
            //textRecognizer Run!
            guard error == nil, let result = result else {
                //이부분 계속 출력되는데 무엇일까용?
                print("OCR textRecognizer error")
                return
            }
            
            let resultText = result.text
            let newRecord = Screenshot(context: self.context) //텍스트모델의 레코드가 될 변수 생성
            
            print(resultText)
            //텍스트 모델의 attribute 저장
            newRecord.localIdentifier = localIdentifier
            newRecord.text = resultText
            
            switch maxIndex{
            case 0:
                newRecord.albumName = "everyTime"
            case 1:
                newRecord.albumName = "instagram"
            case 2:
                newRecord.albumName = "kakaoTalk"
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
    
    func saveRecord(){
        do{ //디비에 변화 저장하는 메소드
            try context.save()
        }catch{
            print("coredata save error")
        }
    }
    
}

enum Category: String {
    case kakaoTalk = "kakaoTalk"
    case everyTime = "everyTime"
    case instagram = "instagram"
    case others = "others"
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
