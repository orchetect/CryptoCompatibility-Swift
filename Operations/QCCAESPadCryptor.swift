//
//  QCCAESPadCryptor.swift
//  CryptoCompatibility
//
//  Translated by OOPer in cooperation with shlab.jp, on 2016/12/6.
//
//
/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    Implements AES encryption and decryption with PKCS#7 padding.
 */

import Foundation

/*! Implements AES encryption and decryption with PKCS#7 padding.
 *  \details In padded AES, the unencrypted data can be of any length wbile the length of the
 *      encrypted data is always an even multiple of the AES block size (`kCCBlockSizeAES128`,
 *      or 16).  Encrypted the data will always increase its length (slightly), while decrypting
 *      it will do the reverse.
 *
 *      This operation supports both EBC and CBC mode.
 *
 *  \warning In most cases you will want to use AES in CBC mode; to do that securely, set the
 *      initialisation vector (via the `ivData` property) to some cryptographically sound
 *      random data.  If you need to use EBC mode, which is generally not recommended, set
 *      the `ivData` property to nil.
 *
 *  \note The designated initialiser for this class is private.  In the unlikely event you
 *      need to subclass it, you will have to make that public.
 *
 *  \note If the data to encrypt or decrypt is too large to fit in memory, take a look at
 *      `QCCAESPadBigCryptor`.
 */

final class QCCAESPadCryptor: Operation {
    
    /*! The error domain for the QCCAESPadCryptor operation.
     *  \details Codes are Common Crypto error codes, that is, `kCCParamError` and its friends.
     */
    
    static let ErrorDomain = "QCCAESPadCryptorErrorDomain"
    
    /*! The data to be encrypted or decrypted.
     *  \details This is set by the init method.
     */
    
    let inputData: Data
    
    /*! The key with which to do the encryption or decryption.
     *  \details This is set by the init method.
     */
    
    let keyData: Data
    
    /*! The initialisation vector for the encryption or decryption.
     *  \details Set this to nil to use EBC mode.  To use CBC mode securely, set this to an
     *      initialisation vector generated by a cryptographically sound random number generator.
     *      Its length must be the AES block size (`kCCBlockSizeAES128`, or 16).
     *
     *      If you set this, you must set it before queuing the operation.
     *
     *  \warning The default value is an initialisation vector all zeroes.  This is not good
     *      from a security standard, although still better than EBC mode.
     */
    
    var ivData: Data?
    
    /*! The error, if any, resulting from encryption or decryption operation.
     *  \details This is set when the operation is finished.  On success, it will be nil.  Or error,
     *      it will hold a value describing that error.  You should expect errors to be in the
     *      `QCCAESPadCryptorErrorDomain` error domain.
     *
     *  \warning Do not expect an error if the data has been corrupted.  The underlying crypto
     *      system does not report errors in that case because it can lead to
     *      padding oracle attacks.  If you need to check whether the data has arrived intact,
     *      use a separate message authentication code (MAC), often generated using HMAC-SHA as
     *      implemented by the QCCHMACSHAAuthentication operation.
     *
     *      <https://en.wikipedia.org/wiki/Padding_oracle_attack>
     */
    
    private(set) var error: Error?
    
    /*! The output data.
     *  \details This is only meaningful when the operation has finished without error.
     *
     *      If this is an encryption operation, this will be the input data encrypted using the
     *      key.  This encrypted data will be slightly longer than the input data, and that length
     *      will always be an even multiple of the AES block size (`kCCBlockSizeAES128`, or 16).
     *
     *      If this is a decryption operation, this will be the input data decrypted using the
     *      key.  This encrypted data can be of any length although it will only be slightly shorter
     *      than the input data.
     */
    
    private(set) var outputData: Data?
    
    private let op: CCOperation
    
    private init(op: CCOperation, input inputData: Data, key keyData: Data) {
        self.op = op
        self.inputData = inputData
        self.keyData = keyData
        self.ivData = Data(count: kCCBlockSizeAES128)
        
        super.init()
        
    }
    
