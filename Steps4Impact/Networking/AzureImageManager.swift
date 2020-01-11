/**
 * Copyright © 2019 Aga Khan Foundation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

import Foundation
import AZSClient.AZSCloudStorageAccount
import AZSClient.AZSCloudBlobContainer
import AZSClient.AZSCloudBlobClient
import AZSClient.AZSCloudBlockBlob

class AzureImageManger {
  private func getContainer() -> AZSCloudBlobContainer {
    var blobContainer: AZSCloudBlobContainer! = nil
    let defaultEndpointsProtocol = "https"

    guard let accountName: String = Bundle.main.object(forInfoDictionaryKey: "Azure Account") as? String
      else { return blobContainer }
    guard let revKey: String = Bundle.main.object(forInfoDictionaryKey: "Azure Key") as? String
      else { return blobContainer }
    let accountKey = String(revKey.reversed())
    let connectionString = "DefaultEndpointsProtocol=\(defaultEndpointsProtocol);AccountName=\(accountName);AccountKey=\(accountKey)"  // swiftlint:disable:this line_length
    do {
      let account: AZSCloudStorageAccount! = try AZSCloudStorageAccount(fromConnectionString: connectionString)
      let blobClient: AZSCloudBlobClient! = account.getBlobClient()
      guard let containerName = Bundle.main.object(forInfoDictionaryKey: "Azure Container Name") as? String
        else { return blobContainer }
      blobContainer = blobClient.containerReference(fromName: containerName)
    } catch {
      NSLog("Error in creating account.")
    }
    return blobContainer
  }

  func uploadImage(image: UIImage, name: String) -> String? {
    let uploadTask: BlobUploadTask = BlobUploadTask(image: image, name: name)
    uploadTask.uploadBlobToContainer()
    return uploadTask.onSuccessName
  }

  class BlobUploadTask {
    var img: UIImage
    var imgName: String
    var onSuccessName: String?

    init(image: UIImage, name: String) {
      img = image
      imgName = name
      onSuccessName = nil
    }

    func uploadBlobToContainer() {
      let defaultEndpointsProtocol = "https"
      guard let accountName: String = Bundle.main.object(forInfoDictionaryKey: "Azure Account") as? String
        else { return }
      guard let revKey: String = Bundle.main.object(forInfoDictionaryKey: "Azure Key") as? String
        else { return }
      let accountKey = String(revKey.reversed())
      let connectionString = "DefaultEndpointsProtocol=\(defaultEndpointsProtocol);AccountName=\(accountName);AccountKey=\(accountKey)" // swiftlint:disable:this line_length
      do {
        let account: AZSCloudStorageAccount! = try AZSCloudStorageAccount(fromConnectionString: connectionString)
        let blobClient: AZSCloudBlobClient! = account.getBlobClient()
        guard let containerName = Bundle.main.object(forInfoDictionaryKey: "Azure Container Name") as? String
          else { return }
        guard let serverURL = Bundle.main.object(forInfoDictionaryKey: "wcb_image_server_url") as? String
        else { return }
        let fullContainerName = "\(serverURL)/\(containerName)"
        let blobContainer: AZSCloudBlobContainer! = blobClient.containerReference(fromName: fullContainerName)
        blobContainer.createContainerIfNotExists { (_, _)  in
          NSLog("Error in creating container.")
        }
        guard let imagePath = Bundle.main.object(forInfoDictionaryKey: "Azure Image Folder") else { return }
        let imagePathName = "\(serverURL)/\(containerName)/\(imagePath)/\(self.imgName).png"
        let blockBlob: AZSCloudBlockBlob! = blobContainer.blockBlobReference(fromName: imagePathName)

        guard let imageData = self.img.pngData() else {
          return
        }
        blockBlob.upload(from: imageData, completionHandler: {(_) -> Void in
          NSLog("Ok, uploaded !")
          NSLog("imagePathName: \(imagePathName)")
          self.onSuccessName = imagePathName
        })
      } catch {
        NSLog("Error in creating account.")
      }
    }
  }
}
