#| ****************************************************************************
 * Copyright (c) Llewellyn Pritchard. 2007,2008,2009
 *
 * This source code is subject to terms and conditions of the Microsoft Public License. 
 * A copy of the license can be found in the License.html file at the root of this distribution. 
 * By using this source code in any fashion, you are agreeing to be bound by the terms of the 
 * Microsoft Public License.
 *
 * You must not remove this notice, or any other, from this software.
 * ***************************************************************************|#

(library (ironscheme bytevectors)
  (export
  
    endianness
    native-endianness
    bytevector?
    make-bytevector
    bytevector-length
    bytevector=?
    bytevector-fill!
    bytevector-copy!
    bytevector-copy
    
    bytevector-u8-ref
    bytevector-s8-ref
    bytevector-u8-set!
    bytevector-s8-set!
    
    bytevector->u8-list
    u8-list->bytevector
    
    bytevector-uint-ref
    bytevector-sint-ref
    bytevector-uint-set!
    bytevector-sint-set!
    
    bytevector->uint-list
    bytevector->sint-list
    uint-list->bytevector
    sint-list->bytevector
    
    bytevector-u16-ref
    bytevector-s16-ref
    bytevector-u16-native-ref
    bytevector-s16-native-ref
    bytevector-u16-set!
    bytevector-s16-set!
    bytevector-u16-native-set!
    bytevector-s16-native-set!
    
    bytevector-u32-ref
    bytevector-s32-ref
    bytevector-u32-native-ref
    bytevector-s32-native-ref
    bytevector-u32-set!
    bytevector-s32-set!
    bytevector-u32-native-set!
    bytevector-s32-native-set!
    
    bytevector-u64-ref
    bytevector-s64-ref
    bytevector-u64-native-ref
    bytevector-s64-native-ref
    bytevector-u64-set!
    bytevector-s64-set!
    bytevector-u64-native-set!
    bytevector-s64-native-set!
    
    bytevector-ieee-single-native-ref
    bytevector-ieee-single-ref
    bytevector-ieee-double-native-ref
    bytevector-ieee-double-ref
    
    bytevector-ieee-single-native-set!
    bytevector-ieee-single-set!
    bytevector-ieee-double-native-set!
    bytevector-ieee-double-set!
    
    string->utf8
    string->utf16
    string->utf32
    utf8->string
    utf16->string
    utf32->string)
    
  (import 
    (ironscheme integrable)
    (ironscheme unsafe)
    (ironscheme clr)
     (except (ironscheme) 
      bytevector-u16-ref
      bytevector-s16-ref
      bytevector-u16-native-ref
      bytevector-s16-native-ref
      bytevector-u16-set!
      bytevector-s16-set!
      bytevector-u16-native-set!
      bytevector-s16-native-set!
      
      bytevector-u32-ref
      bytevector-s32-ref
      bytevector-u32-native-ref
      bytevector-s32-native-ref
      bytevector-u32-set!
      bytevector-s32-set!
      bytevector-u32-native-set!
      bytevector-s32-native-set!
      
      bytevector-u64-ref
      bytevector-s64-ref
      bytevector-u64-native-ref
      bytevector-s64-native-ref
      bytevector-u64-set!
      bytevector-s64-set!
      bytevector-u64-native-set!
      bytevector-s64-native-set!
      
      bytevector-ieee-single-native-ref
      bytevector-ieee-double-native-ref
      bytevector-ieee-single-native-set!
      bytevector-ieee-double-native-set!
      
      native-endianness
      
      make-bytevector
      bytevector-length
      bytevector=?
      bytevector-fill!
      bytevector-copy!
      bytevector-copy
      bytevector-u8-ref
      bytevector-u8-set!
      bytevector-s8-ref
      bytevector-s8-set!
      bytevector->u8-list
      u8-list->bytevector
      string->utf8
      string->utf16
      string->utf32
      utf8->string
      utf16->string
      utf32->string
      bytevector-ieee-single-ref
      bytevector-ieee-single-set!
      bytevector-ieee-double-ref
      bytevector-ieee-double-set!
      uint-list->bytevector
      sint-list->bytevector
      bytevector->uint-list
      bytevector->sint-list
      
      bytevector-uint-ref
      bytevector-sint-ref
      bytevector-uint-set!
      bytevector-sint-set!
      
      ))
     
  (define (native-endianness) 'little)
  
  (define utf8    (clr-static-prop-get System.Text.Encoding UTF8))
  (define utf16le (clr-new System.Text.UnicodeEncoding #f #f))
  (define utf16be (clr-new System.Text.UnicodeEncoding #t #f))
  (define utf32le (clr-new System.Text.UTF32Encoding #f #f))
  (define utf32be (clr-new System.Text.UTF32Encoding #t #f))
  
  (define (bignum? obj)
    (clr-is Microsoft.Scripting.Math.BigInteger obj))      
    
  (define (->bignum ei)
    (cond
      [(bignum? ei) ei]
      [(fixnum? ei) 
        (clr-static-call Microsoft.Scripting.Math.BigInteger "Create(System.Int32)" ei)]
      [else
        (assertion-violation #f "not a exact integer" ei)]))
  
  (define (get-bytes enc str)
    (clr-call System.Text.Encoding "GetBytes(String)" enc str))

  (define (get-string enc bv)
    (clr-call System.Text.Encoding "GetString(Byte[])" enc bv))
  
  (define (byte->sbyte b)
    (let ((b (->fixnum b)))
      (if (fx>? b 127)
          (fx- b 256)
          b)))
  
  (define (->byte k)
    (unless (fixnum? k)
      (assertion-violation #f "not a fixnum" k))
    (when (or (fx<? k -128) (fx>? k 255))
      (assertion-violation #f "too big or small for octect or byte" k))
    (clr-cast System.Byte (clr-cast System.Int32 k)))
    
  (define (->fixnum b)
    (clr-static-call System.Convert "ToInt32(Object)" b))      
  
  (define make-bytevector
    (case-lambda
      [(k)
        (clr-new-array System.Byte (clr-cast System.Int32 k))]
      [(k fill)
        (let ((bv (make-bytevector k)))
          (bytevector-fill! bv fill)
          bv)]))
                  
  (define (bytevector-length bv)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-length "not a bytevector" bv))
    (clr-prop-get System.Array Length bv))  
    
  (define (bytevector=? bv1 bv2)
    (unless (bytevector? bv1)
      (assertion-violation 'bytevector=? "not a bytevector" bv1))
    (unless (bytevector? bv2)
      (assertion-violation 'bytevector=? "not a bytevector" bv2))
    (cond
      [(eq? bv1 bv2) #t]
      [(let ((bl (bytevector-length bv1)))
        (if (= bl (bytevector-length bv2))
            (let f ((i 0))
              (cond 
                [(= i bl) #t]
                [(= (bytevector-u8-ref bv1 i) (bytevector-u8-ref bv2 i))
                  (f (+ i 1))]
                [else #f]))
            #f))]
      [else #f]))
                      
  (define (bytevector-fill! bv fill)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-fill! "not a bytevector" bv))    
    (let ((fill (->byte fill))
          (k (bytevector-length bv)))
      (let f ((i 0))
        (unless (= i k)
          (bytevector-u8-set! bv i fill)
          (f (+ i 1))))))
          
  (define (bytevector-copy! bv1 s1 bv2 s2 len)
    (unless (bytevector? bv1)
      (assertion-violation 'bytevector-copy! "not a bytevector" bv1))
    (unless (bytevector? bv2)
      (assertion-violation 'bytevector-copy! "not a bytevector" bv2))         
    (clr-static-call System.Buffer BlockCopy bv1 s1 bv2 s2 len))  
    
  (define (bytevector-copy bv)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-copy "not a bytevector" bv)) 
    (clr-call System.Array Clone bv))  
    
  (define (bytevector-u8-ref bv k)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-u8-ref "not a bytevector" bv)) 
    (clr-static-call System.Convert "ToInt32(Byte)" 
      ($bytevector-ref bv k)))
      
  (define (bytevector-u8-set! bv k value)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-u8-set! "not a bytevector" bv)) 
    ($bytevector-set! bv k (clr-static-call System.Convert "ToByte(Object)" value)))
   
  (define (bytevector-s8-ref bv k)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-s8-ref "not a bytevector" bv)) 
    (byte->sbyte ($bytevector-ref bv k)))
      
  (define (bytevector-s8-set! bv k value)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-s8-set! "not a bytevector" bv)) 
    ($bytevector-set! bv k (->byte value)))  
   
  (define (bytevector->u8-list bv)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector->u8-list "not a bytevector" bv)) 
    (let ((l (bytevector-length bv)))
      (let f ((i (- l 1))(a '()))
        (if (negative? i)
            a
            (f (- i 1) (cons (bytevector-u8-ref bv i) a))))))
            
  (define (u8-list->bytevector lst)
    (unless (list? lst)
      (assertion-violation 'u8-list->bytevector "not a list" lst))
    (let* ((l (length lst))
           (bv (make-bytevector l)))
      (let f ((i 0)(lst lst))
        (if (= i l)
            bv
            (begin
              (bytevector-u8-set! bv i (car lst))
              (f (+ i 1) (cdr lst)))))))
              
  (define (bytevector-uint-ref bv k end size)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-uint-ref "not a bytevector" bv))
    (unless (and (integer? k) (exact? k) (not (negative? k)))
      (assertion-violation 'bytevector-uint-ref "not a non-negative exact integer" k))
    (unless (and (integer? size) (exact? size) (not (negative? size)))
      (assertion-violation 'bytevector-uint-ref "not a non-negative exact integer" size))
    (unless (symbol? end)
      (assertion-violation 'bytevector-uint-ref "not a symbol" end))
    (let ((sb (make-bytevector size)))
      (bytevector-copy! bv k sb 0 size)
      (when (eq? end 'big)
        (clr-static-call System.Array Reverse sb))
      (case size
        [(1)
          (->fixnum ($bytevector-ref sb k))]
        [(2)
          (->fixnum 
            (clr-static-call System.BitConverter 
                             "ToUInt16(Byte[],Int32)"
                             sb
                             0))]
        [(4)
          (exact (clr-static-call Microsoft.Scripting.Math.BigInteger
                                  "op_Implicit(UInt32)"
                                  (clr-static-call System.BitConverter
                                                   "ToUInt32(Byte[],Int32)"
                                                   sb
                                                   0)))]
        [(8)
          (exact (clr-static-call Microsoft.Scripting.Math.BigInteger
                                 "op_Implicit(UInt64)"
                                 (clr-static-call System.BitConverter
                                                  "ToUInt64(Byte[],Int32)"
                                                  sb
                                                  0)))]
        [else
          (let ((data (make-bytevector (+ size 1))))
            (bytevector-copy! sb 0 data 0 size)
            (exact (clr-static-call Microsoft.Scripting.Math.BigInteger
                                   "Create(Byte[])"
                                   data)))])))
                                                   
  (define (bytevector-sint-ref bv k end size)
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-sint-ref "not a bytevector" bv))
    (unless (and (integer? k) (exact? k) (not (negative? k)))
      (assertion-violation 'bytevector-sint-ref "not a non-negative exact integer" k))
    (unless (and (integer? size) (exact? size) (not (negative? size)))
      (assertion-violation 'bytevector-sint-ref "not a non-negative exact integer" size))
    (unless (symbol? end)
      (assertion-violation 'bytevector-sint-ref "not a symbol" end))
    (let ((sb (make-bytevector size)))
      (bytevector-copy! bv k sb 0 size)
      (when (eq? end 'big)
        (clr-static-call System.Array Reverse sb))
      (case size
        [(1)
          (byte->sbyte ($bytevector-ref sb k))]
        [(2)
          (->fixnum 
            (clr-static-call System.BitConverter 
                             "ToInt16(Byte[],Int32)"
                             sb
                             0))]
        [(4)
          (clr-static-call System.BitConverter
                           "ToInt32(Byte[],Int32)"
                           sb
                           0)]
        [(8)
          (exact (clr-static-call Microsoft.Scripting.Math.BigInteger
                                 "op_Implicit(Int64)"
                                 (clr-static-call System.BitConverter
                                                  "ToInt64(Byte[],Int32)"
                                                  sb
                                                  0)))]
        [else
          (exact (clr-static-call Microsoft.Scripting.Math.BigInteger
                                 "Create(Byte[])"
                                 sb))])))
                           
  (define (bytevector-uint-set! bv k n end size)                           
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-uint-set! "not a bytevector" bv))
    (unless (and (integer? k) (exact? k) (not (negative? k)))
      (assertion-violation 'bytevector-uint-set! "not a non-negative exact integer" k))
    (unless (and (integer? size) (exact? size) (not (negative? size)))
      (assertion-violation 'bytevector-uint-set! "not a non-negative exact integer" size))
    (unless (symbol? end)
      (assertion-violation 'bytevector-uint-set! "not a symbol" end))                 
    (case size
      [(1)
        ($bytevector-set! bv k (->byte n))]
      [(2)
        (let ((data (clr-static-call System.BitConverter
                                     "GetBytes(UInt16)"
                                     (clr-static-call System.Convert
                                                      "ToUInt16(Object)"
                                                      n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data 0 bv k size))]
      [(4)
        (let ((data (clr-static-call System.BitConverter
                                     "GetBytes(UInt32)"
                                     (clr-static-call System.Convert
                                                      "ToUInt32(Object)"
                                                      n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data 0 bv k size))]
      [(8)
        (let ((data (clr-static-call System.BitConverter
                                     "GetBytes(UInt64)"
                                     (clr-static-call System.Convert
                                                      "ToUInt64(Object)"
                                                      n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data 0 bv k size))]
      [else
        (let ((data (clr-call Microsoft.Scripting.Math.BigInteger
                              ToByteArray
                              (->bignum n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data (if (eq? end 'big) 1 0) bv k size))])
    (void))
          
  (define (bytevector-sint-set! bv k n end size)                           
    (unless (bytevector? bv)
      (assertion-violation 'bytevector-sint-set! "not a bytevector" bv))
    (unless (and (integer? k) (exact? k) (not (negative? k)))
      (assertion-violation 'bytevector-sint-set! "not a non-negative exact integer" k))
    (unless (and (integer? size) (exact? size) (not (negative? size)))
      (assertion-violation 'bytevector-sint-set! "not a non-negative exact integer" size))
    (unless (symbol? end)
      (assertion-violation 'bytevector-sint-set! "not a symbol" end))                 
    (case size
      [(1)
        ($bytevector-set! bv k (->byte n))]
      [(2)
        (let ((data (clr-static-call System.BitConverter
                                     "GetBytes(Int16)"
                                     (clr-static-call System.Convert
                                                      "ToInt16(Object)"
                                                      n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data 0 bv k size))]
      [(4)
        (let ((data (clr-static-call System.BitConverter
                                     "GetBytes(Int32)"
                                     (clr-static-call System.Convert
                                                      "ToInt32(Object)"
                                                      n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data 0 bv k size))]
      [(8)
        (let ((data (clr-static-call System.BitConverter
                                     "GetBytes(Int64)"
                                     (clr-static-call System.Convert
                                                      "ToInt64(Object)"
                                                      n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data 0 bv k size))]
      [else
        (let ((data (clr-call Microsoft.Scripting.Math.BigInteger
                              ToByteArray
                              (->bignum n))))
          (when (eq? end 'big)
            (clr-static-call System.Array Reverse data))
          (bytevector-copy! data 0 bv k size))])
    (void))          
      
              
  (define (string->utf8 s)
    (unless (string? s)
      (assertion-violation 'string->utf8 "not a string" s))
    (get-bytes utf8 s))
    
  (define string->utf16
    (case-lambda
      [(s)
        (string->utf16 s 'big)]
      [(s end)
        (unless (string? s)
          (assertion-violation 'string->utf16 "not a string" s))
        (case end
          [(big)    (get-bytes utf16be s)]
          [(little) (get-bytes utf16le s)]
          [else
            (assertion-violation 'string->utf16 "unknown endianness" end)])]))
               
  (define string->utf32
    (case-lambda
      [(s)
        (string->utf32 s 'big)]
      [(s end)
        (unless (string? s)
          (assertion-violation 'string->utf32 "not a string" s))
        (case end
          [(big)    (get-bytes utf32be s)]
          [(little) (get-bytes utf32le s)]
          [else
            (assertion-violation 'string->utf32 "unknown endianness" end)])]))
            
  (define (utf8->string bv)
    (unless (bytevector? bv)
      (assertion-violation 'utf8->string "not a bytevector" bv))
    (get-string utf8 bv))
    
  (define (trim-front bv k)
    (let ((d (make-bytevector (- (bytevector-length bv) k))))
      (bytevector-copy! bv k d 0 (bytevector-length d))
      d))
      
  (define utf16->string           
    (case-lambda
      [(bv end)
        (utf16->string bv end #f)]
      [(bv end endman?)
        (if endman?
            (if (eq? end 'big)
                (get-string utf16be bv)
                (get-string utf16le bv))
            (let ((b0 (bytevector-u8-ref bv 0))
                  (b1 (bytevector-u8-ref bv 1)))
              (cond
                [(and (= #xff b0) (= b1 #xfe))
                  (utf16->string (trim-front bv 2) 'little #t)]
                [(and (= #xfe b0) (= b1 #xff))
                  (utf16->string (trim-front bv 2) 'big #t)]
                [else
                  (utf16->string bv end #t)])))]))
                
  (define utf32->string           
    (case-lambda
      [(bv end)
        (utf32->string bv end #f)]
      [(bv end endman?)
        (if endman?
            (if (eq? end 'big)
                (get-string utf32be bv)
                (get-string utf32le bv))
            (let ((b0 (bytevector-u8-ref bv 0))
                  (b1 (bytevector-u8-ref bv 1))
                  (b2 (bytevector-u8-ref bv 2))
                  (b3 (bytevector-u8-ref bv 3)))                
              (cond
                  [(and (= #xff b0) (= b1 #xfe) (zero? b2) (zero? b3))
                    (utf32->string (trim-front bv 4) 'little #t)]
                  [(and (zero? b0) (zero? b1) (= #xfe b2) (= b3 #xff))
                    (utf32->string (trim-front bv 4) 'big #t)]
                [else
                  (utf32->string bv end #t)])))]))  
                  
  (define (uint-list->bytevector lst end size)
    (when (negative? size)
      (assertion-violation 'uint-list->bytevector "invalid size" size))
    (let ((bv (make-bytevector (* (length lst) size))))
      (let f ((i 0)(lst lst))
        (if (null? lst)
            bv
            (begin
              (bytevector-uint-set! bv i (car lst) end size)
              (f (+ i size) (cdr lst)))))))
              
  (define (sint-list->bytevector lst end size)
    (when (negative? size)
      (assertion-violation 'sint-list->bytevector "invalid size" size))
    (let ((bv (make-bytevector (* (length lst) size))))
      (let f ((i 0)(lst lst))
        (if (null? lst)
            bv
            (begin
              (bytevector-sint-set! bv i (car lst) end size)
              (f (+ i size) (cdr lst)))))))
              
  (define (bytevector->uint-list bv end size)
    (when (negative? size)
      (assertion-violation 'bytevector->uint-list "invalid size" size))
    (let f ((l (bytevector-length bv)) (a '()))
      (if (zero? l)
          a
          (f (- l size) (cons (bytevector-uint-ref bv (- l size) end size) a)))))

  (define (bytevector->sint-list bv end size)
    (when (negative? size)
      (assertion-violation 'bytevector->sint-list "invalid size" size))
    (let f ((l (bytevector-length bv)) (a '()))
      (if (zero? l)
          a
          (f (- l size) (cons (bytevector-sint-ref bv (- l size) end size) a)))))
                
            
  (define (single->double s)
    (clr-static-call System.Convert "ToDouble(Single)" s))  
            
  (define (bytevector-ieee-single-ref bv k end)
    (let ((d (make-bytevector 4)))
      (bytevector-copy! bv k d 0 4)
      (when (eq? end 'big)
        (clr-static-call System.Array Reverse d))
      (single->double (clr-static-call System.BitConverter ToSingle d 0))))

  (define (bytevector-ieee-double-ref bv k end)
    (let ((d (make-bytevector 8)))
      (bytevector-copy! bv k d 0 8)
      (when (eq? end 'big)
        (clr-static-call System.Array Reverse d))
      (clr-static-call System.BitConverter ToDouble d 0)))
      
  (define (bytevector-ieee-single-set! bv k value end)
    (let* ((value (clr-static-call System.Convert "ToSingle(Object)" value))
           (data  (clr-static-call System.BitConverter "GetBytes(Single)" value)))
      (when (eq? end 'big)
        (clr-static-call System.Array Reverse data))
      (bytevector-copy! data 0 bv k 4)))
      
  (define (bytevector-ieee-double-set! bv k value end)
    (let* ((value (clr-static-call System.Convert "ToDouble(Object)" value))
           (data  (clr-static-call System.BitConverter "GetBytes(Double)" value)))
      (when (eq? end 'big)
        (clr-static-call System.Array Reverse data))
      (bytevector-copy! data 0 bv k 8)))
     
  (define (bytevector-u16-ref bytevector k endianness)
    (bytevector-uint-ref bytevector k endianness 2))
    
  (define (bytevector-s16-ref bytevector k endianness)     
    (bytevector-sint-ref bytevector k endianness 2))
    
  (define (bytevector-u16-native-ref bytevector k)     
    (bytevector-uint-ref bytevector k (native-endianness) 2))
    
  (define (bytevector-s16-native-ref bytevector k)     
    (bytevector-sint-ref bytevector k (native-endianness) 2))
    
  (define (bytevector-u16-set! bytevector k n endianness)     
    (bytevector-uint-set! bytevector k n endianness 2))
    
  (define (bytevector-s16-set! bytevector k n endianness)     
    (bytevector-sint-set! bytevector k n endianness 2))
    
  (define (bytevector-u16-native-set! bytevector k n)     
    (bytevector-uint-set! bytevector k n (native-endianness) 2))
    
  (define (bytevector-s16-native-set! bytevector k n)     
    (bytevector-sint-set! bytevector k n (native-endianness) 2))
     
  (define (bytevector-u32-ref bytevector k endianness)     
    (bytevector-uint-ref bytevector k endianness 4))
    
  (define (bytevector-s32-ref bytevector k endianness)     
    (bytevector-sint-ref bytevector k endianness 4))
    
  (define (bytevector-u32-native-ref bytevector k)     
    (bytevector-uint-ref bytevector k (native-endianness) 4))
    
  (define (bytevector-s32-native-ref bytevector k)     
    (bytevector-sint-ref bytevector k (native-endianness) 4))
    
  (define (bytevector-u32-set! bytevector k n endianness)     
    (bytevector-uint-set! bytevector k n endianness 4))
    
  (define (bytevector-s32-set! bytevector k n endianness)     
    (bytevector-sint-set! bytevector k n endianness 4))
    
  (define (bytevector-u32-native-set! bytevector k n)       
    (bytevector-uint-set! bytevector k n (native-endianness) 4))
    
  (define (bytevector-s32-native-set! bytevector k n)     
    (bytevector-sint-set! bytevector k n (native-endianness) 4))
     
  (define (bytevector-u64-ref bytevector k endianness)     
    (bytevector-uint-ref bytevector k endianness 8))
    
  (define (bytevector-s64-ref bytevector k endianness)     
    (bytevector-sint-ref bytevector k endianness 8))
    
  (define (bytevector-u64-native-ref bytevector k)     
    (bytevector-uint-ref bytevector k (native-endianness) 8))
    
  (define (bytevector-s64-native-ref bytevector k)     
    (bytevector-sint-ref bytevector k (native-endianness) 8))
    
  (define (bytevector-u64-set! bytevector k n endianness)     
    (bytevector-uint-set! bytevector k n endianness 8))
    
  (define (bytevector-s64-set! bytevector k n endianness)     
    (bytevector-sint-set! bytevector k n endianness 8))
    
  (define (bytevector-u64-native-set! bytevector k n)     
    (bytevector-uint-set! bytevector k n (native-endianness) 8))
    
  (define (bytevector-s64-native-set! bytevector k n)    
    (bytevector-sint-set! bytevector k n (native-endianness) 8))
    
  (define (bytevector-ieee-single-native-ref bytevector k)
    (if (not (zero? (mod k 4)))
      (assertion-violation 'bytevector-ieee-single-native-ref "must be multiple of 4" k)
      (bytevector-ieee-single-ref bytevector k (native-endianness))))
    
  (define (bytevector-ieee-double-native-ref bytevector k)     
    (if (not (zero? (mod k 8)))
      (assertion-violation 'bytevector-ieee-double-native-ref "must be multiple of 8" k)
      (bytevector-ieee-double-ref bytevector k (native-endianness))))
    
  (define (bytevector-ieee-single-native-set! bytevector k x)     
    (if (not (zero? (mod k 4)))
      (assertion-violation 'bytevector-ieee-single-native-set! "must be multiple of 4" k)
      (bytevector-ieee-single-set! bytevector k x (native-endianness))))
    
  (define (bytevector-ieee-double-native-set! bytevector k x)     
    (if (not (zero? (mod k 8)))
      (assertion-violation 'bytevector-ieee-double-native-set! "must be multiple of 8" k)
      (bytevector-ieee-double-set! bytevector k x (native-endianness))))
)
