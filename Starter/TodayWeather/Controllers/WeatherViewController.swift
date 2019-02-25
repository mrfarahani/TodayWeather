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

import UIKit
import SwiftyJSON

class WeatherViewController: UIViewController {
  @IBOutlet weak var degreeLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var cityTextField: UITextField!
  @IBOutlet weak var weatherImageView: UIImageView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @IBOutlet weak var tableView: UITableView!
  var dataSource: [ForecastItem]?
  // TODO: Add ViewModel property

  
  // TODO: Move to ViewModel
  enum DegreeType {
    case Kelvin
    case Celsius
  }
  
  let degreeType: DegreeType = DegreeType.Celsius
  let CELSIUS_TO_KELVIN: Float = 273.15
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.tableFooterView = UIView()
    cityTextField.becomeFirstResponder()
    activityIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    
    tableView.delegate = self
    tableView.dataSource = self
    cityTextField.delegate = self
  }

}

// MARK: Things to move
extension WeatherViewController {
  
  func getWeatherData(cityName: String, requestType: RequestType, completion: @escaping (WeatherProtocol?, APIError?) -> Void) {
    WeatherService().fetchWeatherData(cityName: cityName, type: requestType) { result, error in
      completion(result, error)
    }
  }
  
  func formattedDegree(_ degree: Float) -> String {
    switch degreeType {
    case .Celsius:
      return "\(Int((degree - self.CELSIUS_TO_KELVIN).rounded()))"
    case .Kelvin:
      return "\(Int((degree).rounded()))"
    }
  }
}

// MARK: Private Methods
private extension WeatherViewController {
  func displayError(_ message: String) {
    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(okAction)
    present(alertController, animated: true, completion: nil)
  }
}

// MARK: UITextFieldDelegate
extension WeatherViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    self.activityIndicator.startAnimating()

    // TODO: Use ViewModel
    getWeatherData(cityName: textField.text ?? "", requestType: .Forecast) { forecast, error in
      guard let forecast = forecast as? Forecast else {
        DispatchQueue.main.async {
          self.activityIndicator.stopAnimating()
        }
        if let error = error {
          switch error {
          case let .RequestError(reason):
            self.displayError(reason)
          case let .ParseError(reason):
            self.displayError(reason)
          }
        }
        return
      }

      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        self.dataSource = forecast.getList()
        self.tableView.reloadData()
      }
    }
    
    getWeatherData(cityName: textField.text ?? "", requestType: .CurrentWeather) { weather, error in
      guard let weather = weather as? Weather else {
        DispatchQueue.main.async {
          self.activityIndicator.stopAnimating()
        }
        if let error = error {
          switch error {
          case let .RequestError(reason):
            self.displayError(reason)
          case let .ParseError(reason):
            self.displayError(reason)
          }
        }
        return
      }
      
      let degree = self.formattedDegree(weather.degree)
      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        self.descriptionLabel.text = weather.description.capitalized
        self.degreeLabel.text = "\(degree)°"
      }
    }
    return true
  }
  
}

// MARK: UITableViewDelegate, UITableViewDataSource
extension WeatherViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "forecastCell", for: indexPath) as! ForecastTableViewCell
    guard let date = self.dataSource?[indexPath.row].date,
      let minDegree = self.dataSource?[indexPath.row].minDegree,
      let maxDegree = self.dataSource?[indexPath.row].maxDegree
    else {
        return cell
    }

    cell.dayOfWeekLabel.text = date.dayOfWeek()
    cell.minDegreeLabel.text = formattedDegree(minDegree)
    cell.maxDegreeLabel.text = formattedDegree(maxDegree)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dataSource?.count ?? 0
  }
}
