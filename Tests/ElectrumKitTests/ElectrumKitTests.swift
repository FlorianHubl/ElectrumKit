import XCTest
import MempoolKit
import SwiftTor
@testable import ElectrumKit

final class ElectrumKitTests: XCTestCase {
    
    @available(iOS 13.0.0, *)
    func testVersion() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let version = try await electrum.version()
        print(version)
    }
    
    @available(iOS 13.0.0, *)
    func testBlockTip() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let blockTip = try await electrum.getBlockTip()
        print(blockTip)
    }
    
    @available(iOS 13.0.0, *)
    func testTransaction() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let tx = try await electrum.transaction(txid: "54b34ca8a627105a1d2a6c0a2224ba3394ca5dcd70ecf62ed43e334129b654d0")
        let tx2 = try await electrum.transaction(txid: "54b34ca8a627105a1d2a6c0a2224ba3394ca5dcd70ecf62ed43e334129b654d0", withPrevOut: false)
    }
    
    @available(iOS 13.0.0, *)
    func testSendTransaction() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let transactionHex = "010000000181eaf9abd3d7ccde4dd3f48ef874a5269d98b9d3e55d60e1a8d4c1452d8ed2cc010000008b483045022100b6da37ea2d80b01c7b1391dc476cbd99501d6598d8127aa76ca52d3b151ba4b902205354455ca61c7449ba7114a406bc724bf4e4b159ef25812723bedc00cbad1440014104f54ca9535bc2dedb2fa3e1a43def36d0fb455148f43531341402b991bee5cac923eb4b4598bc7bfec39f4dc1e098cbf4ae2e693413793f9ec988e400eaaf7216ffffffff0160f59000000000001976a91495558225487ea9855d9f8e483373ed2cf5e32bbc88ac00000000"
//        let tx = try await electrum.sendTransaction(hex: transactionHex)
    }
    
    @available(iOS 13.0.0, *)
    func testTecommendedFees() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let recommendedFees = try await electrum.recommendedFees()
    }
    
    @available(iOS 13.0.0, *)
    func testAddressTXS() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let txs = try await electrum.addressTXS(address: "1Ecc7owFDacRgjcm2Vfw17eW2zM5Gjg4SX")
        print(txs.count)
    }
    
    @available(iOS 13.0.0, *)
    func testGetMempoolTX() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let mempoolTX = try await electrum.getMempoolTX(address: "1Ecc7owFDacRgjcm2Vfw17eW2zM5Gjg4SX")
    }
    
    @available(iOS 13.0.0, *)
    func testAddressUTXOs() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let utxos = try await electrum.addressUTXOs(address: "1Ecc7owFDacRgjcm2Vfw17eW2zM5Gjg4SX")
    }
    
    @available(iOS 13.0.0, *)
    func testTransactionOutspends() async throws {
        let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
        let outspends = try await electrum.transactionOutspends(txid: "a00e4ff182014fe854e8278c8ba8d3f25bd564c8e94cdaa746fbfe7c15cc1d6c")
    }
    
    @available(iOS 13.0.0, *)
    func testBlockExplorer() async throws {
        var blockexplorer: BlockExplorer = Mempool()
        blockexplorer = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp, debug: true)
    }
    
}

extension String: Error {
    
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}


