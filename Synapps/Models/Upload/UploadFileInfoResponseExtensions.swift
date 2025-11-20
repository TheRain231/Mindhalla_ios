//
//  UploadFileInfoResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 18.10.2025.
//

import Foundation

extension UploadFileInfoResponse {
  init(dto: UploadFileInfoResponseDTO) {
    self.id = dto.id
    self.s3Key = dto.s3Key
    self.filename = dto.filename
    self.mimetype = dto.mimetype
    self.size = dto.size
  }
}
