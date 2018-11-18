//
//  TransactionTableViewController.swift
//  VergeiOS
//
//  Created by Swen van Zanten on 10-09-18.
//  Copyright © 2018 Verge Currency. All rights reserved.
//

import UIKit

class TransactionTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet var addAddressButton: UIButton!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet var repeatTransactionBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var tableView: PlaceholderTableView!
    
    let addressBookManager = AddressBookRepository()
    var scrollViewEdger: ScrollViewEdger!
    
    var transaction: TxHistory?
    var items: [TxHistory] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollViewEdger = ScrollViewEdger(scrollView: tableView)
        scrollViewEdger.hideBottomShadow = true

        DispatchQueue.main.async {
            self.scrollViewEdger.createShadowViews()
            // Select the current transaction.
            self.selectCurrentTransaction()
            self.tableView.setContentOffset(.zero, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let transaction = transaction {
            setTransaction(transaction)
            loadTransactions(transaction)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setTransaction(_ transaction: TxHistory) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateTimeLabel.text = dateFormatter.string(from: transaction.timeReceived)
        
        if let name = addressBookManager.name(byAddress: transaction.address) {
            nameLabel.text = name
            addAddressButton.isHidden = true
        } else {
            nameLabel.text = transaction.address.truncated(limit: 6, position: .tail, leader: "******")
            addAddressButton.isHidden = false
        }
        
        var prefix = ""
        if transaction.category == .Sent {
            navigationItem.setRightBarButton(repeatTransactionBarButtonItem, animated: true)
            amountLabel.textColor = UIColor.vergeRed()
            iconImageView.image = UIImage(named: "Payment")
            
            prefix = "-"
        } else {
            navigationItem.setRightBarButton(nil, animated: true)
            amountLabel.textColor = UIColor.vergeGreen()
            iconImageView.image = UIImage(named: "Receive")
            
            prefix = "+"
        }
        
        amountLabel.text = "\(prefix) \(transaction.amountValue.toCurrency(currency: "XVG", fractDigits: 2))"
    }
    
    func loadTransactions(_ transaction: TxHistory) {
        items = TransactionManager.shared.all(byAddress: transaction.address)
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return transaction?.category == .Sent ? 4 : 3
        }
        
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Transaction Details"
        }
        
        return "Transaction History"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.secondaryDark()
        header.textLabel?.font = UIFont.avenir(size: 17).demiBold()
        header.textLabel?.frame = header.frame
        header.textLabel?.text = header.textLabel?.text?.capitalized
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "transactionDetailCell")!
            
            switch indexPath.row {
            case 0:
                cell.imageView?.image = UIImage(named: "Address")
                cell.textLabel?.text = "Address"
                cell.detailTextLabel?.text = transaction?.address
                cell.accessoryType = .detailButton
                addTapRecognizer(cell: cell, action: #selector(addressDoubleTapped(recognizer:)))
                break
            case 1:
                cell.imageView?.image = UIImage(named: "Confirmations")
                cell.textLabel?.text = "Confirmations"
                cell.detailTextLabel?.text = transaction?.confirmationsCount ?? "Unsynced"
                cell.accessoryType = .none
                break
            case 2:
                cell.imageView?.image = UIImage(named: "Block")
                cell.textLabel?.text = "txid"
                cell.detailTextLabel?.text = transaction?.txid
                cell.accessoryType = .detailButton
                addTapRecognizer(cell: cell, action: #selector(blockDoubleTapped(recognizer:)))
                break
            case 3:
                cell.imageView?.image = UIImage(named: "Memo")
                cell.textLabel?.text = "Memo"
                cell.detailTextLabel?.text = transaction?.memo
                cell.accessoryType = .none
                break
            default:
                break
            }
            
            cell.imageView?.tintColor = UIColor.secondaryLight()
            
            return cell
        }
        
        let cell = Bundle.main.loadNibNamed("TransactionTableViewCell", owner: self, options: nil)?.first as! TransactionTableViewCell
        
        let item = items[indexPath.row]
        
        let recipient = Contact()
        recipient.address = item.address
        recipient.name = nameLabel.text ?? item.address
        
        cell.setTransaction(item)
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewEdger.updateView()
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 {
            return nil
        }

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        }
        
        if items[indexPath.row].txid == transaction?.txid {
            return
        }
        
        transaction = items[indexPath.row]
        setTransaction(transaction!)
        tableView.reloadData()
        selectCurrentTransaction()
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if indexPath.section == 0 && transaction != nil {
            switch indexPath.row {
            case 0:
                loadWebsite(url: "\(Config.blockchainExlorer)address/\(transaction!.address)")
            case 2:
                loadWebsite(url: "\(Config.blockchainExlorer)txid/\(transaction!.txid)")
            default: break
            }
        }
    }
    
    func selectCurrentTransaction() {
        for (index, item) in items.enumerated() {
            if (item.txid == self.transaction?.txid) {
                let indexPath = IndexPath(row: index, section: 1)
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            }
        }
    }

    func repeatTransaction(_ transaction: TxHistory) {
        if self.navigationController?.popViewController(animated: true) == nil {
            self.closeViewController(self)
        }

        DispatchQueue.main.async {
            // Create a send transaction.
            let sendTransaction = SendTransaction()
            sendTransaction.address = transaction.address
            sendTransaction.amount = transaction.amountValue

            // Notify the system to show the send view.
            NotificationCenter.default.post(name: .demandSendView, object: sendTransaction)
        }
    }

    private func loadWebsite(url: String) -> Void {
        if let path: URL = URL(string: url) {
            UIApplication.shared.open(path, options: [:])
        }
    }

    func addTapRecognizer(cell: UITableViewCell, action: Selector) {
        let gesture = UITapGestureRecognizer(target: self, action: action)
        gesture.numberOfTapsRequired = 2

        cell.addGestureRecognizer(gesture)
    }

    @objc func addressDoubleTapped(recognizer: UIGestureRecognizer) {
        UIPasteboard.general.string = transaction!.address
        NotificationManager.shared.showMessage("Address copied!", duration: 3)
    }

    @objc func blockDoubleTapped(recognizer: UITapGestureRecognizer) {
        UIPasteboard.general.string = transaction!.txid
        NotificationManager.shared.showMessage("Txid copied!", duration: 3)
    }

    @IBAction func repeatTransactionPushed(_ sender: Any) {
        if transaction != nil {
            repeatTransaction(transaction!)
        }
    }

    @IBAction func closeViewController(_ sender: Any) {
        self.dismiss(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ContactTableViewController {
            let contact = Contact()
            contact.address = transaction!.address
            vc.contact = contact
        }
    }
}
