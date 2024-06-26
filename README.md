# How to route navigation apps right for fleet and logistics vehicles
A sample project demonstrating how to create vehicle-specific routes using TomTom Maps &amp; Navigation SDKs. https://developer.tomtom.com

## Environment Setup

This project uses version 0.52.0 of the TomTom Maps and Navigation SDK. For more details, visit the [TomTom SDK release notes](https://developer.tomtom.com/navigation/ios/releases/versions/0.52).

### Requirements
- **iOS 17**
  - Ensure your development device is running iOS 17 or later.
  - The project targets iOS 17, so please update your device accordingly if necessary.
- **Xcode 15**
  - Download and install Xcode 15 from the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12) or the [Apple Developer site](https://developer.apple.com/xcode/).
  - Make sure Xcode 15 is set as the default Xcode version on your machine.
### Additional Setup
1. **Clone the Repository**
   ```bash
   git clone https://github.com/tnrvrd/tomtom-navigation-sdk-truck-specific-route-example
   cd tomtom-navigation-sdk-truck-specific-route-example
2. **Install Dependencies**
    - Open the project in Xcode 15.
    - Navigate to the File menu, select Packages, and then Update to Latest Package Versions to install all required Swift packages.
3. **Configure API Keys**
    - Obtain an API key from [TomTom developer portal](https://developer.tomtom.com).
    - Replace the placeholder API key in Keys.swift with your own API key:
        ```swift
        // Keys.swift
        enum Keys {
            static let ttAPIKey = "YOUR_API_KEY"
        }
4. **Build and Run**
    - Select your target device or simulator.
    - Click the Run button (or press Cmd + R) to build and run the project on your selected device.
## Troubleshooting
- If you encounter issues with Xcode 15 or iOS 17.0.1, refer to the official [Apple Developer Documentation](https://developer.apple.com/documentation/) for support and troubleshooting tips.
- Ensure all dependencies are up to date and correctly configured as per the instructions above.