//
//  HTTPClient.swift
//  
//
//  Created by Boyce Estes on 6/30/21.
//

import Foundation

public protocol HTTPClient {

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}


public enum HTTPClientResult {

    case success(Data, HTTPURLResponse)
    case failure(Error)
}
