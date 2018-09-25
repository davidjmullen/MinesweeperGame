//
//  ViewController.swift
//  MinesweeperGame
//
//  Created by David Mullen on 7/10/18.
//  Copyright © 2018 David Mullen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    let xPickerData = ["5", "6", "7", "8", "9", "10"]
    let yPickerData = ["5", "6", "7", "8", "9", "10"]
    var treasuresPickerData = [String]()
    let modePickerData = [GameMode.classic.rawValue, GameMode.treasure_hunt.rawValue]
    let trapImages = [UIImage(named: "bomb1")!, UIImage(named: "bomb2")!, UIImage(named: "bomb3")!, UIImage(named: "bomb4")!]
    let flowerImages = [UIImage(named: "flowers1")!, UIImage(named: "flowers2")!, UIImage(named: "flowers3")!, UIImage(named: "flowers4")!]
    let waterImages = [UIImage(named: "shore1")!, UIImage(named: "shore2")!, UIImage(named: "shore3")!, UIImage(named: "shore4")!]

    var isGameActive = false
    var treasureMap: Map?
    var xSize:Int = 5
    var ySize:Int = 5
    var treasuresToGenerate = 10
    var gameMode = GameMode.classic
    var maxShovelHealth = 12
    var shovelHealth = 12
    var numberOfClicks = 0
    var treasuresFound = 0
    var xPickerView = UIPickerView()
    var yPickerView = UIPickerView()
    var treasuresPickerView = UIPickerView()
    var modePickerView = UIPickerView()

    enum GameMode: String {
        case classic = "Classic"
        case treasure_hunt = "Treasure Hunt"
    }

    enum MapContent {
        case treasure
        case empty
        case empty_reserved
    }

    @IBOutlet weak var XPickerTextField: UITextField!
    @IBOutlet weak var YPickerTextField: UITextField!
    @IBOutlet weak var TreasuresPickerTextField: UITextField!
    @IBOutlet weak var ModePickerTextField: UITextField!
    @IBOutlet weak var ShovelHealthLabel: UILabel!
    @IBOutlet weak var TreasuresFoundLabel: UILabel!
    @IBOutlet weak var StartGameButton: UIButton!
    @IBOutlet weak var ShovelHealthBar: UIProgressView!
    @IBOutlet weak var TreasuresFoundBar: UIProgressView!
    @IBOutlet weak var ButtonGridBG: UIView!
    @IBOutlet weak var ButtonGrid: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        xPickerView.delegate = self
        xPickerView.dataSource = self
        XPickerTextField.text = xPickerData[0]
        XPickerTextField.inputView = xPickerView

        yPickerView.delegate = self
        yPickerView.dataSource = self
        YPickerTextField.text = yPickerData[0]
        YPickerTextField.inputView = yPickerView

        treasuresPickerView.delegate = self
        treasuresPickerView.dataSource = self
        TreasuresPickerTextField.text = "10"
        TreasuresPickerTextField.inputView = treasuresPickerView
        recalculateMaxTreasures()

        modePickerView.delegate = self
        modePickerView.dataSource = self
        ModePickerTextField.text = modePickerData[0]
        ModePickerTextField.inputView = modePickerView

        let toolbar = UIToolbar(frame: CGRect(x:0, y:self.view.frame.size.height/6, width:self.view.frame.size.width, height:40.0))
        toolbar.layer.position = CGPoint(x:self.view.frame.size.width/2, y:self.view.frame.size.height-20.0)
        toolbar.barStyle = .blackTranslucent
        toolbar.tintColor = .white
        toolbar.backgroundColor = .black

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: true)
        XPickerTextField.inputAccessoryView = toolbar
        YPickerTextField.inputAccessoryView = toolbar
        TreasuresPickerTextField.inputAccessoryView = toolbar
        ModePickerTextField.inputAccessoryView = toolbar

        ShovelHealthBar.transform = ShovelHealthBar.transform.scaledBy(x: 1, y: 8)
        ShovelHealthBar.progress = 1.0
        TreasuresFoundBar.transform = TreasuresFoundBar.transform.scaledBy(x: 1, y: 10)
        TreasuresFoundBar.progress = 0.0
        updateProgressBars()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func donePressed(sender: UIBarButtonItem) {
        XPickerTextField.resignFirstResponder()
        YPickerTextField.resignFirstResponder()
        TreasuresPickerTextField.resignFirstResponder()
        ModePickerTextField.resignFirstResponder()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if XPickerTextField.isFirstResponder {
            DispatchQueue.main.async(execute: {
                (sender as? UIMenuController)?.setMenuVisible(false, animated: false)
            })
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }

    @IBAction func ClickStartGame(_ sender: Any) {
        startNewGame()
    }

    func startNewGame() {
//        ButtonGridView.backgroundColor = .black
        xSize = Int(XPickerTextField.text!)!
        ySize = Int(YPickerTextField.text!)!
        treasuresToGenerate = Int(TreasuresPickerTextField.text!)!
        gameMode = GameMode(rawValue: ModePickerTextField.text!)!
        switch gameMode {
        case .classic:
            maxShovelHealth = xSize * ySize / 3
        case .treasure_hunt:
            maxShovelHealth = xSize * ySize / 2
        }
        shovelHealth = maxShovelHealth
        ShovelHealthBar.progress = 1.0
        numberOfClicks = 0
        treasuresFound = 0
//        let gridWidth = xSize * 32 + ((xSize - 1) * 2)
//        let gridWidth = ((342 / xSize) - ((xSize - 1) * 2))*xSize
//        let gridHeight = ySize * 32 + ((ySize - 1) * 2)
//        let gridHeight = ((342 / ySize) - ((ySize - 1) * 2))*ySize
//        let rowHeight = CGFloat(gridHeight) / CGFloat(ySize)
//        let gridX = (375 - CGFloat(gridWidth)) / 2
//        ButtonGrid.frame = CGRect(x: gridX, y: 2, width: CGFloat(342), height: CGFloat(342))

        for subview in ButtonGrid.subviews {
            subview.removeFromSuperview()
        }
        ButtonGrid.axis = .vertical
        ButtonGrid.alignment = .center
        ButtonGrid.distribution = .fillEqually
        ButtonGrid.spacing = 2.0
        ButtonGrid.contentMode = .scaleAspectFit

        initializeTreasureMap(width: xSize, height: ySize)

        for y in 1...ySize {
            let buttonRow = UIStackView()
            buttonRow.axis = .horizontal
            buttonRow.alignment = .fill
            buttonRow.distribution = .fillEqually
            buttonRow.spacing = 2.0
            buttonRow.contentMode = .scaleAspectFit

            for x in 1...xSize {
                let indexPath = IndexPath(row: y, section: x)
                buttonRow.addArrangedSubview((treasureMap?.mapData[indexPath]?.button)!)
            }
            ButtonGrid.addArrangedSubview(buttonRow)
        }
        ButtonGridBG.addSubview(ButtonGrid)
        ButtonGridBG.backgroundColor = .black
        updateProgressBars()
        isGameActive = true
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == xPickerView {
            return xPickerData.count
        } else if pickerView == yPickerView {
            return yPickerData.count
        } else if pickerView == treasuresPickerView {
            return treasuresPickerData.count
        } else if pickerView == modePickerView {
            return modePickerData.count
        }
        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == xPickerView {
            return xPickerData[row]
        } else if pickerView == yPickerView {
            return yPickerData[row]
        } else if pickerView == treasuresPickerView {
            return treasuresPickerData[row]
        } else if pickerView == modePickerView {
            return modePickerData[row]
        }
        return ""
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == xPickerView {
            XPickerTextField.text = xPickerData[row]
        } else if pickerView == yPickerView {
            YPickerTextField.text = yPickerData[row]
        } else if pickerView == treasuresPickerView {
            TreasuresPickerTextField.text = treasuresPickerData[row]
        } else if pickerView == modePickerView {
            ModePickerTextField.text = modePickerData[row]
        }
    }

    func recalculateMaxTreasures() {
        let totalTiles = Int(XPickerTextField.text!)! * Int(YPickerTextField.text!)!
        let maxPossibleTreasures = totalTiles / 2
        treasuresPickerData.removeAll()
        for i in 5...maxPossibleTreasures {
            treasuresPickerData.append("\(i)")
        }
        if Int(TreasuresPickerTextField.text!)! > maxPossibleTreasures {
            TreasuresPickerTextField.text = "\(maxPossibleTreasures)"
        }
    }

    class ButtonTile {
        var button:UIButton
        var content:MapContent
        var wasClicked:Bool
        var isTrapped:Bool

        init(button: UIButton) {
            self.button = button
            content = .empty
            wasClicked = false
            isTrapped = false
        }
    }

    func createButton(imageName: String) -> UIButton {
        let button = UIButton(type: UIButtonType.custom)
        button.frame(forAlignmentRect: CGRect(x: 0, y: 0, width: 32, height: 32))
//        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        button.setImage(UIImage(named: imageName), for: .normal)
        button.addConstraint(NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: button, attribute: .width, multiplier: 1, constant: 0))
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.imageView?.contentMode = .scaleAspectFit

//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setContentHuggingPriority(UILayoutPriority(rawValue: 780), for: .vertical)
        button.addTarget(self, action: #selector(self.onButtonClick(_:)), for: .touchUpInside)
        return button
    }

    @objc func onButtonClick(_ sender: UIButton) {
        if isGameActive {
            if let buttonTile = treasureMap?.getButtonTile(uiButton:sender) {
                if !buttonTile.wasClicked {
                    numberOfClicks += 1
                    if numberOfClicks == 1 {
                        randomizeTreasureTiles(button: buttonTile.button)
                    }
                    doClickAction(sender: buttonTile)
                    shovelHealth -= 1
                    updateProgressBars()
                    if shovelHealth <= 0 {
                        ShovelHealthLabel.text = "None!"
                        displayGameEndMessage(title: "Game Over!", message: "Your shovel broke!")
                    } else {
                        ShovelHealthLabel.text = String(shovelHealth)
                    }
                }
            }
        }
    }

    func animateTrapButton(button: UIButton) {
        button.setBackgroundImage(UIImage(named: "empty"), for: .normal)
        button.imageView?.animationImages = trapImages
        button.imageView?.animationDuration = 1.0
        button.imageView?.animationRepeatCount = 1
        button.imageView?.startAnimating()
    }

    func animateFlowers(button: UIButton) {
        button.imageView?.animationImages = flowerImages
        button.imageView?.animationDuration = 1.0
        button.imageView?.animationRepeatCount = 0
        button.imageView?.startAnimating()
    }

    func animateWater(button: UIButton) {
        button.imageView?.animationImages = waterImages
        button.imageView?.animationDuration = 1.0
        button.imageView?.animationRepeatCount = 0
        button.imageView?.startAnimating()
    }

    func doClickAction(sender: ButtonTile?) {
        if let buttonTile = sender {
            if !buttonTile.wasClicked {
                buttonTile.wasClicked = true
                buttonTile.button.imageView?.stopAnimating()
                switch buttonTile.content {
                case .empty_reserved:
                    fallthrough
                case .empty:
                    checkNeighborsForTreasure(button:buttonTile.button)
                    if buttonTile.isTrapped {
                        animateTrapButton(button: buttonTile.button)
                        shovelHealth -= 1
                    }
                case .treasure:
                    buttonTile.button.setBackgroundImage(UIImage(named: "empty"), for: .normal)
                    buttonTile.button.setImage(UIImage(named: "money_bag"), for: .normal)
                    treasuresFound += 1
                    updateTreasuresProgressBar()
                    shovelHealth += 1
                    if treasuresFound >= treasuresToGenerate {
                        displayGameEndMessage(title: "You Win!", message: "You found all the treasures!")
                    }
                }
            }
        }
    }

    func displayGameEndMessage(title: String, message: String) {
        isGameActive = false
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func updateProgressBars() {
        ShovelHealthLabel.text = String(shovelHealth)
        ShovelHealthBar.progress = Float(shovelHealth) / Float(maxShovelHealth)
        updateTreasuresProgressBar()
    }

    func updateTreasuresProgressBar() {
        TreasuresFoundLabel.text = "\(treasuresFound)/\(treasuresToGenerate)"
        TreasuresFoundBar.progress = Float(treasuresFound) / Float(treasuresToGenerate)
    }

    func initializeTreasureMap(width: Int, height: Int) {
        var mapData = [IndexPath: ButtonTile]()
        var imageName = "grass"
        let grassThreshold = Double(height) / 2.0
        let dirtThreshold = (Double(height) / 4.0) + grassThreshold
        for y in 1...height {
            for x in 1...width {
                switch Double(y) {
                case 0.0...grassThreshold:
                    imageName = "grass"
                case grassThreshold...dirtThreshold:
                    imageName = "dirt"
                default:
                    let randomizer = Int(arc4random_uniform(UInt32(10)))
                    if randomizer == 0 {
                        imageName = "sand2"
                    } else if randomizer == 1 {
                        imageName = "sand3"
                    } else {
                        imageName = "sand1"
                    }
                }
                let indexPath = IndexPath(row: y, section: x)
                let button = createButton(imageName: imageName)
                if imageName == "grass" {
                    let randomizer = Int(arc4random_uniform(UInt32(8)))
                    if randomizer == 0 {
                        animateFlowers(button: button)
                    }
                }
                mapData[indexPath] = ButtonTile(button: button)
            }
        }
        treasureMap = Map(mapData: mapData)
    }

    class Map {
        var mapData = [IndexPath: ButtonTile]()

        init(mapData: [IndexPath: ButtonTile]) {
            self.mapData = mapData
        }

        func getButtonTile(x: Int, y: Int) -> ButtonTile? {
            let indexPath = IndexPath(row: y, section: x)
            let buttonTile = mapData[indexPath]
            return buttonTile
        }

        func getButtonTile(uiButton: UIButton) -> ButtonTile? {
            var buttonTile:ButtonTile?
            if mapData.contains(where: { (key, value) -> Bool in
                if value.button == uiButton {
                    buttonTile = value
                    return true
                } else {
                    return false
                }
            }) {
            }
            return buttonTile
        }

        func getIndexPath(uiButton: UIButton) -> IndexPath? {
            var indexPath:IndexPath?
            if mapData.contains(where: { (key, value) -> Bool in
                if value.button == uiButton {
                    indexPath = key
                    return true
                } else {
                    return false
                }
            }) {
            }
            return indexPath
        }
    }

    func randomizeTreasureTiles(button: UIButton) {
        let indexPath = treasureMap!.getIndexPath(uiButton: button)!
        let startX = indexPath.section
        let startY = indexPath.row

        for x in startX-1...startX+1 {
            for y in startY-1...startY+1 {
                treasureMap?.getButtonTile(x:x, y:y)?.content = .empty_reserved
            }
        }

        var treasureTiles = treasuresToGenerate;
        while treasureTiles > 0 {
            let randomX = Int(arc4random_uniform(UInt32(xSize))) + 1
            let randomY = Int(arc4random_uniform(UInt32(ySize))) + 1
            let buttonTile = treasureMap?.getButtonTile(x: randomX, y: randomY)
            if buttonTile?.content == .empty {
                buttonTile?.content = .treasure
//                buttonTile?.button.setImage(UIImage(named: "block_tile_treasure.png"), for: .normal)
                treasureTiles -= 1
            }
        }
        if gameMode == .treasure_hunt {
            var trappedTiles = Double(xSize * ySize) * 0.15
            while trappedTiles > 0 {
                let randomX = Int(arc4random_uniform(UInt32(xSize))) + 1
                let randomY = Int(arc4random_uniform(UInt32(ySize))) + 1
                let buttonTile = treasureMap?.getButtonTile(x: randomX, y: randomY)
                if !(buttonTile?.wasClicked)! && buttonTile?.content != .treasure {
                    buttonTile?.isTrapped = true
//                    buttonTile?.button.setImage(UIImage(named: "block_tile_treasure.png"), for: .normal)
                    trappedTiles -= 1.0
                }
            }
        }
    }

    func checkNeighborsForTreasure(button: UIButton) {
        if let indexPath = treasureMap?.getIndexPath(uiButton: button) {
            let xPos = indexPath.section
            let yPos = indexPath.row
            var neighborTreasureCount = 0
            for x in xPos-1...xPos+1 {
                for y in yPos-1...yPos+1 {
                    neighborTreasureCount += tileContainsTreasure(xPos:x, yPos:y)
                }
            }

            if neighborTreasureCount > 0 {
                button.setImage(UIImage(named: "empty_\(neighborTreasureCount)"), for: .normal)
            } else {
                button.setImage(UIImage(named: "empty"), for: .normal)
                if gameMode == .classic {
                    clickNeighborTiles(x: xPos, y: yPos)
                }
            }
        }
    }

    func clickNeighborTiles(x: Int, y:Int) {
        for x in x-1...x+1 {
            for y in y-1...y+1 {
                doClickAction(sender: treasureMap?.getButtonTile(x:x, y:y))
            }
        }
    }

    func tileContainsTreasure(xPos: Int, yPos: Int) -> Int {
        if let buttonTile = treasureMap?.getButtonTile(x: xPos, y: yPos) {
            if buttonTile.content == .treasure {
                return 1
            }
        }
        return 0
    }
    
    
}

class GridComponent: UIStackView {
    private var cells: [UIView] = []
    private var currentRow: UIStackView?
    var rowSize = 5
    var rowHeight = CGFloat(integerLiteral: 5)
    
    init(rowSize: Int, rowHeight: CGFloat) {
        self.rowSize = rowSize
        self.rowHeight = rowHeight
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.axis = .vertical
        self.distribution = .fillEqually
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func prepareRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.distribution = .fillEqually
        return row
    }

    func reset(rowSize: Int, rowHeight: CGFloat) {
        self.rowSize = rowSize
        self.rowHeight = rowHeight
        cells.removeAll()
    }

    func addCell(view: UIView) {
        let firstCellInRow = self.cells.count % self.rowSize == 0
        if self.currentRow == nil || firstCellInRow {
            self.currentRow = self.prepareRow()
            self.addArrangedSubview(self.currentRow!)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: self.rowHeight).isActive = true
        self.cells.append(view)
        self.currentRow!.addArrangedSubview(view)
    }
}