    /*! Initialise the object to encrypt data using a key.
     *  \param inputData The data to encrypt.
     *  \param keyData The key used to encrypt the data; its length must must be one of the
     *      standard AES key sizes (128 bits, `kCCKeySizeAES128`, 16 bytes; 192 bits,
     *      `kCCKeySizeAES192`, 24 bytes; 256 bits, `kCCKeySizeAES256`, or 32 bytes).
     *  \returns The initialised object.
     */
    
    convenience init(toEncryptInput inputData: Data, key keyData: Data) {
        self.init(op: CCOperation(kCCEncrypt), input: inputData, key: keyData)
    }
    
    /*! Initialise the object to decrypt data using a key.
     *  \param inputData The data to decrypt; its length must be an even multiple of the AES
     *      block size (`kCCBlockSizeAES128`, or 16).
     *  \param keyData The key used to decrypt the data; its length must must be one of the
     *      standard AES key sizes (128 bits, `kCCKeySizeAES128`, 16 bytes; 192 bits,
     *      `kCCKeySizeAES192`, 24 bytes; 256 bits, `kCCKeySizeAES256`, or 32 bytes).
     *  \returns The initialised object.
     */
    
    convenience init(toDecryptInput inputData: Data, key keyData: Data) {
        self.init(op: CCOperation(kCCDecrypt), input: inputData, key: keyData)
    }
    
    override func main() {
        var result: Data? = nil
        var resultLength: Int = 0
        
        // We check for common input problems to make it easier for someone tracing through
        // the code to find problems (rather than just getting a mysterious kCCParamError back
        // from CCCrypt).
        
        var err = kCCSuccess
        if self.op == CCOperation(kCCDecrypt) && self.inputData.count % kCCBlockSizeAES128 != 0 {
            err = kCCParamError
        }
        let keyDataLength = self.keyData.count
        if keyDataLength != kCCKeySizeAES128 && keyDataLength != kCCKeySizeAES192 && keyDataLength != kCCKeySizeAES256 {
            err = kCCParamError
        }
        if self.ivData != nil && self.ivData!.count != kCCBlockSizeAES128 {
            err = kCCParamError
        }
        let ivPointer = ivData?.withUnsafeBytes {(ivBytes: UnsafePointer<UInt8>) -> UnsafeMutableRawPointer in
            let ptr = UnsafeMutableRawPointer.allocate(bytes: ivData!.count, alignedTo: 1)
            ptr.initializeMemory(as: UInt8.self, from: ivBytes, count: ivData!.count)
            return ptr
        }
        defer {
            ivPointer?.deallocate(bytes: ivData!.count, alignedTo: 1)
        }
        
        if err == kCCSuccess {
            let padLength: Int
            
            // Padding can expand the data, so we have to allocate space for that.  The rule for block
            // cyphers, like AES, is that the padding only adds space on encryption (on decryption it
            // can reduce space, obviously, but we don't need to account for that) and it will only add
            // at most one block size worth of space.
            
            if self.op == CCOperation(kCCEncrypt) {
                padLength = kCCBlockSizeAES128
            } else {
                padLength = 0
            }
            result = Data(count: self.inputData.count + padLength)
            
            let err32 = keyData.withUnsafeBytes {keyBytes in
                inputData.withUnsafeBytes {bytes in
                    result!.withUnsafeMutableBytes {mutableBytes in
                        CCCrypt(
                            self.op,
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(((self.ivData == nil) ? kCCOptionECBMode : 0) | kCCOptionPKCS7Padding),
                            keyBytes, self.keyData.count,
                            ivPointer,                                  // will be NULL if ivData is nil
                            bytes, self.inputData.count,
                            mutableBytes, result!.count,
                            &resultLength
                        )
                    }
                }
            }
            err = Int(err32)
        }
        if err == kCCSuccess {
            // Set the output length to the value returned by CCCrypt.  This is necessary because
            // we have padding enabled, meaning that we might have allocated more space than we needed
            // (in the encrypt case, this is the space we allocated above for padding; in the decrypt
            // case, the output is actually shorter than the input because the padding is removed).
            result!.count = resultLength
            self.outputData = result
        } else {
            self.error = NSError(domain: QCCAESPadCryptor.ErrorDomain, code: err, userInfo: nil)
        }
    }
    
}
