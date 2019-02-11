import XCTest
@testable import CSVDecoder
import CSVReader

final class CSVDecoderTests: XCTestCase {
    
    func testStringDecoding() throws {
        struct Account: Codable, Equatable {
            var state: String
            var email: String
            var company_name: String
        }
        
        let comparableAccount = Account(state: "active", email: "info@acme.com", company_name: "ACME inc.")
        
        let decoder = CSVDecoder()
        let csvString = "state,email,company_name\nactive,info@acme.com,ACME inc."
        let csvReader = try CSVReader(string: csvString, hasHeader: true)
        
        csvReader.readLine()
        let account = try decoder.decode(Account.self, using: csvReader)
        XCTAssertEqual(account, comparableAccount)
    }
    
    func testOptionalDecoding() throws {
        struct Account: Codable, Equatable {
            var state: String
            var email: String
            var companyName: String?
        }
        
        let comparableAccount1 = Account(state: "active", email: "info@acme.com", companyName: "ACME inc.")
        let comparableAccount2 = Account(state: "canceled", email: "info@coldfusion.com", companyName: nil)
        
        let decoder = CSVDecoder()
        let csvString = "state,email,companyName\nactive,info@acme.com,ACME inc.\ncanceled,info@coldfusion.com,"
        let csvReader = try CSVReader(string: csvString, hasHeader: true)
        
        csvReader.readLine()
        let account1 = try decoder.decode(Account.self, using: csvReader)
        print(account1)
        XCTAssertEqual(account1, comparableAccount1)
        XCTAssertNotNil(account1.companyName)
        
        csvReader.readLine()
        let account2 = try decoder.decode(Account.self, using: csvReader)
        XCTAssertEqual(account2, comparableAccount2)
        XCTAssertNil(account2.companyName)
    }
    
    func testEnumDecoding() throws {
        struct Account: Codable, Equatable {
            enum State: String, Codable {
                case active, canceled
            }
            var state: State
            var email: String
            var companyName: String?
        }
        
        let comparableAccount = Account(state: .active, email: "info@acme.com", companyName: "ACME inc.")
        
        let decoder = CSVDecoder()
        let csvString = "state,email,companyName\nactive,info@acme.com,ACME inc."
        let csvReader = try CSVReader(string: csvString, hasHeader: true)
        
        csvReader.readLine()
        let account = try decoder.decode(Account.self, using: csvReader)
        XCTAssertEqual(account, comparableAccount)
    }
    
    func testTypesDecoding() throws {
        struct Person: Codable, Equatable {
            var name: String
            var age: Int
            var isProgrammer: Bool
            var height: Double
        }
        
        let comparablePerson = Person(name: "John", age: 25, isProgrammer: true, height: 1.82)
        
        let decoder = CSVDecoder()
        let csvString = "name,age,isProgrammer,height\nJohn,25,true,1.82"
        let csvReader = try CSVReader(string: csvString, hasHeader: true)
        
        csvReader.readLine()
        let person = try decoder.decode(Person.self, using: csvReader)
        XCTAssertEqual(person, comparablePerson)
    }
    
    @available(OSX 10.12, *)
    func testDateDecoding() throws {
        struct BirthDay: Codable, Equatable {
            var name: String
            var date: Date
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = .withInternetDateTime
        let comparableBirthDay = BirthDay(name: "John", date: dateFormatter.date(from: "2018-12-25T17:30:00Z")!)
        let decoder = CSVDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let csvString = "name,date\nJohn,2018-12-25T17:30:00Z"
        let csvReader = try CSVReader(string: csvString, hasHeader: true)
        
        csvReader.readLine()
        let birthday = try decoder.decode(BirthDay.self, using: csvReader)
        XCTAssertEqual(birthday, comparableBirthDay)
    }

    @available(OSX 10.12, *)
    static var allTests = [
        ("testStringDecoding", testStringDecoding),
        ("testOptionalDecoding", testOptionalDecoding),
        ("testEnumDecoding", testEnumDecoding),
        ("testTypesDecoding", testTypesDecoding),
        ("testDateDecoding", testDateDecoding),
    ]
}
