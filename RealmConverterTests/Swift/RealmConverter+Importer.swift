////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import XCTest
import Realm
import RealmConverter
import PathKit

@testable import RealmConverter

class RealmConverter_Importer: XCTestCase {
    
    let outputTestFolderName = "io.realm.test-output"
    let inputTestFolderName = "io.realm.test-input"
    
    var outputTestFolderPath: String {
        var path = Path(NSTemporaryDirectory())
        path = path + Path(outputTestFolderName)
        return String(path)
    }
    
    var inputTestFolderPath: String {
        var path = Path(NSTemporaryDirectory())
        path = path + Path(inputTestFolderName)
        return String(path)
    }
    
    let testRealmFileName = "businesses.realm"
    let csvAssetNames = ["businesses"]

    var bundle: NSBundle {
        return NSBundle(forClass: self.dynamicType)
    }
    
    override func setUp() {
        super.setUp()
        
        // Create the input and output folders
        for path in [self.inputTestFolderPath, self.outputTestFolderPath] {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                try! NSFileManager.defaultManager().removeItemAtPath(path)
            }
        }
        
        // Create the input and output folders
        for path in [self.inputTestFolderPath, self.outputTestFolderPath] {
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Copy our CSV test data to the input folder
        for fileName in self.csvAssetNames {
            let filePath = bundle.pathForResource(fileName, ofType: "csv")
            let destinationPath = Path(self.inputTestFolderPath) + Path(filePath!).lastComponent
            
            if NSFileManager.defaultManager().fileExistsAtPath(String(destinationPath)) == false {
                try! NSFileManager.defaultManager().copyItemAtPath(filePath!, toPath: String(destinationPath))
            }
        }
    }
    
    func testCSVImport() {
        var filePaths = [String]()
        
        let folderContents = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.inputTestFolderPath)
        for file in folderContents {
            let filePath = Path(self.inputTestFolderPath) + Path(file)
            filePaths.append(String(filePath))
        }
        
        let generator =  ImportSchemaGenerator(files: filePaths)
        let schema = try! generator.generate()
        
        let destinationRealmPath = Path(self.outputTestFolderPath)
        let dataImporter = CSVDataImporter(files: filePaths)
        try! dataImporter.importToPath(String(destinationRealmPath), schema: schema)
        
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(String(destinationRealmPath)))
    }

    func testJSONImport() {
        let filePaths = [bundle.pathForResource("realm", ofType: "json")!]

        let generator =  ImportSchemaGenerator(files: filePaths)
        let schema = try! generator.generate()

        let destinationRealmPath = Path(self.outputTestFolderPath)
        let dataImporter = JSONDataImporter(files: filePaths)
        try! dataImporter.importToPath(String(destinationRealmPath), schema: schema)

        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(String(destinationRealmPath)))
    }

    func testThatPropertyTypesAreDetectedProperlyWhenImportingFromCSV() {
        let csvSchema = try! generateSchemaForFileAtPath(bundle.pathForResource("import-test", ofType: "csv")!)

        XCTAssertTrue(csvSchema.schemas[0].properties[0].type == .Int)
        XCTAssertTrue(csvSchema.schemas[0].properties[1].type == .Int)
        XCTAssertTrue(csvSchema.schemas[0].properties[2].type == .Double)
        XCTAssertTrue(csvSchema.schemas[0].properties[3].type == .Double)
        XCTAssertTrue(csvSchema.schemas[0].properties[4].type == .String)
        XCTAssertTrue(csvSchema.schemas[0].properties[5].type == .String)
        XCTAssertTrue(csvSchema.schemas[0].properties[5].type == .String)
        XCTAssertTrue(csvSchema.schemas[0].properties[5].type == .String)
    }

    // FIXME: XLSX import doesn't seem to work at all :(
    func DISABLED_testThatPropertyTypesAreDetectedProperlyWhenImportingFromXLSX() {
        let xlsxSchema = try! generateSchemaForFileAtPath(bundle.pathForResource("restaurant", ofType: "xlsx")!)
        XCTAssertTrue(xlsxSchema.schemas[0].properties[0].type == .Int)
    }

    func testThatPropertyTypesAreDetectedProperlyWhenImportingFromJSON() {
        let jsonSchema = try! generateSchemaForFileAtPath(bundle.pathForResource("realm", ofType: "json")!)
        XCTAssertTrue(jsonSchema.schemas[0].properties[0].type == .Int)
        XCTAssertTrue(jsonSchema.schemas[0].properties[1].type == .String)
    }

    func generateSchemaForFileAtPath(path: String) throws -> ImportSchema {
        let generator = ImportSchemaGenerator(files: [path])
        return try generator.generate()
    }

}
