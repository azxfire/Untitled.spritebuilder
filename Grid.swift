//
//  Grid.swift
//  Untitled
//
//  Created by taowang on 15/9/3.
//  Copyright (c) 2015年 Apportable. All rights reserved.
//

import Foundation
class Grid: CCNodeColor {
    let gridSize = 4
    let startTiles = 2
    var columnWidth : CGFloat = 0
    var columnHeight : CGFloat = 0
    var tileMarginVertical : CGFloat = 0
    var tileMarginHorizontal : CGFloat = 0
    var score: Int = 0{
        didSet{
            var mainScene = parent as! MainScene
            mainScene.scoreLabel.string = "\(score)"
        }
    }
    let winTile = 2048
    var gridArray = [[Title?]]()
    var noTile: Title? = nil
    
    
    func didLoadFromCCB() {
        setupBackground()
        setupGestures()
        for i in 0..<gridSize{
            var column = [Title?]()
            for j in 0..<gridSize{
                column.append(noTile)
            }
            gridArray.append(column)
        }
        spawnSrartTiles()
    }
    
    func setupBackground(){
        var tile = CCBReader.load("Title") as! Title
        columnWidth = tile.contentSize.width
        columnHeight = tile.contentSize.height
        
        tileMarginHorizontal = (contentSize.width - (CGFloat(gridSize) * columnWidth))/CGFloat(gridSize + 1)
        tileMarginVertical = (contentSize.height - (CGFloat(gridSize) * columnHeight)) / CGFloat(gridSize + 1)
        
        var x = tileMarginHorizontal
        var y = tileMarginVertical
        
        for i in 0..<gridSize{
            x = tileMarginHorizontal
            for j in 0..<gridSize{
                var backgroundTile = CCNodeColor.nodeWithColor(CCColor.grayColor())
                backgroundTile.contentSize = CGSize(width: columnWidth, height: columnHeight)
                backgroundTile.position = CGPoint(x: x, y: y)
                addChild(backgroundTile)
                x += columnWidth + tileMarginHorizontal
            }
            y += columnHeight + tileMarginVertical
        }
    }
    func positionForColumn(column:Int, row: Int) -> CGPoint{
        var x = tileMarginHorizontal + CGFloat(column) * (tileMarginHorizontal + columnWidth)
        var y = tileMarginVertical + CGFloat(row) * (tileMarginVertical + columnHeight)
        
        return CGPoint(x: x, y: y)
    }
    func addTitleAtColumn(column : Int, row : Int){
        var title = CCBReader.load("Title")as!Title
        gridArray[column][row] = title
        title.scale = 0
        addChild(title)
        title.position = positionForColumn(column, row: row)
        var delay = CCActionDelay(duration: 0.3)
        var scaleUp = CCActionScaleTo(duration: 0.2,scale: 1)
        var sequence = CCActionSequence(array: [delay, scaleUp])
        title.runAction(sequence)
        
    }
    func spawnRandomTitle(){
        var spawned = false
        while !spawned{
            let randomRow = Int(CCRANDOM_0_1() * Float(gridSize))
            let randomColumn = Int(CCRANDOM_0_1()  * Float(gridSize))
            let positionFree = gridArray[randomColumn][randomRow] == noTile
            if positionFree{
                addTitleAtColumn(randomColumn, row: randomRow)
                spawned = true
            }
        }
    }
    func spawnSrartTiles(){
        for i in 0..<startTiles{
            spawnRandomTitle()
        }
    }
    func setupGestures(){
        var swipeLeft = UISwipeGestureRecognizer(target: self, action: "swipeLeft")
        swipeLeft.direction = .Left
        CCDirector.sharedDirector().view.addGestureRecognizer(swipeLeft)
        
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "swipeRight")
        swipeRight.direction = .Right
        CCDirector.sharedDirector().view.addGestureRecognizer(swipeRight)
        
        var swipeUp = UISwipeGestureRecognizer(target: self, action: "swipeUp")
        swipeUp.direction = .Up
        CCDirector.sharedDirector().view.addGestureRecognizer(swipeUp)
        
