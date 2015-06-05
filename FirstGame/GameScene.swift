//
//  GameScene.swift
//  FirstGame
//
//  Created by Anton Ulyanov on 03.06.15.
//  Copyright (c) 2015 ANCS. All rights reserved.
//

import SpriteKit
import AVFoundation

struct PhysicsCategory {
    static let None : UInt32 = 0
    static let All : UInt32 = UInt32.max
    static let Monster : UInt32 = 0b1
    static let Projectile : UInt32 = 0b10
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var backgroundMusicPlayer: AVAudioPlayer!
    
    let player = SKSpriteNode(imageNamed: "player")
    var monstersDestroyed = 0
    
    private func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    private func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    override func didMoveToView(view: SKView) {
        playBackgroundMusic("background-music-aac.caf")
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor.whiteColor()
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        self.addChild(player)
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addMonster),
                SKAction.waitForDuration(1.0)
                ])
            ))
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func addMonster() {
        let monster = SKSpriteNode(imageNamed: "monster")
        
        // physics
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
        monster.physicsBody!.dynamic = true
        monster.physicsBody!.categoryBitMask = PhysicsCategory.Monster
        monster.physicsBody!.contactTestBitMask = PhysicsCategory.Projectile
        monster.physicsBody!.collisionBitMask = PhysicsCategory.None
        
        let actualY = random(monster.size.height/2, max: self.size.height - monster.size.height/2)
        monster.position = CGPoint(x: self.size.width - monster.size.width/2, y: actualY)
        
        self.addChild(monster)
        
        let actualDuration = random(CGFloat(2.0), max: CGFloat(4.0))
        let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        let loseAction = SKAction.runBlock() {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    // USER INTERACTION
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        let touch = touches.first as! UITouch
        let touchLocation = touch.locationInNode(self)
        
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        // physics
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.dynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        let offset = touchLocation - projectile.position

        if (offset.x < 0) {
            return
        }
        
        addChild(projectile)
        
        let direction = offset.normalized()
        let shootAmount = direction * 1000
        
        let realDest = shootAmount + projectile.position
        
        let actionMove = SKAction.moveTo(realDest, duration: 1.0)
        let actionMoveDone = SKAction.removeFromParent()
        
        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode!, monster: SKSpriteNode!) {
        println("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        monstersDestroyed++
        if (monstersDestroyed > 30) {
            backgroundMusicPlayer.stop()
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    // SKPhysicsContactDelegate
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
                projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
        }
    }
    
    // AODIO
    
    func playBackgroundMusic(fileName: String!) {
        let url = NSBundle.mainBundle().URLForResource(
            fileName, withExtension: nil)
        if (url == nil) {
            println("Could not find file: \(fileName)")
            return
        }
        
        var error: NSError? = nil
        if backgroundMusicPlayer == nil {
            backgroundMusicPlayer =
                AVAudioPlayer(contentsOfURL: url, error: &error)
            if backgroundMusicPlayer == nil {
                println("Could not create audio player: \(error!)")
                return
            }
        }
        
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    }
}
