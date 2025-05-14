
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
  
  (func (export "_start") (local $v0 i64) (local $a i64) (local $v1 i64) (local $v2 i64) 
i64.const 20
local.set $v0
local.get $v0
local.set $a
local.get $a
local.set $v1
local.get $v1
call $relative_primes
i64.const 0
local.set $v2
return
 )
(func $mod (param $a i64) (param $b i64) (result i64) (local $v0 i64) (local $v1 i64) (local $v2 i64) (local $v3 i64) (local $v4 i64) 
local.get $a
local.set $v0
local.get $b
local.set $v1
local.get $v0
local.get $v1
i64.div_s
local.set $v2
local.get $v2
local.get $v1
i64.mul
local.set $v3
local.get $v0
local.get $v3
i64.sub
local.set $v4
local.get $v4 
 return
i64.const 0
return
 )
(func $gcd (param $a i64) (param $b i64) (result i64) (local $v1 i64) (local $v2 i64) (local $v3 i32) (local $v4 i64) (local $tmp i64) (local $v5 i64) (local $v6 i64) (local $v8 i64) (local $v9 i64) (local $v10 i32) (local $v11 i64) (local $v13 i64) (local $v14 i64) (local $v15 i32) (local $v16 i64) (local $v17 i64) (local $v18 i64) (local $remainder i64) (local $v19 i64) (local $v20 i64) (local $g i64) (local $v21 i64) 
(block $block_6652513186610416
        local.get $b
local.set $v1
local.get $a
local.set $v2
local.get $v1
local.get $v2
i64.gt_s
local.set $v3
local.get $v3
 (if
       (then 
 local.get $a
local.set $v4
local.get $v4
local.set $tmp
local.get $b
local.set $v5
local.get $v5
local.set $a
local.get $tmp
local.set $v6
local.get $v6
local.set $b
br $block_6652513186610416
 
) 
       (else 
 br $block_6652513186610416
 
) 
)

      )
(block $block_3288584857993567
        local.get $a
local.set $v8
i64.const 0
local.set $v9
local.get $v8
local.get $v9
i64.eq
local.set $v10
local.get $v10
 (if
       (then 
 local.get $b
local.set $v11
local.get $v11 
 return
br $block_3288584857993567
 
) 
       (else 
 (block $block_9128868690740134
        local.get $b
local.set $v13
i64.const 0
local.set $v14
local.get $v13
local.get $v14
i64.eq
local.set $v15
local.get $v15
 (if
       (then 
 local.get $a
local.set $v16
local.get $v16 
 return
br $block_9128868690740134
 
) 
       (else 
 br $block_9128868690740134
 
) 
)

      )
br $block_3288584857993567
 
) 
)

      )
local.get $a
local.set $v17
local.get $b
local.set $v18
local.get $v17
local.get $v18
call $mod
 local.set $remainder
local.get $remainder
local.set $remainder
local.get $b
local.set $v19
local.get $remainder
local.set $v20
local.get $v19
local.get $v20
call $gcd
 local.set $g
local.get $g
local.set $g
local.get $g
local.set $v21
local.get $v21 
 return
i64.const 0
return
 )
(func $relative_primes (param $a i64) (local $v1 i64) (local $b i64) (local $__v6 i32) (local $v2 i64) (local $v3 i64) (local $v4 i32) (local $v5 i64) (local $v6 i64) (local $g i64) (local $v8 i64) (local $v9 i64) (local $v10 i32) (local $v11 i64) (local $v12 i64) (local $v13 i64) (local $v14 i64) (local $v15 i64) 
local.get $a
local.set $v1
local.get $v1
local.set $b
i32.const 1
local.set $__v6
(block $b_loop_8488739006233442
        (loop $l_loop_8488739006233442
          local.get $b
local.set $v2
i64.const 1
local.set $v3
local.get $v2
local.get $v3
i64.ge_s
local.set $v4
local.get $v4
 (if
       (then 
 (block $block_4682993027951605
        local.get $a
local.set $v5
local.get $b
local.set $v6
local.get $v5
local.get $v6
call $gcd
 local.set $g
local.get $g
local.set $g
local.get $g
local.set $v8
i64.const 1
local.set $v9
local.get $v8
local.get $v9
i64.eq
local.set $v10
local.get $v10
 (if
       (then 
 local.get $b
local.set $v11
local.get $v11
call $int_to_string_and_print
call $print_newline
i64.const 0
local.set $v12
br $block_4682993027951605
 
) 
       (else 
 br $block_4682993027951605
 
) 
)

      )
local.get $b
local.set $v13
i64.const 1
local.set $v14
local.get $v13
local.get $v14
i64.sub
local.set $v15
local.get $v15
local.set $b
br $l_loop_8488739006233442
 
) 
       (else 
 return
 
) 
)

          local.get $__v6
          br_if $l_loop_8488739006233442
        )
      )
 )

)
