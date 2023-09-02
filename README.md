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

## Disclaimer

> VanMoofKit is not an official library of [VanMoof B.V](https://vanmoof.com). This Swift Package makes certain features of the bike accessible which may be illegal to use in certain jurisdictions. As this library hasn't reached an official stable version some features are not yet available or may not working as expected.

## Features

- [x] Establish a bluetooth connection to a VanMoof Bike using async/await
- [x] Easily change the configuration of the bike such as power level, light mode and many more
- [x] Combine support to react to changes of certain functions

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

## How to get a bike

### From VanMoof web api

To initially get a bike, connect to the VanMoof webapi and retrieve the first bike

```swift
let bike = try await Bike(username: "Johnny Mnemonic", password: "swordfish")
```

### Manually from details

If you already have your bike details, e.g. because you have downloaded them earlier from the VanMoof site, you can construct the bike details manually.

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

> **Note**: Make sure that you've got the `bleProfile`, the `macAddress` and the `key` correct, otherwise the connection will not be established. The other parameters are solely flavour text.

### Codable

Bikes implement Codable and thus can be serialized / deserialized should the need arise.

```swift

// store a bike as data
let data = try? JSONEncoder().encode(bike)

// read another bike back from data
let otherBike = JSONDecoder().decode(Bike.self, from: data)
```

## Connection

Connecting a bike is straight forward, just call the `connect` method. 

```swift
try await bike.connect()
```

The bike will stay connected (and in fact automatically re-establish a broken connection) as long as you do not manuall disconnect it.

```swift
bike.disconnect()
```

To retrieve the current connection state, query the bike's `state`:

```swift
let state = bike.state
```

You may also subscribe ot the `statePublisher' and be informed when the current state changes.

```swift
let subscription: AnyCancellable = bike.statePublisher.receive(on: RunLoop.main).sink { state in
    // react to state ...
}

subscription.cancel()
```

> **Note**: Make sure to receive the state changes on the correct thread.

> **Note**: When disconnecting, do not forget to cancel your subscription.

## Getting, observing and setting bike properties

The bike has all kind of properties that represent the current known state of the bike, as:

- `lock` (locked, unlocked)
- `alarm` (on, off, automatic)
- `lighting` (always on, automatic, off)
- `battery level` and `battery state` (charging, discharging and percent charged)
- `module state` (sleeping, off, on)
- `current error code` (raw data, depending on the bike model)
- `motor assistance` (off, one, two, three, four)
- `muted sounds` (wake up sound, shutdown sound, lock sound, unlock sound)
- `speed` (current speed in km/h)
- `distance` (distance in km)
- `region` (eu, us, japan, offroad)
- `unit` (metric, imperial)

> **Note**: if your bike does not support a properity, it will be `nil`.

For each property there is an associated `Publisher` that allows monitoring changes of value.

```swift
let subscription: AnyCancellable = bike.lightingPublisher.receive(on: RunLoop.main).sink { state in
    // do something when lighting changed ...
}

subscription.cancel()
```
> **Note**: Make sure to receive the state changes on the correct thread.

> **Note**: When disconnecting, do not forget to cancel your subscription.

Each property is complemented by a setter:

```swift
try await bike.set(lighting: .alwaysOn)
```

## Other functions

### Play sounds

```swift
try await bike.playSound(.bell, 3) // play the bell sound thrice
```

### Setting backup code

```swift
try await bike.set(backupCode: 123) // sets 123 as new backup code
```

### Waking the bike

Sometimes the bike may not immediately react to configuration changes, because it's smart module is sleeping.
To make sure that your command gets executed even after the bike went to sleep, you can wake it up again.

```swift
try await bike.wakeup()
```

## Credits and inspirations

* [VanMoofKit](https://github.com/SvenTiigi/VanMoofKit)
* [VanBike Library](https://github.com/Poket-Jony/vanbike-lib/tree/main)
* [PyMoof](https://github.com/quantsini/pymoof/tree/main)

## License

MIT License

Copyright (c) 2023 Sebastian Boettcher

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
