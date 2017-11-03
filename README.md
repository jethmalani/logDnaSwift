# logDnaSwift
Wrapper for the LogDNA REST API written in Swift. 

Requirements: you must have alamofire and swiftyjson installed in your project for this to work. 

Usage:
1. Drag and drop this file into your project
2. In your didfinishlaunchingwithoptions initialize the SDK using your Ingestion Key
        `LogDNA.setup(withIngestionKey: "d250c4933fba49b4a003189a578e8a4d", hostName: "looq", appName: "TradingGdax", includeNetworkData: true)`
3. Anywhere you want to send a log you can use this code. 
        `LogDNA.log(line: "test message", level: .debug, meta: ["string":"test", "bool":false, "int":3])`

        
