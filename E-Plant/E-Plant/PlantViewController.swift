//
//  PlantViewController.swift
//  E-Plant
//
//  Created by 郁雨润 on 25/10/17.
//  Copyright © 2017 Monash University. All rights reserved.
//

import UIKit

class PlantViewController: UIViewController {

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var articleField: UITextView!
    var knowledge: KnowledgeBase!
    
    // set the items by using the passed data knowledge object
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = knowledge.title
        articleField.text = knowledge.article
        articleField.isScrollEnabled = false
        articleField.isScrollEnabled = true

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   // go back to previous view
    @IBAction func BackButton(_ sender: UIBarButtonItem) {
        // Dismiss the view controller depending on the context it was presented
        let isPresentingInAddMode = presentingViewController is UITabBarController
        if isPresentingInAddMode {
            print("test111111")
            dismiss(animated: true, completion: nil)
        } else {
            print("test22222")
            
            navigationController!.popViewController(animated: true)
        }

    }
    
}
