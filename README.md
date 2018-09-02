# DrawingDemo
屏幕上画画生成动画，并可以将点保存成plist文件和GIF

![1.gif](https://upload-images.jianshu.io/upload_images/2868618-7ecc14e0e205298d.gif?imageMogr2/auto-orient/strip)

#### 项目文件目录
![Snip20180902_1.png](https://upload-images.jianshu.io/upload_images/2868618-6bab36f029861e16.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
可以拿着plist文件到任何项目再生成路径地址
![test0.gif](https://upload-images.jianshu.io/upload_images/2868618-87feb20022c79aa8.gif?imageMogr2/auto-orient/strip)

![test1.gif](https://upload-images.jianshu.io/upload_images/2868618-22771cc21e8b022f.gif?imageMogr2/auto-orient/strip)

![test2.gif](https://upload-images.jianshu.io/upload_images/2868618-5064168973a57327.gif?imageMogr2/auto-orient/strip)

![test3.gif](https://upload-images.jianshu.io/upload_images/2868618-9de219a26069f741.gif?imageMogr2/auto-orient/strip)

![test4.gif](https://upload-images.jianshu.io/upload_images/2868618-329c85ca92330d43.gif?imageMogr2/auto-orient/strip)

#### 核心代码
```
///路径保存成plist
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
```
```
///从plist读取生成动画
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
```
```
///生成GIF
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

```
