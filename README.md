# ElectrumKit

Make requests to an Electrum Server via Swift.

<img src="https://github.com/FlorianHubl/ElectrumKit/blob/main/ElectrumKitAnimation.gif">

This package supports TCP, TLS, SSL, UDP, DTLS and not tor.
The returning Objects are the same as in the MempoolKit. Also the Electrum Struct conforms to the BlockExplorer protocol, which means you can ether use MempoolKit or ElectrumKit

```swift
var blockexplorer: BlockExplorer = Mempool()
blockexplorer = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp)
```

## Documentation

### Initialise Electrum

```swift
let electrum = Electrum(hostName: "bitcoin.lukechilds.co", port: 50001, using: .tcp)
```

If you want debug logs you can turn set debug to true.

### Version

```swift
let version = try await electrum.version()
```

Returns the version of the Electrum Server in a String.

### Blocktip Height

```swift
let blockTip = try await electrum.getBlockTip()
```

Returns the blockheight of the latest block.

### Transaction

```swift
let tx = try await electrum.transaction(txid: "54b34ca8a627105a1d2a6c0a2224ba3394ca5dcd70ecf62ed43e334129b654d0")
```

Returns the transactions with all the prevouts. If this transaction is huge and has a lot of entries and exits, this method might take a lot of time or even throw an error. If you dont need all the prevouts its way faster:

```swift
let tx = try await electrum.transaction(txid: "54b34ca8a627105a1d2a6c0a2224ba3394ca5dcd70ecf62ed43e334129b654d0", withPrevOut: false)
```

### Send Transaction

```swift
let txid = try await electrum.sendTransaction(hex: transactionHex)
```

Broadcast a raw transaction in hex format.

### Recommended Fees

```swift
let recommendedFees = try await electrum.recommendedFees()
```

Returns the recommended Fees.

### Address Transactions

```swift
let txs = try await electrum.addressTXS(address: "1Ecc7owFDacRgjcm2Vfw17eW2zM5Gjg4SX")
```

Returns all confirmed and unconfirmed transactions from a address.

### Address Mempool Transactions

```swift
let mempoolTX = try await electrum.getMempoolTX(address: "1Ecc7owFDacRgjcm2Vfw17eW2zM5Gjg4SX")
```

Returns all unconfirmed transactions from a address.

### Address UTXOs

```swift
let utxos = try await electrum.addressUTXOs(address: "1Ecc7owFDacRgjcm2Vfw17eW2zM5Gjg4SX")
```

Returns all the UTXOs from an address.

### Transactions Outspends

```swift
let outspends = try await electrum.transactionOutspends(txid: "a00e4ff182014fe854e8278c8ba8d3f25bd564c8e94cdaa746fbfe7c15cc1d6c")
```

Returns which UTXOs in a transaction is spent.
