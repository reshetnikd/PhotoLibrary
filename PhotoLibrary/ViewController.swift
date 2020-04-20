//
//  ViewController.swift
//  PhotoLibrary
//
//  Created by Dmitry Reshetnik on 20.04.2020.
//  Copyright © 2020 Dmitry Reshetnik. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var photos = [Photo]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Photo Library"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPhoto))
        
        let defaults = UserDefaults.standard
        
        if let savedPhotos = defaults.object(forKey: "photos") as? Data {
            let decoder = JSONDecoder()
            
            do {
                photos = try decoder.decode([Photo].self, from: savedPhotos)
            } catch {
                print("Failed to load photos.")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Photo", for: indexPath)
        let photo = photos[indexPath.row]
        let path = getDocumentsDirectory().appendingPathComponent(photo.image)
        cell.imageView?.image = UIImage(contentsOfFile: path.path)
        cell.textLabel?.text = photos[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 1: try loading the "Detail" view controller and typecasting it to be DetailViewController
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            // 2: success! Set its selectedImage property
            vc.selectedImage = getDocumentsDirectory().appendingPathComponent(photos[indexPath.row].image).path
            vc.selectedPictureNumber = indexPath.row + 1
            vc.totalPictures = photos.count
            // 3: now push it onto the navigation controller
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func addNewPhoto() {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func save() {
        let encoder = JSONEncoder()
        if let savedData = try? encoder.encode(photos) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "photos")
        } else {
            print("Failed to save photos.")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        dismiss(animated: true)
        
        let ac = UIAlertController(title: "Name photo", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Cancle", style: .cancel))
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
            guard let newName = ac?.textFields?[0].text else { return }
            let photo = Photo(name: newName, image: imageName)
            self?.photos.append(photo)
            self?.tableView.reloadData()
            self?.save()
        })
        
        present(ac, animated: true)
    }


}

