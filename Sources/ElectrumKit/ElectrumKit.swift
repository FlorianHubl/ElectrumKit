
import Foundation
import Network
import EasyTCP
import MempoolKit
import CryptoKit
import LibWally
import SwiftUI

@available(iOS 13.0, *)
public struct Electrum: BlockExplorer {
    public func transactionOutspends(txid: String) async throws -> MempoolKit.TransactionOutspends {
        var outspends = MempoolKit.TransactionOutspends()
        let tx = try await self.transaction(txid: txid)
    Main: for vout in tx.vout {
            //            let txs = try await addressTXS(address: address)
            //            var spend = false
            //            var vin = 0
            //            var status: MempoolKit.TransactionOutspend.Status? = nil
            //            var txid = ""
            //        Loop: for tx in txs {
            //            for input in tx.vin {
            //                if input.prevout!.scriptpubkey_address! == address {
            //                    spend = true
            //                    vin = input.vout
            //                    txid = tx.txid
            //                    status = MempoolKit.TransactionOutspend.Status(confirmed: tx.status.confirmed, block_height: tx.status.block_height!, block_hash: tx.status.block_hash!, block_time: tx.status.block_time!)
            //                    break Loop
            //                }
            //            }
            let utxos = try await addressUTXOs(address: vout.scriptpubkey_address!)
            for utxo in utxos {
                if utxo.txid == txid && utxo.value == vout.value {
                    // UTXO unspent
                    print("UTXO unspend: \(utxo.txid): \(utxo.value)")
                    outspends.append(MempoolKit.TransactionOutspend(spent: false, txid: nil, vin: nil, status: nil))
                    continue Main
                }
            }
            
            // UTXO spent
//        outspends.append(MempoolKit.TransactionOutspend(spent: true, txid: nil, vin: nil, status: nil))
            
            let txs = try await addressTXS(address: vout.scriptpubkey_address!, withPrevOuts: false)
        Loop: for tx in txs {
            for input in tx.vin {
                if input.txid == txid {
                    let status = MempoolKit.TransactionOutspend.Status(confirmed: tx.status.confirmed, block_height: tx.status.block_height!, block_hash: tx.status.block_hash!, block_time: tx.status.block_time!)
                    outspends.append(TransactionOutspend(spent: true, txid: tx.txid, vin: input.vout, status: status))
                    break Loop
                }
            }
        }
        }
        
        
//            if spend {
//                outspends.append(MempoolKit.TransactionOutspend(spent: true, txid: txid, vin: vin, status: status!))
//            }else {
//                outspends.append(MempoolKit.TransactionOutspend(spent: false, txid: nil, vin: nil, status: nil))
//            }
        return outspends
    }
    
    public func testConnection() -> Bool {
        tcp.connection.state == .ready
    }
    
    
    public func addressUTXOs(address: String) async throws -> MempoolKit.UTXOs {
        
        let adr = convertToElectrumAddress(address: address)
        
        let electrumUtxos = try await tcp.sendJsonRpc(input: ElectrumCall(method: .addressUTXOsRequest, params: [adr]), output: ElectrumResult<ElectrumUTXOs>.self).result

        var utxos = MempoolKit.UTXOs()

        for u in electrumUtxos {
            var s = MempoolKit.UTXO.Status(confirmed: false, block_height: nil, block_hash: nil, block_time: nil)
            if u.height > 0 {
                let tx = try await transaction(txid: u.tx_hash)
                s = UTXO.Status(confirmed: true, block_height: tx.status.block_height, block_hash: tx.status.block_hash!, block_time: tx.status.block_time!)
            }
            let utxo = UTXO(txid: u.tx_hash, vout: u.tx_pos, status: s, value: u.value)
            utxos.append(utxo)
        }

        return utxos
    }
    
    func getMempoolTX(address: String) async throws -> MempoolKit.Transactions {
        
        let adr = convertToElectrumAddress(address: address)
        
        let txs = try await tcp.sendJsonRpc(input: ElectrumCall(method: .addressMempoolTXsRequest, params: [adr]), output: ElectrumResult<ElectrumAddressTXs>.self).result
        
        let a = txs.map { i in
            i.tx_hash
        }
        
        var transactions = MempoolKit.Transactions()
        
        for i in a {
            do {
                let tx = try await self.transaction(txid: i)
                transactions.append(tx)
            }catch {
                print("error in \(i)")
            }
        }
        return transactions
    }
    
    public func sha256(_ data: Data) -> Data {
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }
    
