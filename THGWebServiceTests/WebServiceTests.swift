//
//  WebServiceTests.swift
//  THGWebService
//
//  Created by Angelo Di Paolo on 3/11/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import UIKit
import XCTest
import THGWebService

class WebServiceTests: XCTestCase {
    
    // MARK: Utilities
    
    var baseURL: String {
        get {
            return "http://httpbin.org/"
        }
    }
    
    func responseHandler(expectation expectation: XCTestExpectation) -> (NSData?, NSURLResponse?) -> Void {
        return { data, response in
            
            let httpResponse = response as! NSHTTPURLResponse
            
            if httpResponse.statusCode == 200 {
                expectation.fulfill()
            }
        }
    }
    
    func jsonResponseHandler(expectation expectation: XCTestExpectation) -> (AnyObject?) -> Void {
        return { json in
            
            if json is NSDictionary {
                expectation.fulfill()
            }
        }
    }

    // MARK: Tests  
    
    func testGetEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
                    .GET("/get")
                    .response(handler)
                    .resume()

        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testAbsoluteURLString() {
        let service = WebService(baseURLString: "http://www.walmart.com/")
        let url = service.absoluteURLString("/foo")
        XCTAssertEqual(url, "http://www.walmart.com/foo")
    }
    
    /// Verify that absolute paths work against a different base URL.
    func testGetAbsolutePath() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: "www.walmart.com")
        let task = service
            .GET("http://httpbin.org/get")
            .response(handler)
            .resume()

        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .POST("/post")
            .response(handler)
            .resume()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPutEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .PUT("/put")
            .response(handler)
            .resume()

        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testDeleteEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .DELETE("/delete")
            .response(handler)
            .resume()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testErrorHandler() {
        let baseURL = "httpppppp://httpbin.org/"
        let errorExpectation = expectationWithDescription("Error handler called for bad URL")
        var wasResponseCalled = false
        
        WebService(baseURLString: baseURL)
            .GET("/")
            .response { data, response in
                wasResponseCalled = true
            }
            .responseError { error in
                XCTAssertFalse(wasResponseCalled, "Response should not be called for error cases")
                errorExpectation.fulfill()
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testSpecifyingResponseHandlerQueue() {
        let successExpectation = expectationWithDescription("Received status 200")
        let backgroundExpectation = expectationWithDescription("Background handler ran")
        let service = WebService(baseURLString: baseURL)
        let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)

        let task = service
            .GET("/get")
            .response(queue) { data, response in
                backgroundExpectation.fulfill()
            }
            .response { data, response in
                successExpectation.fulfill()
            }
            .resume()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(4, handler: nil)
    }
    
    func testGetJSON() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .GET("/get")
            .responseJSON(handler)
            .resume()

        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testGetJSONWithSpecificQueue() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        let task = service
            .GET("/get")
            .responseJSON(queue, handler: handler)
            .resume()

        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testGetPercentEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        service
            .GET("/get")
                .setParameters(parameters)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)

                let deliveredParameters = castedJSON!["args"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostPercentEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        service
            .POST("/post")
                .setParameters(parameters)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["form"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostJSONEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "number" : 42]
        
        service
            .POST("/post")
                .setParameters(parameters, encoding: .JSON)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["json"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostJSONEncodedArray() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        
        let jsonObject = ["foo" : "bar", "number" : 42]
        let jsonArray = [jsonObject, jsonObject]
        
        service
            .POST("/post")
                .setParameterEncoding(.JSON)
                .setJSON(jsonArray)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredArray = castedJSON!["json"] as? [[String : AnyObject]]
                XCTAssert(deliveredArray != nil)
                
                for deliveredJSONObject in deliveredArray! {
                    RequestTests.assertRequestParametersNotEqual(deliveredJSONObject, toOriginalParameters: jsonObject)
                }
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testHeadersDelivered() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let headers =  ["Some-Test-Header" :"testValue"]
        
        service
            .GET("/get")
                .setHeaders(headers)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredHeaders = castedJSON!["headers"] as? [String : AnyObject]
                XCTAssert(deliveredHeaders != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredHeaders!, toOriginalParameters: headers)
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testFoo() {
        let service = WebService(baseURLString: baseURL)
        let successExpectation = expectationWithDescription("Received status 200")

        service
            .POST("/post")
                .setHeaderValue("Custom-Header", forName: "bar")
                .setParameters(["foo" : "this needs percent encoded"])
            .response { data, res in
                let httpResponse = res as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .resume()
        
        waitForExpectationsWithTimeout(5.0, handler: nil)
        
        /**
        
        POST /stores HTTP/1.1
        Custom-Header: bar
        Content-Length: 55
        
        foo=this%20needs%20percent%20encoded
        */
    }
}

