//
//  GardenListTVC.swift
//  E-Plant
//
//  Created by Jiazhou Liu on 27/10/17.
//  Copyright © 2017 Monash University. All rights reserved.
//

import UIKit
import CoreData

class GardenListTVC: UITableViewController, NSFetchedResultsControllerDelegate {

    
    // FRC controller variable
    var controller: NSFetchedResultsController<Garden>!
    // customOrderFlag
    var customOrder:Bool = false
    // edit Btn IBOutlet
    @IBOutlet weak var editBtn: UIBarButtonItem!
    var managedContext: NSManagedObjectContext?
    
    // check sensor status
    var myTimer: Timer?
    var localTemp1: LocalTemperature1!
    var localTemp2: LocalTemperature2!
    var localTemp3: LocalTemperature3!
    var sensor1On:Bool = false
    var sensor2On:Bool = false
    var sensor3On:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // first Fetch to initialize controller and get all gardens
        attemptFetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let sections = controller.sections {
            
            let sectionInfo = sections[0]
            // if nothing in the controller, add sample data
            if sectionInfo.numberOfObjects == 0{
                generateTestData()
                attemptFetch()
            }else{
                // if controller not empty, get customOrder flag configured
                let gardens = controller.fetchedObjects
                for item in gardens!{
                    if item.customOrder{
                        self.customOrder = true
                    }
                }
                attemptFetch()
            }
        }
        if myTimer == nil {
            startTimer()
        }else{
            if !((myTimer?.isValid)!) {
                startTimer()
            }
        }
    }
    
    // invalidate timer after leaving this view to avoid duplicate timer
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myTimer?.invalidate()
    }
    
    // start a 2s timer to refresh local weather
    func startTimer(){
        myTimer = Timer.scheduledTimer(timeInterval: 2, target: self,selector: #selector(GardenListTVC.refreshLocalWeather), userInfo: nil, repeats: true)
    }
    
    // refresh local weather data from sensor
    func refreshLocalWeather() {
        localTemp1 = LocalTemperature1()
        localTemp1.downloadLocalWeatherDetails {
            if self.localTemp1.pressure > 0.0 {
                self.sensor1On = true
            }else{
                self.sensor1On = false
            }
        }

        localTemp2 = LocalTemperature2()
        localTemp2.downloadLocalWeatherDetails {
            if self.localTemp2.pressure > 0.0 {
                self.sensor2On = true
            }else{
                self.sensor2On = false
            }
        }

        localTemp3 = LocalTemperature3()
        localTemp3.downloadLocalWeatherDetails {
            if self.localTemp3.pressure > 0.0 {
                self.sensor3On = true
            }else{
                self.sensor3On = false
            }
        }
        tableView.reloadData()
    }
    
    // number of sections for tableview
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = controller.sections {
            return sections.count
        }
        return 0
    }
    // number of rows in section for tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if let sections = controller.sections {
                
                let sectionInfo = sections[section]
                return sectionInfo.numberOfObjects
            }
            return 0
    }

    // call configureCell function to configure cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GardenCell", for: indexPath) as! GardenCell
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        
        return cell
    }
    
    // take garden object into cell model to configure cell UI elements
    func configureCell(cell: GardenCell, indexPath: NSIndexPath){
        let item = controller.object(at: indexPath as IndexPath)
        cell.configureCell(item: item, order: indexPath.row, sensor1: sensor1On, sensor2: sensor2On, sensor3: sensor3On)
    }
    
    // if select row then perform segue to single garden controller
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if let objs = controller.fetchedObjects, objs.count > 0 {
            let garden = objs[indexPath.row]
            performSegue(withIdentifier: "gardenViewFromList", sender: garden)
        }
    }
    
    // prepare for single garden controller segue and take object selected object to the next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gardenViewFromList" {
            if let destination = segue.destination as? GardenViewTVC {
                if let garden = sender as? Garden {
                    destination.selectedGarden = garden
                }
            }
        }
    }
    
    // height for row for tableview
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    // enable row editing function
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // delete editing for tableview
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let deletedGarden = controller.object(at: indexPath as IndexPath)
            context.delete(deletedGarden)
            ad.saveContext()
            
        }else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // enable move function
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // move row for tableview
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        attemptFetch()
        
        var gardens = controller.fetchedObjects!
        //controller.delegate = nil
        
        let object = gardens[sourceIndexPath.row]
        gardens.remove(at: sourceIndexPath.row)
        gardens.insert(object, at: destinationIndexPath.row)
        
        var i = 0
        for item in gardens{
            self.customOrder = true
            item.customOrder = true
            item.orderNo = Int16(i)
            i += 1
        }
        attemptFetch()
        tableView.reloadData()
    }
    
    // toggle editing mode and edit button text
    @IBAction func editBtnPressed(_ sender: Any) {
        self.isEditing = !self.isEditing
        
        if tableView.isEditing {
            editBtn.title = "Save"
        } else {
            editBtn.title = "Edit List"
        }
    }
    
    // FRC section
    func attemptFetch() {
        let fetchRequest: NSFetchRequest<Garden> = Garden.fetchRequest()
        
        if (self.customOrder == false){
            let dateSort = NSSortDescriptor(key: "dateAdded", ascending: false)
            fetchRequest.sortDescriptors = [dateSort]
        }else{
            let customSort = NSSortDescriptor(key: "orderNo", ascending: true)
            fetchRequest.sortDescriptors = [customSort]
        }
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        self.controller = controller
        
        do {
            try controller.performFetch()
        }catch {
            let error = error as NSError
            print("\(error)")
        }
        self.tableView.reloadData()
    }
    
    
    // controller begin update
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    // controller end update
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // handle controller update
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case.insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break
        case.delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break
        case.update:
            if let indexPath = indexPath {
                let cell = tableView.cellForRow(at: indexPath) as! GardenCell
                configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
            }
            break
        case.move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break
        }
        
    }
    
    // generate sample data
    func generateTestData(){
        
        let garden1 = Garden(context: context)
        garden1.name = "Flowers Garden"
        garden1.latitude = -37.882731
        garden1.longitude = 145.048345
        let picture1 = Image(context: context)
        picture1.image = #imageLiteral(resourceName: "flowerGarden")
        garden1.toImage = picture1
        garden1.sensorNo = 1
        
        let kb1 = KnowledgeBase(context: context)
        kb1.title = "Rose"
        kb1.article = "Roses can withstand a wide range of temperatures.\n\nIn general, hot, dry conditions are preferable to humid conditions.\n\nRoses adopt winter dormancy when temperatures fall below zero at night and less than 10°C in the day.\n\nWith minimum night temperatures of 10°C and correspondingly warmer temperatures of 18°C to 25°C during the day, roses will happily flower non-stop for 12 months of the year, providing they have been watered, fertilized and groomed as required."
        kb1.category = "Plant"
        
        let plant1 = Plant(context: context)
        plant1.name = "Rose"
        let picture3 = Image(context: context)
        picture3.image = #imageLiteral(resourceName: "rose")
        plant1.toImage = picture3
        plant1.toGarden = garden1
        plant1.toKB = kb1
        
        
        let garden2 = Garden(context: context)
        garden2.name = "Vege Garden"
        garden2.latitude = -37.910656
        garden2.longitude = 145.133633
        let picture2 = Image(context: context)
        picture2.image = #imageLiteral(resourceName: "vegeGarden")
        garden2.toImage = picture2
        garden2.sensorNo = 2
        
        
        let kb2 = KnowledgeBase(context: context)
        kb2.title = "Mint"
        kb2.article = "The mints will grow in a wide range of climates as shown by their popularity in home gardens all over Australia.\n\nIdeally, they require plenty of sun, growing best in the long midsummer days of the higher latitudes.\n\nFor this reason, the Australian mint industry has developed mostly in Tasmania, particularly for oil production.\n\nIdeal growing temperatures for mint are warm sunny days (25°C) and cool nights (15°C).\n\nThis is why, in the hotter climates, mint generally grows better in the more shaded areas of the garden."
        kb2.category = "Plant"
        
        let plant2 = Plant(context: context)
        plant2.name = "Mint"
        let picture4 = Image(context: context)
        picture4.image = #imageLiteral(resourceName: "mint")
        plant2.toImage = picture4
        plant2.toGarden = garden2
        plant2.toKB = kb2
        
        ad.saveContext()
    }
}
