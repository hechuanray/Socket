//
//  FileDescriptor.swift
//  Socket
//
//  Created by LEI on 3/21/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

typealias FileDescriptorRawType = Int32

protocol FileDescriptorType: NilLiteralConvertible {
    var raw: FileDescriptorRawType { get }
    init(_ raw: FileDescriptorRawType)
}

struct FileDescriptor: FileDescriptorType {
    
    var raw: FileDescriptorRawType
    
    init(_ raw: FileDescriptorRawType) {
        self.raw = raw
    }
    
    init(nilLiteral: ()) {
        self.init(Int32(-1))
    }
    
}