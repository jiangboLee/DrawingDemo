//
//  ViewController.swift
//  DrawingDemo
//
//  Created by LEE on 2018/9/1.
//  Copyright © 2018年 LEE. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController {
    
    @IBOutlet weak var lineWidthTextField: UITextField!
    @IBOutlet weak var drawView: UIView!
    
    var pointArr: Array<String> = []
    var plistName: Int = 0
    var imageArr: Array<UIImage> = []
    var timeCount: Double = 0.0
    
    lazy var shaperLayer: CAShapeLayer = {
        let shaperLayer = CAShapeLayer()
        shaperLayer.strokeColor = UIColor.blue.cgColor
        shaperLayer.fillColor = UIColor.clear.cgColor
        shaperLayer.lineJoin = kCALineJoinRound
        shaperLayer.lineCap = kCALineCapRound
        shaperLayer.lineWidth = 10
        return shaperLayer
    }()
    
    var path: UIBezierPath = UIBezierPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lineWidthTextField.delegate = self
        drawView.layer.addSublayer(shaperLayer)
    }
    @IBAction func againClickAction(_ sender: UIButton) {
        self.view.endEditing(true)
    }
    @IBAction func clearClickAction(_ sender: UIButton) {
        self.view.endEditing(true)
        shaperLayer.removeAllAnimations()
        path.removeAllPoints()
        shaperLayer.path = path.cgPath
        pointArr.removeAll()
    }
    
    @IBAction func savePlistAction(_ sender: Any) {
        
        let fm = FileManager.default
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        guard let plistPath = filePath else { return }
        let pPath = (plistPath as NSString).appendingPathComponent("test\(plistName).plist")
        fm.createFile(atPath: plistPath, contents: nil, attributes: nil)
        if pointArr.count > 0 {
            (pointArr as NSArray).write(toFile: pPath, atomically: true)
            plistName += 1
            pointArr.removeAll()
            print("保存成功")
        }
    }

    @IBAction func animationClickAction(_ sender: Any) {
        
        
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        guard let plistPath = filePath else { return }
        let pPath = (plistPath as NSString).appendingPathComponent("test\(plistName - 1).plist")
        let points = NSArray(contentsOfFile: pPath)
        guard let pointsArr = points else { return }
        if pointsArr.count > 0 {
            path.removeAllPoints()
            shaperLayer.path = path.cgPath
            //开始动画
            for i in 0 ..< pointsArr.count {
                guard let pointStr = pointsArr[i] as? String else {return}
                if pointStr == "start" {
                    guard let pointStart = pointsArr[i + 1] as? String else {return}
                    let arr = pointStart.split(separator: "-")
                    path.move(to: CGPoint(x: Double(arr[0]) ?? 0.0, y: Double(arr[1]) ?? 0.0))
                } else {
                    let arr = pointStr.split(separator: "-")
                    path.addLine(to: CGPoint(x: Double(arr[0]) ?? 0.0, y: Double(arr[1]) ?? 0.0))
                }
            }
            shaperLayer.path = path.cgPath
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = Double(pointsArr.count) * 0.005
            animation.repeatCount = Float(CGFloat.greatestFiniteMagnitude)
            animation.fillMode = "both"
            animation.isRemovedOnCompletion = false
            shaperLayer.add(animation, forKey: nil)
            timeCount = Double(pointsArr.count) * 0.005
        }
    }
    
    @IBAction func stopClickAction(_ sender: Any) {
        shaperLayer.removeAllAnimations()
        path.removeAllPoints()
        shaperLayer.path = path.cgPath
        pointArr.removeAll()
    }
    
    @IBAction func createGifAction(_ sender: Any) {
        
        shaperLayer.removeAllAnimations()
        self.imageArr.removeAll()
        
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        CATransaction.setAnimationDuration(timeCount)
        CATransaction.setAnimationDuration(1.0 / 30.0)
        shaperLayer.strokeEnd = 0
        let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { (_) in
            self.shaperLayer.strokeEnd += CGFloat(1.0 / 30.0 / self.timeCount)
            print(self.shaperLayer.strokeEnd)
            CATransaction.commit()
            self.imageArr.append(self.screenImage(self.drawView.bounds.size))
        }
        RunLoop.current.add(timer, forMode: .commonModes)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeCount) {
            timer.invalidate()
            self.creatGif()
        }
    }
    func screenImage(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        drawView.layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    func creatGif() {
        let fm = FileManager.default
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        guard let plistPath = filePath else { return }
        let pPath = (plistPath as NSString).appendingPathComponent("gif")
        try? fm.createDirectory(atPath: pPath, withIntermediateDirectories: true, attributes: nil)
        let gifPath = (pPath as NSString).appendingPathComponent("test\(plistName - 1).gif")
        //创建CFURL对象
        /*
         CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory)
         
         allocator : 分配器,通常使用kCFAllocatorDefault
         filePath : 路径
         pathStyle : 路径风格,我们就填写kCFURLPOSIXPathStyle 更多请打问号自己进去帮助看
         isDirectory : 一个布尔值,用于指定是否filePath被当作一个目录路径解决时相对路径组件
         */
        let url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, gifPath as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
        
        let fileProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
        let gifProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0]]
        //通过一个url返回图像目标
        if let destination = CGImageDestinationCreateWithURL(url!, kUTTypeGIF, imageArr.count, nil) {
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            for photo in imageArr {
                CGImageDestinationAddImage(destination, photo.cgImage!, gifProperties as CFDictionary)
            }
            CGImageDestinationFinalize(destination)
        }
        print("GIF生成成功")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = (touches as NSSet).anyObject() as AnyObject
        let point = view.convert(touch.location(in: self.view), to: drawView)
        print(NSHomeDirectory())
        path.move(to: point)
        pointArr.append("start")
        pointArr.append("\(point.x)-\(point.y)")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = (touches as NSSet).anyObject() as AnyObject
        let point = view.convert(touch.location(in: self.view), to: drawView)
        print(point)
        pointArr.append("\(point.x)-\(point.y)")
        path.addLine(to: point)
        shaperLayer.path = path.cgPath
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if let text = textField.text, let lineWidth = Double(text) {
            shaperLayer.lineWidth = CGFloat(lineWidth)
        }
    }
}

