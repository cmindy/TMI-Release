//
//  DashBoard.swift
//  TMI
//
//  Created by 어혜민 on 31/01/2019.
//  Copyright © 2019 momo. All rights reserved.
//

import UIKit
import Photos

class DashBoard: UIViewController, UIPageViewControllerDataSource, UIScrollViewDelegate {
    
    private var asset: PHAsset!
    
    var fetchResult: PHFetchResult<PHAsset>!
    
    var selectedAlbums: [PHAsset] = []
    
    var albumIndex: IndexPath = IndexPath()
    
    var selectedIndex: Int = 0
    
    var navBar: UINavigationBar = UINavigationBar()
    
    var navBarTitle = String()
    
    private var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: PageView.bounds.width * scale, height: PageView.bounds.height * scale)
    }
    
    @IBOutlet weak var PageView: UIView!
    @IBOutlet weak var dashBoardNavigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setPageVC()
        
        
    }
    
    override func viewWillLayoutSubviews() {
        
        let isNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        
        view.backgroundColor = isNavigationBarHidden ? .black : .white
        navigationController?.isToolbarHidden = isNavigationBarHidden ? true : false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isTranslucent = true
        
        navigationController?.navigationBar.setBackgroundImage(UIImage.from(color: UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        setBackBtn(color: .white)
        

        navigationController?.isToolbarHidden = false
        navigationController?.hidesBarsOnTap = true
        
//        toolbarItems = [trashButton, space, moveButton]
//
//        let scale = UIScreen.main.scale
//        
//        let cellSize = collectionViewFlowLayout.collectionViewContentSize
//
//        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.hidesBarsOnTap = false
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.setToolbarHidden(true, animated: false)
        navigationController?.navigationBar.topItem?.title = nil
        
    }
    

    
    private func setPageVC() {
        
        guard let PageVC = self.storyboard?.instantiateViewController(withIdentifier: "PageVC") as? UIPageViewController else {
            fatalError("no such VC")
        }
        view.backgroundColor = .white
        let InitialView = AssetVCIndex(index: selectedIndex) as AssetVC
        let ViewController = NSArray(object: InitialView)
        
//        pageViewController.setViewControllers(ViewController as? [AssetVC], direction: .forward, animated: true, completion: nil)
//        addChild(pageViewController)
//        view.addSubview(pageViewController.view)
//        pageViewController.didMove(toParent: self)
        
        for view in InitialView.view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.delegate = self
//                scrollView.contentInsetAdjustmentBehavior = .always
            }
        }
        
        
        navigationController?.hidesBarsOnTap = true
        
        PageVC.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        PageView.addSubview(PageVC.view)
        addChild(PageVC)
       

        PageVC.didMove(toParent: self)
        
        PageVC.dataSource = self
        
        PageVC.setViewControllers(ViewController as? [UIViewController], direction: .forward, animated: true, completion: nil)
        
    }
    
    //MARK: - Page View
    private func AssetVCIndex(index: Int) -> AssetVC {
        
        guard let AssetVC = self.storyboard?.instantiateViewController(withIdentifier: "AssetVC") as? AssetVC else {
            fatalError("no such VC")
        }
        
        if selectedAlbums.count == 0 || index >= selectedAlbums.count {
            return .init()
        }
        
        guard let date = selectedAlbums[index].creationDate else {
            return .init()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        AssetVC.pageIndex = index
        AssetVC.asset = selectedAlbums[index]
//        AssetVC.navBarTitle = navBarTitle
        navigationController?.navigationBar.topItem?.title = navBarTitle
        return AssetVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let assetVC = viewController as? AssetVC else {
            return .init()
        }
        var selectedIndex = assetVC.pageIndex as Int
        
        if selectedIndex == 0 || selectedIndex == NSNotFound {
            return nil
        }
        
        selectedIndex -= 1
        navigationController?.hidesBarsOnTap = true
        
        return AssetVCIndex(index: selectedIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let assetVC = viewController as? AssetVC else {
            return .init()
        }
        var selectedIndex = assetVC.pageIndex as Int
        
        if selectedIndex == NSNotFound {
            return nil
        }
        
        selectedIndex += 1
        
        if selectedIndex == selectedAlbums.count {
            return nil
        }
        navigationController?.hidesBarsOnTap = true
        return AssetVCIndex(index: selectedIndex)
    }
}


extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
