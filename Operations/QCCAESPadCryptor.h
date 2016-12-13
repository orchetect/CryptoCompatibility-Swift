/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Implements AES encryption and decryption with PKCS#7 padding.
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

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

@interface QCCAESPadCryptor : NSOperation

/*! Initialise the object to encrypt data using a key.
 *  \param inputData The data to encrypt.
 *  \param keyData The key used to encrypt the data; its length must must be one of the 
 *      standard AES key sizes (128 bits, `kCCKeySizeAES128`, 16 bytes; 192 bits, 
 *      `kCCKeySizeAES192`, 24 bytes; 256 bits, `kCCKeySizeAES256`, or 32 bytes).
 *  \returns The initialised object.
 */

- (instancetype)initToEncryptInputData:(NSData *)inputData keyData:(NSData *)keyData;

/*! Initialise the object to decrypt data using a key.
 *  \param inputData The data to decrypt; its length must be an even multiple of the AES 
 *      block size (`kCCBlockSizeAES128`, or 16).
 *  \param keyData The key used to decrypt the data; its length must must be one of the 
 *      standard AES key sizes (128 bits, `kCCKeySizeAES128`, 16 bytes; 192 bits, 
 *      `kCCKeySizeAES192`, 24 bytes; 256 bits, `kCCKeySizeAES256`, or 32 bytes).
 *  \returns The initialised object.
 */

- (instancetype)initToDecryptInputData:(NSData *)inputData keyData:(NSData *)keyData;

- (instancetype)init NS_UNAVAILABLE;

/*! The data to be encrypted or decrypted.
 *  \details This is set by the init method.
 */

@property (atomic, copy,   readonly ) NSData *      inputData;

/*! The key with which to do the encryption or decryption.
 *  \details This is set by the init method.
 */

@property (atomic, copy,   readonly ) NSData *      keyData;

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

@property (atomic, copy,   readwrite, nullable) NSData *      ivData;

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

@property (atomic, copy,   readonly, nullable) NSError *    error;

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

@property (atomic, copy,   readonly, nullable) NSData *     outputData;

@end

/*! The error domain for the QCCAESPadCryptor operation.
 *  \details Codes are Common Crypto error codes, that is, `kCCParamError` and its friends.
 */

extern NSString * QCCAESPadCryptorErrorDomain;

NS_ASSUME_NONNULL_END
