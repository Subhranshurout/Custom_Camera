//
//  ViewImagesVC.swift
//  CustomCamera
//
//  Created by Yudiz-subhranshu on 12/10/23.
//

import UIKit

class ViewImagesVC: UIViewController {

    @IBOutlet var viewImagesCollection: UICollectionView!
    
//    @IBOutlet var navigationBar: UINavigationBar!
//    @IBOutlet var navigationBackBtn: UIBarButtonItem!
    var images = [UIImage]()
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationItem.title = "Gallery"
//        navigationBar.layer.name = "gr"

//        viewImagesCollection.collectionViewLayout = compositionalLayout()
        viewImagesCollection.register(UINib(nibName: "ViewImagesCell", bundle: nil), forCellWithReuseIdentifier: "ViewImagesCell")
    }
    
//    @IBAction func navigationbackBtnClick(_ sender: UIBarButtonItem) {
//        navigationController?.popViewController(animated: true)
//    }
    
//    func compositionalLayout () -> UICollectionViewCompositionalLayout {
//        let item = CompositionalLayout.createItem(width: .fractionalWidth(1), height: .fractionalHeight(1), spacing: 0)
//        let group = CompositionalLayout.createGroup(width: .fractionalWidth(1), height: .fractionalHeight(1), groupType: .horizontal, items: [item])
//        let section = NSCollectionLayoutSection(group: group)
//        section.orthogonalScrollingBehavior = .groupPaging
//        return UICollectionViewCompositionalLayout(section: section)
//    }
}

extension ViewImagesVC : UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = viewImagesCollection.dequeueReusableCell(withReuseIdentifier: "ViewImagesCell", for: indexPath) as! ViewImagesCell
        cell.imageView.image = images[indexPath.row]
        cell.scrollView.setZoomScale(1.0, animated: true)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ViewImagesCell
        cell.scrollView.setZoomScale(1.0, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! ViewImagesCell
        cell.scrollView.setZoomScale(1.0, animated: true)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSizeMake(collectionView.frame.size.width, collectionView.frame.size.height)
    }
    
}
