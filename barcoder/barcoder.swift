//
//  barcoder.swift
//  barcoder
//
//  Created by tinaxd on 2024/04/10.
//

public enum EncodeError: Error {
    case UnencodableCharacter
}

public enum BarcoderError: Error {
    case InvalidConfiguration
}

open class Barcoder {
    var use_code_b: Bool
    
    public init(use_code_b: Bool) throws {
        self.use_code_b = use_code_b
        
        if (!self.use_code_b) {
            throw BarcoderError.InvalidConfiguration
        }
    }
    
    open func encode_string(value: String) -> Result<Array<UInt8>, EncodeError> {
        return self.encode_b(value: value);
    }
    
    private func encode_b(value: String) -> Result<Array<UInt8>, EncodeError> {
        var encoded = Array<UInt8>();
        
        // start code
        encoded += code128_patterns[code128_IDX_START_B];
        
        // encode body
        var checksum = code128_IDX_START_B;
        for (i, ch) in value.enumerated() {
            let idx = code128_B[ch];
            if let idx = idx {
                encoded += code128_patterns[idx];
                
                // update checksum
                checksum += (i+1) * idx;
                checksum %= 103;
            } else {
                return .failure(.UnencodableCharacter)
            }
        }
        
        // append checksum
        encoded += code128_patterns[checksum];
        
        // stop code
        encoded += code128_patterns[code128_IDX_STOPCODE];
        
        return .success(encoded);
    }
}
