//
//  GardenViewTVC.swift
//  E-Plant
//
//  Created by Jiazhou Liu on 27/10/17.
//  Copyright © 2017 Monash University. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class GardenViewTVC: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate  {

    // IBOutlet variables
    @IBOutlet weak var currentWeatherIcon: UIImageView!
    @IBOutlet weak var currentTemp: UILabel!
    @IBOutlet weak var currentDate: UILabel!
    @IBOutlet weak var currentTempRange: UILabel!
    @IBOutlet weak var secDayWeatherIcon: UIImageView!
    @IBOutlet weak var secDayDate: UILabel!
    @IBOutlet weak var secDayTempRange: UILabel!
    @IBOutlet weak var thirdDayWeatherIcon: UIImageView!
    @IBOutlet weak var thirdDayDate: UILabel!
    @IBOutlet weak var thirdDayTempRange: UILabel!
    @IBOutlet weak var fourthDayWeatherIcon: UIImageView!
    @IBOutlet weak var fourthDayDate: UILabel!
    @IBOutlet weak var fourthDayTempRange: UILabel!
    @IBOutlet weak var soilMoist: UILabel!
    @IBOutlet weak var gardenTemp: UILabel!
    @IBOutlet weak var gardenPress: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // passed by variable
    var selectedGarden: Garden?
    
    // FRC controller
    var controller: NSFetchedResultsController<Plant>!
    
    // garden map variables
    var gardenLat: Double?
    var gardenLong: Double?
    var mapHasCenteredOnce = false
    
    // Activity Indicator
    var spinner: UIActivityIndicatorView!
    
    // weather variables
    var gardenLocation: CLLocation!
    var myTimerLocal: Timer?
    var myTimerOnline: Timer?
    var onlineWeather: OnlineWeather!
    var onlineForecast: OnlineWeatherForecast!
    var localTemp1: LocalTemperature1!
    var localTemp2: LocalTemperature2!
    var localTemp3: LocalTemperature3!
    var localMoist1: LocalMoisture1!
    var localMoist2: LocalMoisture2!
    var localMoist3: LocalMoisture3!
    
    // plants variables
    var plants = [Plant]()
    
    // begin view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        // load restaurant if got passed data
        if selectedGarden != nil {
            loadGardenData()
        }
        
        // setup annotation for restaurant
        mapView.delegate = self
        
        // setup collectionView delegate
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // setup spinner
        self.spinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height:50))
        self.spinner.color = UIColor.darkGray
        self.spinner.center = CGPoint(x: self.view.frame.width / 2, y: 160)
        self.tableView.addSubview(spinner)
        self.spinner.hidesWhenStopped = true
        self.spinner.startAnimating()
        
        if let title = selectedGarden?.name, let subtitle = selectedGarden?.toPlant?.count, let lat = selectedGarden?.latitude, let long = selectedGarden?.longitude{
            let gardenAnnotation = FencedAnnotation(newTitle: title, newSubtitle: "\(subtitle) plants", lat: lat, long: long)
            mapView.addAnnotation(gardenAnnotation)
        }
        let loc: CLLocation = CLLocation(latitude: gardenLat!, longitude: gardenLong!)
        centerMapOnLocation(location: loc)
    }
    
    // change for view appear every time
    override func viewDidAppear(_ animated: Bool) {
        // setup navigation title
        navigationItem.title = (selectedGarden?.name)!
        
        // refresh current date and print on screen
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd"
        let todayFormatter = DateFormatter()
        todayFormatter.dateFormat = "yyyy-MM-dd"
        let today = todayFormatter.string(from: date)
        let result = formatter.string(from: date)
        let DOW = getDayOfWeek(today: today)
        self.currentDate.text = "\(DOW!) \(result)"
        
        
        if (myTimerLocal == nil && myTimerOnline == nil) {
            startTimer()
        }else{
            if !((myTimerLocal?.isValid)!) && !((myTimerOnline?.isValid)!){
                startTimer()
            }
        }
        
    }
    
    // invalidate timer after leaving this view to avoid duplicate timer
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myTimerLocal?.invalidate()
        myTimerOnline?.invalidate()
    }
    
    // load garden data from passed by garden
    func loadGardenData() {
        gardenLat = selectedGarden?.latitude
        gardenLong = selectedGarden?.longitude
        
        let fetchRequest: NSFetchRequest<Plant> = Plant.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "toGarden == %@", selectedGarden!)
        
        let dateSort = NSSortDescriptor(key: "dateAdded", ascending: false)
        
        fetchRequest.sortDescriptors = [dateSort]

        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        self.controller = controller
        
        do {
            try controller.performFetch()
        }catch {
            let error = error as NSError
            print("\(error)")
        }
    
    }
    
    // fetch online weather data and update UI
    func updateOnlineUI(){
        currentWeatherIcon.image = UIImage(named: "\(onlineWeather.weather)")
        currentTemp.text = "\(onlineWeather.temperature) °C"
        currentTempRange.text = "\(onlineWeather.currentTempMin) °C - \(onlineWeather.currentTempMax) °C"
        
    }
    func updateOnlineForecastUI(){
        secDayWeatherIcon.image = UIImage(named: "\(onlineForecast.firstWeather)")
        secDayTempRange.text = "\(onlineForecast.firstTempMin) °C - \(onlineForecast.firstTempMax) °C"
        
        thirdDayWeatherIcon.image = UIImage(named: "\(onlineForecast.secondWeather)")
        thirdDayTempRange.text = "\(onlineForecast.secondTempMin) °C - \(onlineForecast.secondTempMax) °C"
        
        fourthDayWeatherIcon.image = UIImage(named: "\(onlineForecast.thirdWeather)")
        fourthDayTempRange.text = "\(onlineForecast.thirdTempMin) °C - \(onlineForecast.thirdTempMax) °C"
    }
    
    // fetch local sensor data and update UI
    func updateLocalTempUI() {
        if selectedGarden?.sensorNo == 1 {
            if localTemp1.pressure == 0.0{
                gardenTemp.text =  "unknown"
                gardenPress.text = "unknown"
            }else{
                gardenTemp.text =  "\(localTemp1.temperature) °C"
                gardenPress.text = "\(localTemp1.pressure) kPa"
            }
        }else if selectedGarden?.sensorNo == 2 {
            
            if localTemp2.pressure == 0.0{
                gardenTemp.text =  "unknown"
                gardenPress.text = "unknown"
            }else{
                gardenTemp.text =  "\(localTemp2.temperature) °C"
                gardenPress.text = "\(localTemp2.pressure) kPa"
            }
        }else if selectedGarden?.sensorNo == 3 {
            if localTemp3.pressure == 0.0{
                gardenTemp.text =  "unknown"
                gardenPress.text = "unknown"
            }else{
                gardenTemp.text =  "\(localTemp3.temperature) °C"
                gardenPress.text = "\(localTemp3.pressure) kPa"
            }
        }else{
            print("error!")
        }
        
    }
    func updateLocalMoistUI() {
        if selectedGarden?.sensorNo == 1 {
            if localMoist1.moisture == 0{
                soilMoist.text = "unknown"
            }else{
                soilMoist.text = "\(localMoist1.moisture)%"
            }
        }else if selectedGarden?.sensorNo == 2 {
            if localMoist2.moisture == 0{
                soilMoist.text = "unknown"
            }else{
                soilMoist.text = "\(localMoist2.moisture)%"
            }
        }else if selectedGarden?.sensorNo == 3 {
            if localMoist3.moisture == 0{
                soilMoist.text = "unknown"
            }else{
                soilMoist.text = "\(localMoist3.moisture)%"
            }
        }else{
            print("error!")
        }
    }
    
    // map view configuration
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinateRegion, animated: false)
    }
    
    // start a 1s timer to refresh online and local weather
    func startTimer(){
        refreshLocalWeather()
        refreshOnlineWeather()
        myTimerLocal = Timer.scheduledTimer(timeInterval: 1, target: self,selector: #selector(GardenViewTVC.refreshLocalWeather), userInfo: nil, repeats: true)
        myTimerOnline = Timer.scheduledTimer(timeInterval: 30, target: self,selector: #selector(GardenViewTVC.refreshLocalWeather), userInfo: nil, repeats: true)
        
    }
    
    // refresh online weather
    func refreshOnlineWeather() {
        onlineWeather = OnlineWeather()
        onlineWeather.downloadOnlineWeatherDetails {
            self.spinner.stopAnimating()
            self.updateOnlineUI()
        }
        onlineForecast = OnlineWeatherForecast()
        onlineForecast.downloadOnlineWeatherDetails {
            self.spinner.stopAnimating()
            self.updateOnlineForecastUI()
        }
    }
    
    // refresh local weather
    func refreshLocalWeather() {
        
        if selectedGarden?.sensorNo == 1 {
            localTemp1 = LocalTemperature1()
            localTemp1.downloadLocalWeatherDetails {
                self.spinner.stopAnimating()
                self.updateLocalTempUI()
            }
            localMoist1 = LocalMoisture1()
            localMoist1.downloadLocalMoistureDetails {
                self.spinner.stopAnimating()
                self.updateLocalMoistUI()
            }
        }else if selectedGarden?.sensorNo == 2 {
            localTemp2 = LocalTemperature2()
            localTemp2.downloadLocalWeatherDetails {
                self.spinner.stopAnimating()
                self.updateLocalTempUI()
            }
            localMoist2 = LocalMoisture2()
            localMoist2.downloadLocalMoistureDetails {
                self.spinner.stopAnimating()
                self.updateLocalMoistUI()
            }
        }else if selectedGarden?.sensorNo == 3 {
            localTemp3 = LocalTemperature3()
            localTemp3.downloadLocalWeatherDetails {
                self.spinner.stopAnimating()
                self.updateLocalTempUI()
            }
            localMoist3 = LocalMoisture3()
            localMoist3.downloadLocalMoistureDetails {
                self.spinner.stopAnimating()
                self.updateLocalMoistUI()
            }
        }else{
            print("error!")
        }
    }
    
    //// get plants and conditions
    // return number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = controller.sections {
            
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    // get items for each cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlantCVC", for: indexPath) as! PlantCVC
        
        let item = controller.object(at: indexPath as IndexPath)
        cell.plantImage.image = item.toImage?.image as? UIImage
        cell.plantCondition.text = item.condition
        if item.condition == "healthy condition" {
            cell.plantCondition.textColor = UIColor.green
        }else if item.condition == "warning condition" {
            cell.plantCondition.textColor = UIColor.orange
        }else if item.condition == "error condition" {
            cell.plantCondition.textColor = UIColor.red
        }
        cell.plantName.text = item.name
        
        return cell
    }
    // if select item from collection item, passed through segue to plant view
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let objs = controller.fetchedObjects, objs.count > 0 {
            let plant = objs[indexPath.row]
            performSegue(withIdentifier: "plantViewFromGardenView", sender: plant)
        }
    }
    
    // passed through garden to plant list view by segue
    @IBAction func viewAllPlantsBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "plantsListFromGardenView", sender: selectedGarden)
    }
    
    // navigate to settings screen with garden object
    @IBAction func settingsBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "gardenSettingsFromView", sender: selectedGarden)
    }
    
    // water button to update water information
    @IBAction func waterBtnPressed(_ sender: Any) {
        // show user success message and navigate back to root screen
        let alert = UIAlertController(title: "Water this garden", message: "Please enter watering time below:", preferredStyle: .alert)
        
        alert.addTextField { (textField : UITextField) -> Void in
            textField.placeholder = "...mins"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
        }
        let waterAction = UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if let waterQty = Int((textField?.text)!){
                if waterQty > 0{
                    self.selectedGarden?.waterUsageQty += Int16(waterQty)
                    self.selectedGarden?.lastWaterQty = Int16(waterQty)
                    self.selectedGarden?.lastWaterTime = NSDate()
                    ad.saveContext()
                    let alertVC = UIAlertController(title: "Success", message: "You have successfully updated water information", preferredStyle: UIAlertControllerStyle.alert)
                    let acSure = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (UIAlertAction) -> Void in
                    }
                    alertVC.addAction(acSure)
                    self.present(alertVC, animated: true, completion: nil)
                }
            }else{
                let alertVC = UIAlertController(title: "Failed", message: "Please enter a valid number", preferredStyle: UIAlertControllerStyle.alert)
                let acSure = UIAlertAction(title: "OK", style: UIAlertActionStyle.destructive) { (UIAlertAction) -> Void in
                }
                alertVC.addAction(acSure)
                self.present(alertVC, animated: true, completion: nil)
            }
            
        })
        cancelAction.setValue(UIColor.gray, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        alert.addAction(waterAction)
        self.present(alert, animated: true, completion: nil)
    }

    // prepare for single garden controller segue and take object selected object to the next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gardenSettingsFromView" {
            if let destination = segue.destination as? GardenSettingsTVC {
                if let garden = sender as? Garden {
                    destination.selectedGarden = garden
                }
            }
        }
        if segue.identifier == "plantsListFromGardenView" {
            if let destination = segue.destination as? MyPlantTableViewController {
                if let garden = sender as? Garden {
                    destination.filterGarden = garden
                }
            }
        }
        if segue.identifier == "plantViewFromGardenView" {
            if let destination = segue.destination as? PlantsViewController {
                if let plant = sender as? Plant {
                    destination.plant = plant
                }
            }
        }
    }
    
    // custom Date String Helper Functions -> day of the week
    func getDayOfWeek(today:String)->String? {
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let todayDate = formatter.date(from: today) {
            let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            let myComponents = myCalendar.components(.weekday, from: todayDate)
            let weekDay = myComponents.weekday!
            switch weekDay {
            case 1:
                secDayDate.text = "Mon"
                thirdDayDate.text = "Tue"
                fourthDayDate.text = "Wed"
                return "Sunday"
            case 2:
                secDayDate.text = "Tue"
                thirdDayDate.text = "Wed"
                fourthDayDate.text = "Thu"
                return "Monday"
            case 3:
                secDayDate.text = "Wed"
                thirdDayDate.text = "Thu"
                fourthDayDate.text = "Fri"
                return "Tuesday"
            case 4:
                secDayDate.text = "Thu"
                thirdDayDate.text = "Fri"
                fourthDayDate.text = "Sat"
                return "Wednesday"
            case 5:
                secDayDate.text = "Fri"
                thirdDayDate.text = "Sat"
                fourthDayDate.text = "Sun"
                return "Thursday"
            case 6:
                secDayDate.text = "Sat"
                thirdDayDate.text = "Sun"
                fourthDayDate.text = "Mon"
                return "Friday"
            case 7:
                secDayDate.text = "Sun"
                thirdDayDate.text = "Mon"
                fourthDayDate.text = "Tue"
                return "Saturday"
            default:
                print("Error fetching days")
                return "Day"
            }
        } else {
            return nil
        }
    }
}
