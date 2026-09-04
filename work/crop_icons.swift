import Foundation
import ImageIO
import CoreGraphics

let sourceURL = URL(fileURLWithPath: "/Volumes/SSD/meta/EXpressMeta/outputs/home_quick_services.png")
let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let crops: [(String, Int, Int, Int, Int)] = [
  ("quick_large", 100, 70, 280, 230),
  ("quick_fee", 470, 70, 280, 230),
  ("quick_prohibited", 800, 70, 280, 230),
  ("quick_support", 1150, 70, 280, 230)
]
for (name, x, y, width, height) in crops {
  let crop = image.cropping(to: CGRect(x: x, y: y, width: width, height: height))!
  let url = URL(fileURLWithPath: "/Volumes/SSD/meta/EXpressMeta/features/business_home/src/main/resources/base/media/\(name).png")
  let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
  CGImageDestinationAddImage(destination, crop, nil)
  CGImageDestinationFinalize(destination)
}
