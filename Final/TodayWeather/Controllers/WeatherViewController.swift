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
  
  private var viewModel: WeatherViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.tableFooterView = UIView()
    activityIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    
    cityTextField.becomeFirstResponder()

    tableView.delegate = self
    tableView.dataSource = self
    cityTextField.delegate = self
    viewModel = WeatherViewModel(weatherService: WeatherService())
    
    viewModel.degree.bind { degree in
      DispatchQueue.main.async {
        self.degreeLabel.text = degree
        self.activityIndicator.stopAnimating()
      }
    }
    
    viewModel.description.bind { description in
      DispatchQueue.main.async {
        self.descriptionLabel.text = description
      }
    }
    
    viewModel.imageId.bind { url in
      DispatchQueue.main.async {
        if let url = url {
          self.weatherImageView.downloaded(from: url)
        }
      }
    }
    
    viewModel.dataSource.bind { dataSource in
      DispatchQueue.main.async {
        self.dataSource = dataSource
        self.tableView.reloadData()
      }
    }

    viewModel.errorHandler.bind { error in
      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        if !error.isEmpty {
          self.displayError(error)
        }
      }
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

    viewModel.getWeatherData(cityName: textField.text ?? "", requestType: .Forecast)
    
    viewModel.getWeatherData(cityName: textField.text ?? "", requestType: .CurrentWeather)
    
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
    cell.minDegreeLabel.text = viewModel.formattedDegree(minDegree)
    cell.maxDegreeLabel.text = viewModel.formattedDegree(maxDegree)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dataSource?.count ?? 0
  }
}
