//
//  ViewImagesCell.swift
//  CustomCamera
//
//  Created by Yudiz-subhranshu on 12/10/23.
//

import UIKit

class ViewImagesCell: UICollectionViewCell , UIScrollViewDelegate{

    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var imageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
        doubleTapZoom()
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    func doubleTapZoom() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTab))
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
        scrollView.isUserInteractionEnabled = true
        imageView.isUserInteractionEnabled = true
    }
    @objc func handleTab(_ gesture: UITapGestureRecognizer){
        if scrollView.zoomScale == 1 {
            let scale = gesture.location(in: imageView)
            let rect = CGRect(x: scale.x, y: scale.y, width: 1, height: 1)
            scrollView.zoom(to: rect, animated: true)
        }else {
            scrollView.setZoomScale(1, animated: true)
        }
    }

}