        var swipeDown = UISwipeGestureRecognizer(target: self, action: "swipeDown")
        swipeDown.direction = .Down
        CCDirector.sharedDirector().view.addGestureRecognizer(swipeDown)
    }
    func swipeLeft(){
        move(CGPoint(x: -1, y: 0))
    }
    func swipeRight(){
        move(CGPoint(x: 1, y: 0))
    }
    func swipeUp(){
        move(CGPoint(x: 0, y: 1))
    }
    func swipeDown(){
        move(CGPoint(x: 0, y: -1))
    }
    func move(direction: CGPoint) {
        var movedTilesThisRound = false
        // apply negative vector until reaching boundary, this way we get the tile that is the furthest away
        // bottom left corner
        var currentX = 0
        var currentY = 0
        // Move to relevant edge by applying direction until reaching border
        while indexValid(currentX, y: currentY) {
            var newX = currentX + Int(direction.x)
            var newY = currentY + Int(direction.y)
            if indexValid(newX, y: newY) {
                currentX = newX
                currentY = newY
            } else {
                break
            }
        }
        // store initial row value to reset after completing each column
        var initialY = currentY
        // define changing of x and y value (moving left, up, down or right?)
        var xChange = Int(-direction.x)
        var yChange = Int(-direction.y)
        if xChange == 0 {
            xChange = 1
        }
        if yChange == 0 {
            yChange = 1
        }
        // visit column for column
        while indexValid(currentX, y: currentY) {
            while indexValid(currentX, y: currentY) {
                // get tile at current index
                if let tile = gridArray[currentX][currentY] {
                    // if tile exists at index
                    var newX = currentX
                    var newY = currentY
                    // find the farthest position by iterating in direction of the vector until reaching boarding of
                    // grid or occupied cell
//                    while indexValid(newX+Int(direction.x), y: newY+Int(direction.y)) {
//                        newX += Int(direction.x)
//                        newY += Int(direction.y)
//                    }
                    while indexValidAndUnoccupied(newX+Int(direction.x), y: newY+Int(direction.y)){
                        newX += Int(direction.x)
                        newY += Int(direction.y)
                    }
                    var performMove = false
                    // If we stopped moving in vector direction, but next index in vector direction is valid, this
                    // means the cell is occupied. Let's check if we can merge them...
                    if indexValid(newX+Int(direction.x), y: newY+Int(direction.y)) {
                        // get the other tile
                        var otherTileX = newX + Int(direction.x)
                        var otherTileY = newY + Int(direction.y)
                        if let otherTile = gridArray[otherTileX][otherTileY] {
                            // compare the value of other tile and also check if the other tile has been merged this round
                            if tile.value == otherTile.value && !otherTile.mergedThisRound {
                                mergeTilesAtindex(currentX, y: currentY, withTileAtIndex: otherTileX, y: otherTileY)
                                 movedTilesThisRound = true
                            } else {
                                // we cannot merge so we want to perform a move
                                performMove = true
                            }
                        }
                    } else {
                        // we cannot merge so we want to perform a move
                        performMove = true
                    }
                    if performMove {
                        // move tile to furthest position
                        if newX != currentX || newY != currentY {
                            // only move tile if position changed
                            moveTile(tile, fromX: currentX, fromY: currentY, toX: newX, toY: newY)
                             movedTilesThisRound = true
                        }
                    }
//                    if newX != currentX || newY != currentY {
//                        moveTile(tile, fromX: currentX, fromY: currentY, toX: newX, toY: newY)
//                    }
                }
                // move further in this column
                currentY += yChange
            }
            currentX += xChange
            currentY = initialY
        }
        if movedTilesThisRound {
//            spawnRandomTitle()
            nextRound()
        }
    }
    func indexValid(x: Int, y: Int) -> Bool {
        var indexValid = true
        indexValid = (x >= 0) && (y >= 0)
        if indexValid {
            indexValid = x < Int(gridArray.count)
            if indexValid {
                indexValid = y < Int(gridArray[x].count)
            }
        }
        return indexValid
    }
    func moveTile(tile: Title, fromX: Int, fromY: Int, toX: Int, toY: Int) {
        gridArray[toX][toY] = gridArray[fromX][fromY]
        gridArray[fromX][fromY] = noTile
        var newPosition = positionForColumn(toX, row: toY)
        var moveTo = CCActionMoveTo(duration: 0.2, position: newPosition)
        tile.runAction(moveTo)
    }
    func indexValidAndUnoccupied(x: Int, y: Int) -> Bool {
        var indexValid = self.indexValid(x, y: y)
        if !indexValid {
            return false
        }
        // unoccupied?
        return gridArray[x][y] == noTile
    }
    func mergeTilesAtindex(x: Int, y: Int, withTileAtIndex otherX: Int, y otherY: Int) {
        // Update game data
        var mergedTile = gridArray[x][y]!
        var otherTile = gridArray[otherX][otherY]!
        score += mergedTile.value + otherTile.value;
        otherTile.mergedThisRound = true
        gridArray[x][y] = noTile
        
        // Update the UI
        var otherTilePosition = positionForColumn(otherX, row: otherY)
        var moveTo = CCActionMoveTo(duration:0.2, position: otherTilePosition)
        var remove = CCActionRemove()
        var mergeTile = CCActionCallBlock(block: { () -> Void in
            otherTile.value *= 2
        })
        var checkWin = CCActionCallBlock(block: { () -> Void in
            if otherTile.value == self.winTile {self.win()}
        })
        var sequence = CCActionSequence(array: [moveTo, mergeTile, checkWin, remove])
        mergedTile.runAction(sequence)
    }
    func win() {
        endGameWithMessage("You win!")
    }
    func lose() {
        endGameWithMessage("You lose!")
    }
    func endGameWithMessage(message: String) {
        
        var gameEndPopover = CCBReader.load("GameEnd") as! GameEnd
        gameEndPopover.positionType = CCPositionType(xUnit: .Normalized, yUnit: .Normalized, corner: .BottomLeft)
        gameEndPopover.position = ccp(0.5, 0.5)
        gameEndPopover.zOrder = Int.max
        gameEndPopover.setMessage(message, score: score)
        addChild(gameEndPopover)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var highscore = defaults.integerForKey("highscore")
        if score > highscore {
            defaults.setInteger(score, forKey: "highscore")
        }
//        println(message)
    }
    func nextRound(){
        spawnRandomTitle()
        for column in gridArray{
            for title in column{
                title?.mergedThisRound = false
            }
        }
        if !movePossible() {
            lose()
        }
    }
    func movePossible() -> Bool {
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                if let tile = gridArray[i][j] {
                    var topNeighbor = tileForIndex(i, y: j+1)
                    var bottomNeighbor = tileForIndex(i, y: j-1)
                    var leftNeighbor = tileForIndex(i-1, y: j)
                    var rightNeighbor = tileForIndex(i+1, y: j)
                    var neighbors = [topNeighbor, bottomNeighbor, leftNeighbor, rightNeighbor]
                    for neighbor in neighbors {
                        if let neighborTile = neighbor {
                            if neighborTile.value == tile.value {
                                return true
                            }
                        }
                    }
                } else { // empty space on the grid
                    return true
                }
            }
        }
        return false
    }
    func tileForIndex(x: Int, y: Int) -> Title? {
        return indexValid(x, y: y) ? gridArray[x][y] : noTile
    }
    

}
