//
//  ImageCache.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 8/10/25.
//

import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 500
        cache.totalCostLimit = 80 * 1024 * 1024 
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String, cost: Int? = nil) {
        if let cost { cache.setObject(image, forKey: key as NSString, cost: cost) }
        else { cache.setObject(image, forKey: key as NSString) }
    }

    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
