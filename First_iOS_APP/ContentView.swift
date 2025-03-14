import SwiftUI
import GameplayKit
import AVFoundation  // 添加這行

struct ContentView: View {
    @State private var birdPosition = CGPoint(x: 100, y: 300)
    @State private var pipes: [(CGFloat, CGFloat)] = []
    @State private var pipePositions: [CGFloat] = []  // Add this line
    @State private var gameTimer: Timer?
    @State private var isGameOver = false
    @State private var score = 0
    @State private var velocity: CGFloat = 0
    @State private var audioPlayer: AVAudioPlayer?  // 添加這行
    @State private var isGameStarted = false  // 新增這行
    @State private var scoredPipes: Set<Int> = []  // 新增這行來追蹤已計分的管道
    private let gravity: CGFloat = 0.7
    private let jumpForce: CGFloat = -10
    
    var body: some View {
        ZStack {
            if (!isGameStarted) {
                Image("小桃桌面有標題")
                    .resizable()
                    .scaledToFill()
                    .offset(x: -32)  // 向左偏移 50 點
                    .clipped()  // 確保超出部分被裁剪
                    .edgesIgnoringSafeArea(.all)
            } else {
                Image("chiikawa_background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                ForEach(0..<pipes.count, id: \.self) { index in
                    Group {
                        // Top pipe
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(red: 1, green: 0.9, blue: 0.7))
                                .frame(width: 60, height: pipes[index].0)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .opacity(pipes[index].0 > 0 ? 1 : 0)  // 只在有高度時顯示邊框
                                )
                            Ellipse()  // 底部橢圓
                                .fill(Color(red: 1, green: 0.9, blue: 0.7))
                                .frame(width: 60, height: 20)
                                .overlay(
                                    Ellipse()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .offset(y: -10)  // 向下移動 10 點
                        }
                        .position(x: pipePositions[index], y: pipes[index].0 / 2)
                        
                        // Bottom pipe
                        ZStack(alignment: .top) {  // 改用 ZStack
                            Rectangle()
                                .fill(Color(red: 1, green: 0.9, blue: 0.7))
                                .frame(width: 60, height: pipes[index].1)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .opacity(pipes[index].1 < UIScreen.main.bounds.height ? 1 : 0)
                                )
                            
                            Ellipse()
                                .fill(Color(red: 1, green: 0.9, blue: 0.7))
                                .frame(width: 60, height: 20)
                                .overlay(
                                    Ellipse()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .offset(y: -10)
                                .zIndex(1)  // 確保橢圓形在上層
                        }
                        .position(x: pipePositions[index], y: UIScreen.main.bounds.height - pipes[index].1 / 2)
                    }
                }
                
                Image("小桃-removebg-preview")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)  // 將 50x50 改為 200x200
                    .scaleEffect(x: -1, y: 1)  // 水平翻轉
                    .position(birdPosition)
                
                Text("Score: \(score)")
                    .font(.largeTitle)
                    .bold()  // 添加這行
                    .foregroundColor(.black)  // 添加這行
                    .position(x: 100, y: 100)  // 將 y 值從 50 改為 100
                
                if isGameOver {
                    Text("Game Over!\nTap to restart")
                        .font(.largeTitle)
                        .bold()  // 添加這行
                        .foregroundColor(.black)  // 添加這行
                        .multilineTextAlignment(.center)
                }
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    if !isGameStarted {
                        isGameStarted = true
                        startGame()
                    } else if isGameOver {
                        restartGame()
                    } else {
                        jump()
                    }
                }
        )
        .onAppear {
            startGame()
        }
    }
    
    private func startGame() {
        pipes = []
        pipePositions = []  // Add this line
        score = 0
        isGameOver = false
        birdPosition = CGPoint(x: 100, y: 300)
        velocity = 0
        scoredPipes.removeAll()  // 重置已計分的管道記錄
        
        // Generate initial pipes
        for i in 0...3 {
            let gap = CGFloat.random(in: 200...400)
            let topHeight = CGFloat.random(in: 100...500)
            pipes.append((topHeight, 800 - topHeight - gap))
            pipePositions.append(CGFloat(i) * 300 + 400)  // Add this line
        }
        
        // 播放背景音樂
        do {
            if let path = Bundle.main.path(forResource: "uuwawauwa", ofType: "mp4") {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.numberOfLoops = -1  // 無限循環播放
                audioPlayer?.play()
            }
        } catch {
            print("Could not find and play the sound file.")
        }
        
        // Start game loop
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateGame()
        }
    }
    
    private func updateGame() {
        // Update bird position
        velocity += gravity
        birdPosition.y += velocity
        
        // Move pipes
        for i in 0..<pipes.count {
            pipePositions[i] -= 3
            if pipePositions[i] < -30 {
                let gap = CGFloat.random(in: 200...400)
                let topHeight = CGFloat.random(in: 100...500)
                pipes[i] = (topHeight, 800 - topHeight - gap)
                pipePositions[i] = 1200
            }
        }
        
        // Check collisions
        if checkCollision() {
            endGame()
        }
        
        // Update score - 替換原本的計分邏輯
        for i in 0..<pipes.count {
            if !scoredPipes.contains(i) && // 確保這個管道還沒計過分
               pipePositions[i] < birdPosition.x - 30 { // 當角色完全通過管道時
                score += 1
                scoredPipes.insert(i)
            }
            
            // 當管道重置位置時，也重置其計分狀態
            if pipePositions[i] >= 1200 {
                scoredPipes.remove(i)
            }
        }
    }
    
    private func checkCollision() -> Bool {
        // Check if bird hits the ground or ceiling
        if birdPosition.y < 0 || birdPosition.y > UIScreen.main.bounds.height {  // 這裡也要修改
            return true
        }
        
        // Check if bird hits pipes
        for i in 0..<pipes.count {
            if abs(pipePositions[i] - birdPosition.x) < 30 {
                if birdPosition.y < pipes[i].0 || birdPosition.y > UIScreen.main.bounds.height - pipes[i].1 {  // 這裡也要修改
                    return true
                }
            }
        }
        
        return false
    }
    
    private func jump() {
        velocity = jumpForce
    }
    
    private func endGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        isGameOver = true
        audioPlayer?.stop()
    }
    
    private func restartGame() {
        isGameStarted = true  // 新增這行
        startGame()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
