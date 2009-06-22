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

(library (ironscheme io ports)
  (export
    file-options
    
    buffer-mode?
    
    latin-1-codec
    utf-8-codec
    utf-16-codec
    eol-style
    native-eol-style
    
    &i/o-decoding
    make-i/o-decoding-error
    i/o-decoding-error?
    &i/o-encoding
    make-i/o-encoding-error
    i/o-encoding-error?
    i/o-encoding-error-char
    
    error-handling-mode
    make-transcoder
    native-transcoder
    transcoder-codec
    transcoder-eol-style
    transcoder-error-handling-mode
    
    bytevector->string
    string->bytevector
    
    eof-object
    eof-object?
    
    port?
    port-transcoder
    textual-port?
    binary-port?
    transcoded-port
    
    port-has-port-position?
    port-position
    port-has-set-port-position!?
    set-port-position!
    
    close-port
    call-with-port
    
    input-port?
    port-eof?
    open-file-input-port
    open-bytevector-input-port
    open-string-input-port
    standard-input-port
    current-input-port
    make-custom-binary-input-port
    make-custom-textual-input-port
    
    get-u8
    lookahead-u8
    get-bytevector-n
    get-bytevector-n!
    get-bytevector-some
    get-bytevector-all
    
    get-char
    lookahead-char
    get-string-n
    get-string-n!
    get-string-all
    get-line
    get-datum
    
    output-port?
    flush-output-port
    output-port-buffer-mode
    open-file-output-port
    open-bytevector-output-port
    call-with-bytevector-output-port
    open-string-output-port
    call-with-string-output-port
    
    standard-output-port
    standard-error-port
    
    current-output-port
    current-error-port
    
    make-custom-binary-output-port
    make-custom-textual-output-port
    
    put-u8
    put-bytevector
    
    put-char
    put-string
    put-datum
    
    open-file-input/output-port
    
    make-custom-binary-input/output-port
    make-custom-textual-input/output-port
    
    open-output-string
    get-output-string
    )
  
  (import 
    (ironscheme clr)
    (except (rnrs) 
      call-with-port
      open-string-output-port 
      port? 
      call-with-string-output-port
      open-output-string
      get-output-string
      put-datum
      get-datum
      buffer-mode?
      native-eol-style
      standard-error-port
      standard-input-port
      standard-output-port))
      
  (clr-using ironscheme.runtime)  
  
  (define (standard-error-port)
    (clr-static-call System.Console OpenStandardError))
    
  (define (standard-input-port)
    (clr-static-call System.Console OpenStandardInput))

  (define (standard-output-port)
    (clr-static-call System.Console OpenStandardOutput))
    
  
  (define (native-eol-style) 'crlf)
  
  (define (buffer-mode? obj)
    (and (symbol? obj) 
         (memq obj '(none line block)) 
         #t))

  (define (put-datum p datum) 
    (write datum p))
  
  (define get-datum read)
    
  (define (get-output-string port)
    (clr-call ironscheme.runtime.stringwriter getbuffer port))
    
  (define (open-output-string)
    (clr-new ironscheme.runtime.stringwriter))
  
  (define (open-string-output-port)
    (let ((p (open-output-string)))
      (values p (lambda () (get-output-string p)))))
      
  (define (port? obj)
    (or (textual-port? obj) 
        (binary-port? obj)))
    
  (define (call-with-string-output-port proc)
    (let ((p (open-output-string)))
      (call-with-port p proc)
      (get-output-string p)))
      
  (define (call-with-port port proc)
    (let ((r (proc port)))
      (close-port port)
      r))      

)