    func convertToElectrumAddress(address: String) -> String {
        print("convertToElectrumAddress: \(address)")
        let a = LibWally.Address(address)!
        let b = a.scriptPubKey.bytes
        let hash = sha256(b)
        let reversed = Data(hash.reversed())
        let hex = reversed.hexString
        return hex
    }
    
    public func addressTXS(address: String) async throws -> MempoolKit.Transactions {
        return try await addressTXS(address: address, withPrevOuts: true)
    }
    
    /// Transactions from an Address
    /// - Parameter address: The Bitcoin Address
    /// - Returns: The confirmed and mempool Transactions from this address
    public func addressTXS(address: String, withPrevOuts: Bool? = nil) async throws -> MempoolKit.Transactions {
        
        let adr = convertToElectrumAddress(address: address)
        
        let txs = try await tcp.sendJsonRpc(input: ElectrumCall(method: .addressTXsRequest, params: [adr]), output: ElectrumResult<ElectrumAddressTXs>.self).result
        let a = txs.map { i in
            i.tx_hash
        }
        
        var transactions = MempoolKit.Transactions()
        
        for i in a {
            do {
                let tx = try await self.transaction(txid: i, withPrevOut: withPrevOuts)
                transactions.append(tx)
            }catch {
                print("error in \(i)")
            }
        }
        
        let mempoolTXs = try await self.getMempoolTX(address: address)
        print("MempoolTXs for \(address) -> \(mempoolTXs.count)")
        
        transactions.append(contentsOf: mempoolTXs)
        
        return transactions
    }
    
    private func convertScriptPubKey(key: ElectrumTransaction.ScriptPubKeyType) -> MempoolKit.Transaction.ScriptpubkeyType {
        switch key {
        case .witness_v0_keyhash:
            return .v0_p2wpkh
        case .witness_v1_taproot:
            return .v1_p2tr
        case .witness_v0_scripthash:
            return .v0_p2wsh
        case .pubkeyhash:
            return .p2pk
        case .scripthash:
            return .p2sh
        case .nulldata:
            return .op_return
        }
    }
    
    private func bitcoinToSats(btc: Double) -> Int {
        Int((btc * 100000000.0).rounded())
    }
    
    func getBlockTip() async throws -> Int {
        let b = [String]()
        let a = try await tcp.sendJsonRpc(input: ElectrumCall(method: .blocktip, params: b), output: ElectrumResult<ElectrumTip>.self).result
        return a.height
    }
    
    public func transaction(txid: String) async throws -> MempoolKit.Transaction {
        return try await transaction(txid: txid, withPrevOut: true)
    }
    
    public func transaction(txid: String, withPrevOut: Bool? = nil) async throws -> MempoolKit.Transaction {
        
        let withPrevOut = withPrevOut ?? true
        
        let data = try await tcp.send(line: "{\"jsonrpc\": \"2.0\", \"method\": \"blockchain.transaction.get\", \"params\": [\"\(txid)\", true], \"id\": 1}")
        print("First Done")
        let tx = try JSONDecoder().decode(ElectrumResult<ElectrumTransaction>.self, from: data).result
        
        var inputs = [MempoolKit.Transaction.Vin]()

        var fee = 0

        for vin in tx.vin {
            print("vin: \(vin.txid!)")
            if withPrevOut {
                let data = try await tcp.send(line: "{\"jsonrpc\": \"2.0\", \"method\": \"blockchain.transaction.get\", \"params\": [\"\(vin.txid!)\", true], \"id\": 1}")
                let tx2 = try JSONDecoder().decode(ElectrumResult<ElectrumTransaction>.self, from: data).result
                
                var prev: MempoolKit.Transaction.Vout? = nil
                
                if let v = vin.vout {
                    let prevout = tx2.vout[v]
                    let a = MempoolKit.Transaction.Vout(scriptpubkey: prevout.scriptPubKey.hex, scriptpubkey_asm: prevout.scriptPubKey.asm, scriptpubkey_type: convertScriptPubKey(key: prevout.scriptPubKey.type), scriptpubkey_address: prevout.scriptPubKey.address, value: bitcoinToSats(btc: prevout.value))
                    fee += bitcoinToSats(btc: prevout.value)
                    prev = a
                }
                
                let input = MempoolKit.Transaction.Vin(txid: vin.txid!, vout: vin.vout!, prevout: prev, scriptsig: vin.scriptSig!.hex, scriptsig_asm: vin.scriptSig!.asm, witness: vin.txinwitness, is_coinbase: vin.coinbase == nil, sequence: vin.sequence, inner_redeemscript_asm: nil, inner_witnessscript_asm: nil)
                inputs.append(input)
            }else {
                if vin.vout != nil {
                    let input = MempoolKit.Transaction.Vin(txid: vin.txid!, vout: vin.vout!, prevout: nil, scriptsig: vin.scriptSig!.hex, scriptsig_asm: vin.scriptSig!.asm, witness: vin.txinwitness, is_coinbase: vin.coinbase == nil, sequence: vin.sequence, inner_redeemscript_asm: nil, inner_witnessscript_asm: nil)
                    inputs.append(input)
                }
            }
        }

        var outputs = [MempoolKit.Transaction.Vout]()

        for vout in tx.vout {
            let output = MempoolKit.Transaction.Vout(scriptpubkey: vout.scriptPubKey.hex, scriptpubkey_asm: vout.scriptPubKey.asm, scriptpubkey_type: convertScriptPubKey(key: vout.scriptPubKey.type), scriptpubkey_address: vout.scriptPubKey.address, value: bitcoinToSats(btc: vout.value))
            fee -= bitcoinToSats(btc: vout.value)
            outputs.append(output)
        }

        var status = MempoolKit.Transaction.Status(confirmed: false)
        
        if let confirmations = tx.confirmations {
            let tip = try await getBlockTip()
            status = MempoolKit.Transaction.Status(confirmed: true, block_height: tip - confirmations + 1, block_hash: tx.blockhash!, block_time: tx.blocktime!)
        }
        
        let transaction = MempoolKit.Transaction(txid: tx.txid, version: tx.version, locktime: tx.locktime, vin: inputs, vout: outputs, size: tx.size, weight: tx.weight, fee: fee, status: status)
        return transaction
    }
    
