//
//  MoviesViewController.swift
//  flicks
//
//  Created by 徐旻威 on 2/5/17.
//  Copyright © 2017 Minwei Xu. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkAlert: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [NSDictionary]?
    var filteredMovies: [NSDictionary]?
    
    func loadDatafromNetwork(_ refreshControl: UIRefreshControl) {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            MBProgressHUD.hide(for: self.view, animated: true)

            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    self.movies = dataDictionary["results"] as? [NSDictionary]
                    self.filteredMovies = dataDictionary["results"] as? [NSDictionary]
                    self.tableView.reloadData()
                    refreshControl.endRefreshing()
                    self.networkAlert.isHidden = true
                } else {
                    self.networkAlert.isHidden = false
                }
            } else {
                self.networkAlert.isHidden = false
            }
        }
        task.resume()

    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {        self.searchBar.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(loadDatafromNetwork(_:)), for: UIControlEvents.valueChanged)
        // add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
        
        loadDatafromNetwork(refreshControl)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = filteredMovies {
            return movies.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = filteredMovies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        let posterPath = movie["poster_path"] as! String
        
        let baseUrl = "http://image.tmdb.org/t/p/w342"
        let imageUrl = NSURL(string: baseUrl + posterPath)
        
        cell.titleLabel?.text = title
        cell.overviewLabel?.text = overview
        let imageRequest = NSURLRequest(url: imageUrl as! URL)
        
        cell.posterView.setImageWith(
            imageRequest as URLRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                    })
                } else {
                    cell.posterView.image = image
                }
        },
            failure: { (imageRequest, imageResponse, error) -> Void in
                self.networkAlert.isHidden = false
        })
        return cell
    }
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredMovies = searchText.isEmpty ? movies : movies?.filter({(movie: NSDictionary) -> Bool in
            let title = movie["title"] as! String
            return title.range(of: searchText, options: .caseInsensitive) != nil
        })
        
        tableView.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
