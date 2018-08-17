//
//  NetInfoViewController.swift
//  UIPageViewController Post
//
//  Created by Jeffrey Burt on 2/3/16.
//  Copyright © 2016 Seven Even. All rights reserved.
//

import UIKit

class NetInfoViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var containerView: UIView!
    
    var netInfoPageViewController: NetInfoPageViewController? {
        didSet {
            netInfoPageViewController?.netInfoDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControl.addTarget(self, action: Selector(("didChangePageControlValue")), for: .valueChanged)
    }

    @IBAction func didTapNextButton(sender: UIButton) {
        netInfoPageViewController?.scrollToNextViewController()
    }
    
    /**
     Fired when the user taps on the pageControl to change its current page.
     */
    func didChangePageControlValue() {
        netInfoPageViewController?.scrollToViewController(index: pageControl.currentPage)
    }
}

extension NetInfoViewController: NetInfoPageViewControllerDelegate {
    
    func netInfoPageViewController(netInfoPageViewController: NetInfoPageViewController,
        didUpdatePageCount count: Int) {
        pageControl.numberOfPages = count
    }
    
    func netInfoPageViewController(netInfoPageViewController: NetInfoPageViewController,
        didUpdatePageIndex index: Int) {
        pageControl.currentPage = index
    }
    
}
