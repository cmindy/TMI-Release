//
//  StartVC.swift
//  TMI
//
//  Created by CHOMINJI on 24/03/2019.
//  Copyright © 2019 momo. All rights reserved.
//

import UIKit
import Photos

class StartVC: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.makeRounded(cornerRadius: 24)
//        startButton.addTarget(self, action: #selector(self.startButtonTapped), for: .touchUpInside)
        
    }
    
    @objc func startButtonTapped() {
//        authorizatePhotoState()
        guard let loadingVC = storyboard?.instantiateViewController(withIdentifier: "LoadingVC") else {
            fatalError("No loadingVC")
        }
        self.addChild(loadingVC)
        loadingVC.view.frame = self.view.frame
        self.view.addSubview(loadingVC.view)
        loadingVC.didMove(toParent: self)
        
    }
    
//    private func authorizatePhotoState() {
//
//        guard let nextVC = storyboard?.instantiateViewController(withIdentifier: "AlbumGridVC") as? AlbumGridVC else {
//            fatalError("No AlbumGridVC")
//        }
//        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
//
//        //사용자가 사진첩에 접근을 허가했는지
//        switch photoAuthorizationStatus {
//        case .authorized:
//            print("접근 허가됨")
//            nextVC.isAuthorizedPhotos = true
//        case .denied:
//            print("접근 불허됨")
//        case .notDetermined: //허가하는지 안하는지 선택하지 않으면
//            print("아직 응답하지 않음")
//            PHPhotoLibrary.requestAuthorization({ (status) in //다시 허가 요청
//                switch status {
//                case .authorized:
//                    nextVC.isAuthorizedPhotos = true
//                case .denied:
//                    print("사용자가 불허함")
//                default: break
//                }
//            })
//        case .restricted:
//            print("접근 제한")
//        }
//
//        /* //커스텀 앨범 추가
//         let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addAlbum))
//         self.navigationItem.rightBarButtonItem = addButton
//         */
//
//        PHPhotoLibrary.shared().register(AlbumGridVC.self()) //포토 라이브러리가 변화될 때마다 델리게이트가 호출됨
//    }
    
    
}
