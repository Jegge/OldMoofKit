# OldMoofKit

### A Swift Package to communicate with older VanMoof bikes, e.G. SmartBike, SmartS/X, Electrified S/X or S/X2

```swift
import OldMoofKit

let details = BikeDetails(
    name: "MyCoolBike",
    frameNumber: "ABC123456",
    bleProfile: "SMARTBIKE_2018",
    modelName: "VM01-145-2G",
    macAddress: "12:34:56:78:9A:BC",
    key: Data(hexString: "1234567890abcdef")!,
    smartModuleVersion: "1.2.0"
)

let bike = try await Bike(scanningForBikeMatchingDetails: details)

let events = bike.events.receive(on: RunLoop.main).sink { event in
    switch event {
    case .connected:
        bike.set(lock: .unlocked)
        bike.disconnect()
        events.cancel()
        
    default:
        break
    }
}

bike.connect()
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

A connected bike stays connected until you manuall disconnect it. Should the connection drop due to a timeout or the like, it will automatically get restored. To get informed about the current state, subscribe to the `bike.events`.
 
