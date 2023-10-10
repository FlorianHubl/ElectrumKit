import Foundation

public struct ElectrumTransaction: Codable {
    public let txid, hash: String
    public let version, size, vsize, weight: Int
    public let locktime: Int
    public let vin: [Vin]
    public let vout: [Vout]
    public let hex: String
    public let blockhash: String?
    public let confirmations, time, blocktime: Int?
    
    public struct Vin: Codable {
        public let coinbase: String?
        public let txid: String?
        public let vout: Int?
        public let scriptSig: ScriptSig?
        public let txinwitness: [String]?
        public let sequence: Int
    }
    
    public struct ScriptSig: Codable {
        public let asm, hex: String
    }
    
    public struct Vout: Codable {
        public let value: Double
        public let n: Int
        public let scriptPubKey: ScriptPubKey
    }
    
    public struct ScriptPubKey: Codable {
        public let asm, desc, hex: String
        public let address: String?
        public let type: ScriptPubKeyType
    }
    
    public enum ScriptPubKeyType: String, Codable {
        case witness_v0_keyhash
        case witness_v1_taproot
        case witness_v0_scripthash
        case pubkeyhash
        case scripthash
        case nulldata
    }
}

public struct ElectrumBlock: Codable {
    public let header: String
    public let branch: [String]
    public let root: String
}

public struct ElectrumTip: Codable {
    public let hex: String
    public let height: Int
}

public struct ElectrumAddressTX: Codable {
    public let tx_hash: String
    public let height: Int
    
    enum CodingKeys: String, CodingKey {
        case tx_hash
        case height
    }
}

typealias ElectrumAddressTXs = [ElectrumAddressTX]

public struct ElectrumUTXO: Codable {
    public let tx_hash: String
    public let tx_pos, height, value: Int
    
    enum CodingKeys: String, CodingKey {
        case tx_hash
        case tx_pos
        case height, value
    }
}

typealias ElectrumUTXOs = [ElectrumUTXO]
