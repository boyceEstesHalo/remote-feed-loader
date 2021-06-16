//
//  FeedLoader.swift
//  
//
//  Created by Boyce Estes on 6/16/21.
//

import Foundation


protocol FeedLoader {

    func load(completion: @escaping (Result<[FeedItem], Error>) -> Void)
    // This is an abstraction to handle any error type - sometimes this can complicate the current design so make sure there is a future revisit to clean it up. Its still too early to make a concrete error type right now.
}
