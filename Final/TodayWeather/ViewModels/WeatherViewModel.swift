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

class WeatherViewModel {
  var weatherService: WeatherService
  
  var degree: Box<String> = Box("0")
  var description: Box<String> = Box("Description")
  var errorHandler: Box<String> = Box("")
  var imageId: Box<URL?> = Box(nil)

  var dataSource: Box<[ForecastItem]?> = Box(nil)

  enum DegreeType {
    case Kelvin
    case Celsius
  }
  
  var degreeType: DegreeType = DegreeType.Celsius
  let CELSIUS_TO_KELVIN: Float = 273.15
  
  init(weatherService: WeatherService) {
    self.weatherService = weatherService
  }
  
}

extension WeatherViewModel {
  func formattedDegree(_ degree: Float) -> String {
    switch degreeType {
    case .Celsius:
      return "\(Int((degree - self.CELSIUS_TO_KELVIN).rounded()))"
    case .Kelvin:
      return "\(Int((degree).rounded()))"
    }
  }

  func getWeatherData(cityName: String, requestType: RequestType, completion: @escaping (WeatherProtocol?, APIError?) -> Void = { result, error in }) {
    weatherService.fetchWeatherData(cityName: cityName, type: requestType) { result, error in
      if let weather = result as? Weather {
        self.degree.value = "\(self.formattedDegree(weather.degree))°"
        self.description.value = weather.description.capitalized
        self.imageId.value = URL(string: WeatherService.ResourcePath.Icon.path + weather.imageId)
      }
      else if let forecast = result as? Forecast {
        self.dataSource.value = forecast.getList()
      }
      else if let error = error {
        switch error {
        case let .RequestError(reason):
          self.errorHandler.value = reason
        case let .ParseError(reason):
          self.errorHandler.value = reason
        }
      }
      completion(result, error)
    }
  }
}
