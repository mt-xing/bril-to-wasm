
(module
  ;; Import fd_write from WASI for console output
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))

  ;; Define 1 page of memory (64KiB) and export it
  (memory (export "memory") 1)

  ;; --- Memory Layout Constants (Addresses) ---
  (global $ADDR_IOV_BUF i32 (i32.const 0))
  (global $ADDR_IOV_LEN i32 (i32.const 4))
  (global $ADDR_NWRITTEN i32 (i32.const 8))
  (global $ADDR_STRING_BUFFER i32 (i32.const 12))
  ;; Increased capacity for i64 strings
  (global $STRING_BUFFER_CAPACITY i32 (i32.const 24))

  (global $STR_TRUE_ADDR i32 (i32.const 40)) ;; Adjusted offset due to larger int buffer (12+24=36, next nice is 40)
  (global $STR_TRUE_LEN i32 (i32.const 4))
  (global $STR_FALSE_ADDR i32 (i32.const 50)) ;; Adjusted offset
  (global $STR_FALSE_LEN i32 (i32.const 5))

  ;; --- Data Segments to initialize strings in memory ---
  (data (i32.const 40) "true")
  (data (i32.const 50) "false")

  ;; --- Function to convert an i64 to a string and print it ---
  (func $int_to_string_and_print (param $value i64) ;; Changed to i64
    (local $char_ptr i32)
    (local $current_magnitude i64) ;; Changed to i64
    (local $is_negative i32)
    (local $digit_i64 i64) ;; To store i64 result of rem_u
    (local $char_code i32)
    (local $string_actual_start_addr i32)
    (local $string_actual_length i32)

    (local.set $char_ptr
      (i32.add
        (global.get $ADDR_STRING_BUFFER)
        (global.get $STRING_BUFFER_CAPACITY)
      )
    )

    local.get $value
    i64.eqz ;; Changed to i64.eqz
    if $if_value_is_zero
      (local.set $char_ptr (i32.sub (local.get $char_ptr) (i32.const 1)))
      local.get $char_ptr
      i32.const 48
      i32.store8
      (local.set $string_actual_start_addr (local.get $char_ptr))
      (local.set $string_actual_length (i32.const 1))
    else
      (local.set $is_negative (i32.const 0))
      local.get $value
      i64.const 0 ;; Changed to i64.const
      i64.lt_s ;; Changed to i64.lt_s
      if $if_value_is_negative
        (local.set $is_negative (i32.const 1))
        local.get $value
        i64.const 0x8000000000000000 ;; i64.MIN_INT
        i64.eq ;; Changed to i64.eq
        if $if_value_is_min_int
          (local.set $current_magnitude (local.get $value))
        else
          (local.set $current_magnitude (i64.sub (i64.const 0) (local.get $value))) ;; i64 ops
        end $if_value_is_min_int
      else
        (local.set $current_magnitude (local.get $value))
      end $if_value_is_negative

      (block $digit_conversion_break_target
        (loop $digit_conversion_loop
          ;; Get digit as i64
          (local.set $digit_i64 (i64.rem_u (local.get $current_magnitude) (i64.const 10)))
          ;; Convert i64 digit to i32 for char code calculation
          (local.set $char_code (i32.add (i32.wrap_i64 (local.get $digit_i64)) (i32.const 48)))
          
          (local.set $char_ptr (i32.sub (local.get $char_ptr) (i32.const 1)))
          local.get $char_ptr
          local.get $char_code
          i32.store8

          (local.set $current_magnitude (i64.div_u (local.get $current_magnitude) (i64.const 10)))

          local.get $current_magnitude
          i64.eqz ;; Changed to i64.eqz
          br_if $digit_conversion_break_target
          br $digit_conversion_loop
        )
      )

      local.get $is_negative
      if
        (local.set $char_ptr (i32.sub (local.get $char_ptr) (i32.const 1)))
        local.get $char_ptr
        i32.const 45
        i32.store8
      end

      (local.set $string_actual_start_addr (local.get $char_ptr))
      (local.set $string_actual_length
        (i32.sub
          (i32.add (global.get $ADDR_STRING_BUFFER) (global.get $STRING_BUFFER_CAPACITY))
          (local.get $char_ptr)
        )
      )
    end $if_value_is_zero

    global.get $ADDR_IOV_BUF
    local.get $string_actual_start_addr
    i32.store

    global.get $ADDR_IOV_LEN
    local.get $string_actual_length
    i32.store

    (call $fd_write
      (i32.const 1)
      (global.get $ADDR_IOV_BUF)
      (i32.const 1)
      (global.get $ADDR_NWRITTEN)
    )
    drop
  )

  (func $bool_to_string_and_print (param $value i32)
    (local $string_to_print_addr i32)
    (local $string_to_print_len i32)
    local.get $value
    i32.eqz
    if $if_value_is_false
      (local.set $string_to_print_addr (global.get $STR_FALSE_ADDR))
      (local.set $string_to_print_len (global.get $STR_FALSE_LEN))
    else
      (local.set $string_to_print_addr (global.get $STR_TRUE_ADDR))
      (local.set $string_to_print_len (global.get $STR_TRUE_LEN))
    end $if_value_is_false
    global.get $ADDR_IOV_BUF
    local.get $string_to_print_addr
    i32.store
    global.get $ADDR_IOV_LEN
    local.get $string_to_print_len
    i32.store
    (call $fd_write
      (i32.const 1)
      (global.get $ADDR_IOV_BUF)
      (i32.const 1)
      (global.get $ADDR_NWRITTEN)
    )
    drop
  )

  ;; Exported function for printing i64 integers
  (func (export "print_this_int") (param $val i64) ;; Changed to i64
    local.get $val
    call $int_to_string_and_print
  )

  (func (export "print_this_bool") (param $val i32)
    local.get $val
    call $bool_to_string_and_print
  )

  (func $print_newline
    global.get $ADDR_STRING_BUFFER
    i32.const 10
    i32.store8
    global.get $ADDR_IOV_BUF
    global.get $ADDR_STRING_BUFFER
    i32.store
    global.get $ADDR_IOV_LEN
    i32.const 1
    i32.store
    (call $fd_write
      (i32.const 1) (global.get $ADDR_IOV_BUF) (i32.const 1) (global.get $ADDR_NWRITTEN))
    drop
  )
  
  (func $pow (param $x i64) (param $n i64) (result i64) (local $v1 i64) (local $v2 i64) (local $v3 i32) (local $v4 i64) (local $v5 i64) (local $v6 i64) (local $v7 i64) (local $v8 i64) (local $half i64) (local $v9 i64) (local $v10 i64) (local $v11 i64) (local $half2 i64) (local $v13 i64) (local $v14 i64) (local $v15 i64) (local $v16 i64) (local $v17 i32) (local $v18 i64) (local $v19 i64) (local $v20 i64) (local $ans i64) (local $v21 i64) (local $v22 i64) 
local.get $n
local.set $v1
i64.const 1
local.set $v2
local.get $v1
local.get $v2
i64.eq
local.set $v3
local.get $v3
 (if
       (then 
 local.get $x
local.set $v4
local.get $v4 
 return
 
) 
       (else 
 (block $block_1862185383052255
        local.get $x
local.set $v5
local.get $n
local.set $v6
i64.const 2
local.set $v7
local.get $v6
local.get $v7
i64.div_s
local.set $v8
local.get $v5
local.get $v8
call $pow
 local.set $half
local.get $half
local.set $half
local.get $half
local.set $v9
local.get $half
local.set $v10
local.get $v9
local.get $v10
i64.mul
local.set $v11
local.get $v11
local.set $half2
local.get $n
local.set $v13
i64.const 2
local.set $v14
local.get $v13
local.get $v14
call $mod
 local.set $v15
i64.const 1
local.set $v16
local.get $v15
local.get $v16
i64.eq
local.set $v17
local.get $v17
 (if
       (then 
 local.get $half2
local.set $v18
local.get $x
local.set $v19
local.get $v18
local.get $v19
i64.mul
local.set $v20
local.get $v20
local.set $ans
br $block_1862185383052255
 
) 
       (else 
 local.get $half2
local.set $v21
local.get $v21
local.set $ans
br $block_1862185383052255
 
) 
)

      )
local.get $ans
local.set $v22
local.get $v22 
 return
 
) 
)
i64.const 0
return
 )
