//
//  UploadFileInfoResponse.swift
//  Synapps
//
//  Created by Andrey Stepanov on 18.10.2025.
//

import Foundation

struct UploadFileInfoResponse: Identifiable {
  let id: String
  let s3Key: String
  let filename: String
  let mimetype: String
  let size: Int
}
