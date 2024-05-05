[![Tested on GitHub Actions](https://github.com/Jegge/OldMoofKit/actions/workflows/swift.yml/badge.svg)](https://github.com/Jegge/OldMoofKit/actions/workflows/swift.yml)
[![](https://www.codefactor.io/repository/github/Jegge/OldMoofKit/badge)](https://www.codefactor.io/repository/github/Jegge/OldMoofKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FJegge%2FOldMoofKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Jegge/OldMoofKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FJegge%2FOldMoofKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Jegge/OldMoofKit)
![GitHub](https://img.shields.io/github/license/Jegge/OldMoofKit)
![GitHub issues](https://img.shields.io/github/issues/Jegge/OldMoofKit)
![Static Badge](https://img.shields.io/badge/Supported%20Bikes-SmartBike%20%7C%20SmartS%2FX%20%7C%20Electrified%20S%2FX%20%7C%20S%2FX%202-blue)
![Mastodon Follow](https://img.shields.io/mastodon/follow/108202548777940296?domain=https%3A%2F%2Fchaos.social)


# OldMoofKit

### A Swift Package to communicate with older VanMoof bikes, such as SmartBike, SmartS/X, Electrified S/X or S/X2

```swift
import OldMoofKit

let bike = try await Bike(username: "Johnny Mnemonic", password: "swordfish") // queries the vanmoof web api
try await bike.connect()
try await bike.playSound(.bell)
try await bike.set(lock: .unlocked)
bike.disconnect()
```

## Disclaimer

> OldMoofKit is not an official library of [VanMoof B.V](https://vanmoof.com). This Swift Package hasn't reached an official stable version, so some features may not work as expected. You use this library solely at your own risk.

## Features

- [x] Establish a bluetooth connection to a VanMoof Bike using async/await
- [x] Lock or unlock your bike
- [x] Change the bike settings: light, motor assistance, ...
- [x] Combine support to react to value changes

## Supported bikes

Model           | Supported          | Tested              | Alternatives
:-------------- | :----------------: | :-----------------: | :-------------
SmartBike       | :white_check_mark: |  :x:                | [vanbike-lib](https://github.com/Poket-Jony/vanbike-lib/tree/main)
SmartS/X        | :white_check_mark: |  :white_check_mark: | [vanbike-lib](https://github.com/Poket-Jony/vanbike-lib/tree/main)
Electrified S/X | :white_check_mark: |  :x:                | [vanbike-lib](https://github.com/Poket-Jony/vanbike-lib/tree/main)
S/X 2           | :white_check_mark: |  :white_check_mark: | [vanbike-lib](https://github.com/Poket-Jony/vanbike-lib/tree/main)
S/X 3           | :x:                |  :x:                | [VanMoofKit](https://github.com/SvenTiigi/VanMoofKit), [PyMoof](https://github.com/quantsini/pymoof/tree/main)

*Not tested* means that it should work in theory, but since I could not lay may hands on such a bike this is a bit of an uncharted territory. Should you own a SmartBike or a Electified S/X I would appreciate if you could confirm that OldMoofKit works, or else help me debug the issue.

## Installation

### Swift Package Manager

To integrate using Apple's [Swift Package Manager](https://swift.org/package-manager/), add the following as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Jegge/OldMoofKit.git", from: "0.0.3")
]
```

Or navigate to your Xcode project then select `Swift Packages`, click the “+” icon and search for `OldMoofKit`.

### Info.plist

As the OldMoofKit is using the [`CoreBluetooth`](https://developer.apple.com/documentation/corebluetooth) framework to establish a [BLE](https://wikipedia.org/wiki/Bluetooth_Low_Energy) connection to a bike the [`NSBluetoothAlwaysUsageDescription`](https://developer.apple.com/documentation/bundleresources/information_property_list/nsbluetoothalwaysusagedescription) key needs to be added to the Info.plist of your application.

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Establishing a bluetooth connection to your VanMoof Bike.</string>
```

## How to get a bike

### From VanMoof web api

To initially get a bike, connect to the VanMoof web api and retrieve the first bike.

```swift
let bike = try await Bike(username: "Johnny Mnemonic", password: "swordfish")
```

If you own several bikes, you need to download the details separately. You may then scan your surroundings via bluetooth for a bike matching these details.

```swift
var api = VanMoof(apiUrl: VanMoof.Api.url, apiKey: VanMoof.Api.key)
try await api.authenticate(username: "Johnny Mnemonic", password: "swordfish")
let allDetails = try await api.bikeDetails()
let details = allDetails.first! // select one element from allDetails
let bike = try await Bike(scanningForBikeMatchingDetails: details)
```

### Manually from details

If you already have your bike details, e.g. because you have downloaded them earlier from the VanMoof site, you can construct the bike details manually. You may then scan your surroundings via bluetooth for a bike matching these details.

```swift
let details = try BikeDetails(bleProfile: .smartbike2016, macAddress: "12:34:56:78:9A:BC", encryptionKey: "00112233445566778899aabbccddeeff")
let bike = try await Bike(scanningForBikeMatchingDetails: details)
```

> **Note**: Make sure that you've got the `bleProfile`, the `macAddress` and the `encryptionKey` correct, otherwise the connection will not be established. The other parameters are solely flavour text.

> **Note**: The MAC address has to be entered in MAC-48 format.

> **Note**: The encryption key has to be exactely 16 bytes long and has to be entered as hex string.

### Codable

Bikes implements [`Codable`](https://developer.apple.com/documentation/swift/codable?changes=_4) and thus can be serialized / deserialized should the need arise.

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

The bike will stay connected (and in fact automatically re-establish a broken connection) as long as you do not manually disconnect it.

```swift
bike.disconnect()
```

To retrieve the current connection state, query the bike's `state`:

```swift
let state = bike.state
switch state {
    case .connected:
        // do something when connection get (re-)established
    case .disconnected:
        // do something when connection drops or closes
}
```

You may also subscribe to the `statePublisher` and be informed when the current state changes.

```swift
let subscription: AnyCancellable = bike.statePublisher.receive(on: RunLoop.main).sink { state in
    // react to state ...
}

subscription.cancel()
```

> **Note**: Make sure to receive the state changes on the correct thread.

> **Note**: When disconnecting, do not forget to cancel your subscription.

## Errors

The bike has a dedicated `errorPublisher`, that you can subscribe to to get error messages.

```swift
let subscription: AnyCancellable = bike.errorPublisher.receive(on: RunLoop.main).sink { error in
    // react to the error
    print("Error: \(error))
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
- `batteryLevel` and `batteryState` (percent charged and charging or discharching)
- `moduleState` (sleeping, off, on)
- `errorCode` (raw data, depending on the bike model)
- `motorAssistance` (off, one, two, three, four)
- `mutedSounds` (wake up sound, shutdown sound, lock sound, unlock sound)
- `speed` (current speed in km/h)
- `distance` (distance in km)
- `region` (eu, us, japan, offroad)
- `unit` (metric, imperial)

```swift
let lighting = bike.lighting
```

> **Note**: if your bike does not support a properity, it's value will be `nil`.

For each property there is an associated `Publisher` that allows monitoring changes of value.

```swift
let subscription: AnyCancellable = bike.lightingPublisher.receive(on: RunLoop.main).sink { state in
    // do something when lighting changed ...
}

subscription.cancel()
```
> **Note**: Make sure to receive the state changes on the correct thread.

> **Note**: When disconnecting, do not forget to cancel your subscription.

Each property is complemented by a setter. Calling this setter transmits the value directly to the bike. The bike then will send a notification and the
according property will get updated upon receiving that notification. If your bike does not support a property, calling the setter will be ignored.

```swift
try await bike.set(lighting: .alwaysOn)
```

> **Note**: setting the region of your e-bike to a value not corresponding to your country may be illegal in some jurisdictions. Use at your own risk.

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
When ``wakeup`` returns, the command has been sent to the bike. It may still be on ``.standby`` at this moment. 
To be sure that the bike is awake, consider listening the the ``moduleStatePublisher``.

```swift
try await bike.wakeup()
```

## Credits and inspirations

* [VanMoofKit](https://github.com/SvenTiigi/VanMoofKit)
* [vanbike-lib](https://github.com/Poket-Jony/vanbike-lib/tree/main)
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
