# logDnaSwift
Wrapper for the LogDNA REST API written in Swift. 

Requirements: you must have alamofire and swiftyjson installed in your project for this to work. 

Usage:
1. Drag and drop this file into your project
2. In your didfinishlaunchingwithoptions initialize the SDK using your Ingestion Key
        `LogDNA.setup(withIngestionKey: "INSERT_INGESTION_KEY", hostName: "looq", appName: "LooqApp", includeNetworkData: true)`
3. Anywhere you want to send a log you can use this code: 
        `LogDNA.log(line: "test message", level: .debug, meta: ["string":"test", "bool":false, "int":3])`
4. If you want to see the return of the API call. You can set verbose to true as follows: `LogDNA.shared.verbose = true`
