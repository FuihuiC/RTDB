//
//  RTError.swift
//  RTDatabase
//
//  Created by ENUUI on 2018/6/3.
//

import Foundation

public final class RTError: Error {
    var code: Int
    var msg: String
    init(_ code: Int, _ msg: String) {
        self.code = code
        self.msg = msg
    }
}
