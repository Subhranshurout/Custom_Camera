//
//  CompositionalLayout.swift
//  CustomCamera
//
//  Created by Yudiz-subhranshu on 12/10/23.
//

import Foundation
import UIKit

enum GroupType {
    case horizontal
    case vertical
}

struct CompositionalLayout {
    //Method to creating an item
    static func createItem (width : NSCollectionLayoutDimension , height : NSCollectionLayoutDimension, spacing : CGFloat) -> NSCollectionLayoutItem {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: width,heightDimension: height))
        item.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing) // For Padding
        return item
    }
    //Method to create a group using multiple items
    static func createGroup (width : NSCollectionLayoutDimension , height : NSCollectionLayoutDimension , groupType : GroupType,items : [NSCollectionLayoutItem]) -> NSCollectionLayoutGroup{
        ///For switching between horizontal and vertical group
        switch groupType {
        case .horizontal:
            return NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: width, heightDimension: height), subitems: items)
        case .vertical:
            return NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: width, heightDimension: height), subitems: items)
        }
    }
    //Method to create a group using a single item and using that item multiple times
    @available(iOS 16.0, *)
    static func createGroup (width : NSCollectionLayoutDimension , height : NSCollectionLayoutDimension , groupType : GroupType , count :Int, item : NSCollectionLayoutItem) -> NSCollectionLayoutGroup{
        ///For switching between horizontal and vertical group
        switch groupType {
        case .horizontal:
            return NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: width, heightDimension: height), repeatingSubitem: item, count: count)
        case .vertical:
            return NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: width, heightDimension: height), repeatingSubitem: item, count: count)
        }
    }
}