    public func sendTransaction(hex: String) async throws -> String {
        return try await tcp.sendJsonRpc(input: ElectrumCall(method: .broadcast, params: [hex]), output: ElectrumResult<String>.self).result
    }
    
    public func recommendedFees() async throws -> MempoolKit.RecommendedFees {
        let fastestFee = try await tcp.sendJsonRpc(input: ElectrumCall(method: .estimateFee, params: [1]), output: ElectrumResult<Double>.self).result * 100000
        let fastFee = try await tcp.sendJsonRpc(input: ElectrumCall(method: .estimateFee, params: [2]), output: ElectrumResult<Double>.self).result * 100000
        let middleFee = try await tcp.sendJsonRpc(input: ElectrumCall(method: .estimateFee, params: [3]), output: ElectrumResult<Double>.self).result * 100000
        let slowFee = try await tcp.sendJsonRpc(input: ElectrumCall(method: .estimateFee, params: [7]), output: ElectrumResult<Double>.self).result * 100000
        let slowestFee = try await tcp.sendJsonRpc(input: ElectrumCall(method: .estimateFee, params: [25]), output: ElectrumResult<Double>.self).result * 100000
        return RecommendedFees(fastestFee: fastestFee, halfHourFee: fastFee, hourFee: middleFee, economyFee: slowFee, minimumFee: slowestFee)
    }
    
    public func version() async throws -> String {
        let a = try await tcp.sendJsonRpc(input: ElectrumCall(method: .version, params: ["", "1.4"]), output: ElectrumResult<[String]>.self)
        guard let f = a.result.first else {
            throw ElectrumError.noResult
        }
        return f
    }
    
    enum ElectrumError: Error {
        case noResult
        case blockHashNotFound
    }

    public let tcp: EasyTCP
    
    public init(hostName: String, port: Int, using connection: NWParameters, debug: Bool? = nil) {
        self.tcp = EasyTCP(hostName: hostName, port: port, using: connection, lastLetters: ": 1}", debug: debug ?? false)
        tcp.start()
    }
}

enum ElectrumMethods: String, Codable {
    case version = "server.version" // "", "1.4"
    case broadcast = "blockchain.transaction.broadcast" // "hex"
    case estimateFee = "blockchain.estimatefee" // Blockint
    case blockHeader = "blockchain.block.header" // Blockheight, Blockheight
    case transactionRequest = "blockchain.transaction.get" // "txid", true
    case addressUTXOsRequest = "blockchain.scripthash.listunspent" // "hex"
    case addressTXsRequest = "blockchain.scripthash.get_history" // "hex"
    case addressMempoolTXsRequest = "blockchain.scripthash.get_mempool" // "txid"
    case blocktip = "blockchain.headers.subscribe"
}


struct ElectrumResult<T: Codable>: Codable {
    var jsonrpc: String
    var id: Int
    var result: T
}

struct ElectrumCall<T: Codable>: Codable {
    var jsonrpc = "2.0"
    var method: ElectrumMethods
    var params: T
    var id = 1
}

extension Data {
    var str: String {
        return String(data: self, encoding: .utf8)!
    }
}

