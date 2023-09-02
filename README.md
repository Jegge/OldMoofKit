# OldMoofKit

### A Swift Package to communicate with older VanMoof bikes, such as SmartBike, SmartS/X, Electrified S/X or S/X2

```swift
import OldMoofKit

let bike = try await Bike(username: "Johnny Mnemonic", password: "swordfish") // queries the vanmoof web api
try await bike.connect()
try await bike.set(lock: .unlocked)

// The bike is now connected. It will stay that way until manually disconnected.
// Should the connection drop due to a timeout or the like, it will automatically get restored.

bike.disconnect()
```

## Inspired by

* [VanMoofKit](https://github.com/SvenTiigi/VanMoofKit)
* [VanBike Library](https://github.com/Poket-Jony/vanbike-lib/tree/main)
* [PyMoof](https://github.com/quantsini/pymoof/tree/main)

## Supported bikes

Model           | Supported          | Tested              | Alternatives
:-------------- | :----------------: | :-----------------: | :-------------
SmartBike       | :white_check_mark: |  :x:                | [VanBike Library](https://github.com/Poket-Jony/vanbike-lib/tree/main)
SmartS/X        | :white_check_mark: |  :white_check_mark: | [VanBike Library](https://github.com/Poket-Jony/vanbike-lib/tree/main)
Electrified S/X | :white_check_mark: |  :x:                | [VanBike Library](https://github.com/Poket-Jony/vanbike-lib/tree/main)
S/X 2           | :white_check_mark: |  :white_check_mark: | [VanBike Library](https://github.com/Poket-Jony/vanbike-lib/tree/main)
S/X 3           |  :x:               |  :x:                | [VanMoofKit](https://github.com/SvenTiigi/VanMoofKit), [PyMoof](https://github.com/quantsini/pymoof/tree/main)


## Info.plist

As the VanMoofKit is using the [`CoreBluetooth`](https://developer.apple.com/documentation/corebluetooth) framework to establish a [BLE](https://wikipedia.org/wiki/Bluetooth_Low_Energy) connection to a bike the [`NSBluetoothAlwaysUsageDescription`](https://developer.apple.com/documentation/bundleresources/information_property_list/nsbluetoothalwaysusagedescription) key needs to be added to the Info.plist of your application.

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Establishing a bluetooth connection to your VanMoof Bike.</string>
```

## Connection

### Vanmoof API

To initially get a bike, connect to the VanMoof webapi and retrieve the first bike

```swift
let bike = try await Bike(username: "Johnny Mnemonic", password: "swordfish")
```

### From details

If you already have your bike details, e.G. because you downloaded them earlier from the VanMoof site, you can construct the bike details manually.
Make sure that you've got the `bleProfile`, the `macAddress` and the `key` correct, otherwise the connection will not be established.

```swift
let details = BikeDetails(
    name: "MyCoolBike",
    frameNumber: "ABC123456",
    bleProfile: "SMARTBIKE_2018",
    modelName: "VM01-145-2G",
    macAddress: "12:34:56:78:9A:BC",
    encryptionKey: "1234567890abcdef",
    smartModuleVersion: "1.2.0"
)

let bike = try await Bike(scanningForBikeMatchingDetails: details)
```

### Codable

Bikes implement Codable and thus can be serialized / deserialized should the need arise.

```swift

// write bike

let data = try? JSONEncoder().encode(bike)

// read it back

let otherBike = JSONDecoder().decode(Bike.self, from: data)
```