(func $mod (param $a i64) (param $b i64) (result i64) (local $v0 i64) (local $v1 i64) (local $v2 i64) (local $v3 i64) (local $v4 i64) (local $v5 i64) (local $v6 i64) 
local.get $a
local.set $v0
local.get $a
local.set $v1
local.get $b
local.set $v2
local.get $v1
local.get $v2
i64.div_s
local.set $v3
local.get $b
local.set $v4
local.get $v3
local.get $v4
i64.mul
local.set $v5
local.get $v0
local.get $v5
i64.sub
local.set $v6
local.get $v6 
 return
i64.const 0
return
 )
(func $LEFTSHIFT (param $x i64) (param $step i64) (result i64) (local $v0 i64) (local $v1 i64) (local $p i64) (local $v2 i64) (local $v3 i64) (local $v4 i64) 
i64.const 2
local.set $v0
local.get $step
local.set $v1
local.get $v0
local.get $v1
call $pow
 local.set $p
local.get $p
local.set $p
local.get $x
local.set $v2
local.get $p
local.set $v3
local.get $v2
local.get $v3
i64.mul
local.set $v4
local.get $v4 
 return
i64.const 0
return
 )
(func $RIGHTSHIFT (param $x i64) (param $step i64) (result i64) (local $v0 i64) (local $v1 i64) (local $p i64) (local $v2 i64) (local $v3 i64) (local $v4 i64) 
i64.const 2
local.set $v0
local.get $step
local.set $v1
local.get $v0
local.get $v1
call $pow
 local.set $p
local.get $p
local.set $p
local.get $x
local.set $v2
local.get $p
local.set $v3
local.get $v2
local.get $v3
i64.div_s
local.set $v4
local.get $v4 
 return
i64.const 0
return
 )
(func (export "_start") (param $a i64) (param $b i64) (param $c i64) (param $d i64) (local $v2 i64) (local $v3 i64) (local $ans1 i64) (local $v4 i64) (local $v5 i64) (local $ans2 i64) 
local.get $a
local.set $v2
local.get $b
local.set $v3
local.get $v2
local.get $v3
call $LEFTSHIFT
 local.set $ans1
local.get $ans1
call $int_to_string_and_print
call $print_newline
local.get $c
local.set $v4
local.get $d
local.set $v5
local.get $v4
local.get $v5
call $RIGHTSHIFT
 local.set $ans2
local.get $ans2
call $int_to_string_and_print
call $print_newline
return
 )

)
