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

public enum RequestType {
  case Forecast
  case CurrentWeather
}

public enum APIError: Error {
  case ParseError(String)
  case RequestError(String)
}

struct WeatherService {
  
  private struct Constants {
    static let APPID = "6a700a1e919dc96b0a98901c9f4bec47"
    static let baseURL = "https://api.openweathermap.org/"
  }
  
  enum ResourcePath: String {
    case Forecast = "data/2.5/forecast/daily"
    case Weather = "data/2.5/weather"
    case Icon = "img/w/"
    
    var path: String {
      return Constants.baseURL + rawValue
    }
  }
  
  func fetchWeatherData(cityName city: String?, type: RequestType, completion: @escaping (WeatherProtocol?, APIError?) -> Void) {
    let parameters = ["q": city, "appid": Constants.APPID]
    
    var components: URLComponents!
    switch type {
    case .CurrentWeather:
      components = URLComponents(string: ResourcePath.Weather.path)
    case .Forecast:
      components = URLComponents(string: ResourcePath.Forecast.path)
    }
    components.queryItems = parameters.map { (key, value) in
      URLQueryItem(name: key, value: value)
    }
    let url = URL(string: components.url!.absoluteString)!
    
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
      guard let data = data,
        let response = response as? HTTPURLResponse,
        (200 ..< 300) ~= response.statusCode,
        error == nil else {
          completion(nil, APIError.RequestError("Error in request ☹️"))
          return
      }
      switch type {
      case .CurrentWeather:
        guard let weather = CurrentWeather(data: data) else {
          return completion(nil, APIError.ParseError("Error parsing response ☹️"))
        }
        completion(weather, nil)
      case .Forecast:
        guard let forecast = Forecast(data: data) else {
          return completion(nil, APIError.ParseError("Error parsing response ☹️"))
        }
        completion(forecast, nil)
      }
    }
    
    task.resume()
  }
  
}
