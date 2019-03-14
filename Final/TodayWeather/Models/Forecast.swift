/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

struct InitialForecastElement: Codable {
  let list: [List]?
}

struct List: Codable {
  let dt: Double?
  let temp: Temp?
}

struct Temp: Codable {
  let min: Float?
  let max: Float?
}


struct Forecast: WeatherProtocol {
  
  private let list: [List]
  
  
  init?(data: Data) {
    var forecastData: InitialForecastElement?

    do {
      let decoder = JSONDecoder()
      forecastData = try decoder.decode(InitialForecastElement.self, from: data)
      
    } catch let err {
      print("Err", err)
    }
    
    guard
      let list = forecastData?.list
      else {
        return nil
    }
    self.list = list
  }
  
  func getList() -> [ForecastItem]? {
    var forecastItems = [ForecastItem]()
    for item in list {
      guard
        let timestamp = item.dt,
        let minDegree = item.temp?.min,
        let maxDegree = item.temp?.max
      else {
          return nil
      }
      let date = Date(timeIntervalSince1970: timestamp)
      let item = ForecastItem(date: date, minDegree: minDegree, maxDegree: maxDegree)
      forecastItems.append(item)
    }
    return forecastItems
  }
}

struct ForecastItem {
  let date: Date
  let minDegree: Float
  let maxDegree: Float
}
