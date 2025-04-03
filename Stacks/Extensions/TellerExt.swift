//
//  TellerExt.swift
//  Stacks
//
//  Created by Zach Hofmeister on 4/3/25.
//

import Foundation
import TellerKit

extension Teller.Authorization : @retroactive Encodable {
    enum CodingKeys: CodingKey {
        case accessToken, enrollment, signatures
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(enrollment, forKey: .enrollment)
        try container.encode(signatures, forKey: .signatures)
    }
}

extension Teller.Enrollment : @retroactive Encodable {
    enum CodingKeys: CodingKey {
        case id, institution
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(institution, forKey: .institution)
    }
}

extension Teller.Institution : @retroactive Encodable {
    enum CodingKeys: CodingKey {
        case name
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}
