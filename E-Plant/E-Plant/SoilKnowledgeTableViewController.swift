//
//  SoilKnowledgeTableViewController.swift
//  E-Plant
//
//  Created by 郁雨润 on 25/10/17.
//  Copyright © 2017 Monash University. All rights reserved.
//

import UIKit
import CoreData

class SoilKnowledgeTableViewController: UITableViewController,UISearchBarDelegate,addKnowledgeDelegate{
    
    
    var KnowledgeBaseList: [KnowledgeBase]?
    var filteredKnowledgeList: [KnowledgeBase]?
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?
    var newKnowledge: NewKnowledge?
    
    var path:Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.persistentContainer.viewContext
        fetchAllKnowledges() //get all soil knowledge from db
        
        // if no item in the db, create sample data
       if filteredKnowledgeList?.count == 0 {
          print("test11111")
          createDefaultItems()
          fetchAllKnowledges()
       }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    // set number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    // set number of rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let count = filteredKnowledgeList?.count {
            return count
        }
        
        return 0;
    }
    
    
    // setting the cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: "SoilKnowledgeCell", for: indexPath) as! soilKnowledgeCell
          let knowledge = filteredKnowledgeList![indexPath.row]
          cell.titleLabel.text = knowledge.title
          return cell
       
    }
    
    // pass the data before jump to that view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "soilKnowledgeDetail") {
            let selectedCategory = filteredKnowledgeList![(tableView.indexPathForSelectedRow?.row)!]
            let destination: SoilKnowledgeViewController = segue.destination as! SoilKnowledgeViewController
            destination.knowledge = selectedCategory
        }
            
        else if(segue.identifier == "addSoilKnowledge"){
            let destination: AddSoilKnowledgeViewController = segue.destination.childViewControllers[0] as! AddSoilKnowledgeViewController
            destination.delegate = self
        }
        
        
        
    }
    
    // delete item function
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            managedContext?.delete(filteredKnowledgeList![indexPath.row])
            filteredKnowledgeList!.remove(at: indexPath.row)
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.reloadSections(NSIndexSet(index:0) as IndexSet, with: .fade)
            do{
                try managedContext?.save()
            }
            catch let error{
                print("Could not save: \(error)")
            }
        }
        
        
    }
    
    
    // create a category
    func createManagedCategory(name: String) -> Category {
        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedContext!) as! Category
        category.name = name
       
        return category
    }

    
    
    // create a knowledge
    func createManagedKnowledge(title: String,category: String, article:String) -> KnowledgeBase {
        let knowledge = NSEntityDescription.insertNewObject(forEntityName: "KnowledgeBase", into: managedContext!) as! KnowledgeBase
        knowledge.title = title
        knowledge.article = article
        knowledge.category = category
        return knowledge
    }
    
    
    // create sample data
    func createDefaultItems() {
        let soil = createManagedCategory(name: "Soil")
        soil.addToMembers(createManagedKnowledge(title: "Soil Knowledge 1", category: "Soil", article: "Bark, ground: made from various tree barks. ..."))
          soil.addToMembers(createManagedKnowledge(title: "Soil Knowledge 2", category: "Soil", article: "BCompost: excellent conditioner.\n\nLeaf mold: decomposed leaves that add nutrients and structure to soil.\n\nLime: raises the pH of acid soil and helps loosen clay soil."))
          soil.addToMembers(createManagedKnowledge(title: "Soil Knowledge 3", category: "Soil", article: "Manure: best if composted\n\nPeat moss: conditioner that helps soil retain water"))
        appDelegate?.saveContext()
    }
    
    
    // get all soil knowledge from db
    func fetchAllKnowledges() {
        let knowledgeFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "KnowledgeBase")
        
        do {
            KnowledgeBaseList = try managedContext?.fetch(knowledgeFetch) as? [KnowledgeBase]
            filteredKnowledgeList = KnowledgeBaseList?.filter({ (knowledge) -> Bool in return
                (knowledge.category?.contains("Soil"))!})
        } catch {
            fatalError("Failed to fetch Knowledge Base: \(error)")
        }
    }
    
    // add knowledge to db
    func addKnowledge(knowledge:NewKnowledge){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.persistentContainer.viewContext
        let knowledge1 = NSEntityDescription.insertNewObject(forEntityName: "KnowledgeBase", into: managedContext!) as! KnowledgeBase
        knowledge1.title = knowledge.title
        knowledge1.category = knowledge.category
        knowledge1.article = knowledge.article
        appDelegate.saveContext()
        
        fetchAllKnowledges()
        self.tableView.reloadData()
    }
    
    // go back to previous view page
    @IBAction func backbutton(_ sender: UIBarButtonItem) {
        // Dismiss the view controller depending on the context it was presented
        let isPresentingInAddMode = presentingViewController is UITabBarController
        print("test11111111")
        if isPresentingInAddMode {
            print("test222222")
            dismiss(animated: true, completion: nil)
        } else {
            print("test33333")
            navigationController!.popViewController(animated: true)
        }
        
    }
    

    
}
