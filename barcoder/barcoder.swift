//
//  barcoder.swift
//  barcoder
//
//  Created by tinaxd on 2024/04/10.
//

import CoreGraphics

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
    
    open func draw_string(value: String, ctx: CGContext, width: CGFloat, height: CGFloat) -> Result<Array<UInt8>, EncodeError> {
        let encoded = encode_string(value: value)
        switch encoded {
        case .failure(let e):
            return .failure(e)
        case .success(let encoded):
            let widths = self.convert_to_widths(bytes: encoded)
            draw_encoded(widths: widths, ctx: ctx, width: width, height: height)
            return .success(encoded)
        }
    }
    
    public func convert_to_widths(bytes: Array<UInt8>) -> (UInt8, Array<Int>) {
        let start_code = bytes[0];
        var last_code = start_code;
        var last_width = 1;
        var widths = Array<Int>();
        for val in bytes[1...] {
            if val == last_code {
                last_width += 1
            } else {
                widths.append(last_width)
                last_width = 1
                last_code = val
            }
        }
        widths.append(last_width)
        
        return (start_code, widths)
    }
    
    private func draw_encoded(widths: (UInt8, Array<Int>), ctx: CGContext, width: CGFloat, height: CGFloat) {
        let black_color = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        let white_color = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        
        // calculate bar width
        let total_bars = widths.1.reduce(0, {
            (acc, v) -> Int in
            return acc+Int(v)
        })
        let bar_width = width / CGFloat(total_bars)
        
        // initialize draw
        var currentX = 0
        var rectStartX = CGFloat(0)
        var rectStartY = CGFloat(0)
        var currentColorIsBlack = widths.0 == 0 ? false : true
        ctx.setFillColor(currentColorIsBlack ? black_color : white_color)
        
        // draw bars
        for width_count in widths.1 {
            let realWidth = bar_width * CGFloat(width_count)
            ctx.fill(CGRect(x: rectStartX, y: rectStartY, width: realWidth, height: height))
            
            currentX += Int(width_count)
            rectStartX = bar_width * CGFloat(currentX)
            rectStartY = 0.0
            currentColorIsBlack = !currentColorIsBlack
            ctx.setFillColor(currentColorIsBlack ? black_color : white_color)
        }
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
