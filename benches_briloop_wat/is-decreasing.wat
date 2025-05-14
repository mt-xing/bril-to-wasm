
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
  
  (func (export "_start") (param $x i64) (local $tmp0 i32) (local $tmp i32) 
local.get $x
call $is_decreasing
 local.set $tmp0
local.get $tmp0
local.set $tmp
local.get $tmp
call $bool_to_string_and_print
call $print_newline
return
 )
(func $is_decreasing (param $x i64) (result i32) (local $tmp i64) (local $tmp1 i64) (local $tmp2 i64) (local $tmp3 i64) (local $prev i64) (local $__v0 i32) (local $tmp7 i64) (local $tmp8 i32) (local $tmp9 i64) (local $digit i64) (local $tmp10 i32) (local $tmp14 i32) (local $tmp15 i64) (local $tmp16 i64) (local $tmp17 i32) 
local.get $x
local.set $tmp
i64.const 1
local.set $tmp1
i64.const -1
local.set $tmp2
local.get $tmp1
local.get $tmp2
i64.mul
local.set $tmp3
local.get $tmp3
local.set $prev
i32.const 1
local.set $__v0
(block $b_loop_14986818607540675
        (loop $l_loop_14986818607540675
          i64.const 0
local.set $tmp7
local.get $tmp
local.get $tmp7
i64.gt_s
local.set $tmp8
local.get $tmp8
 (if
       (then 
 (block $block_4914117915955952
        local.get $tmp
call $last_digit
 local.set $tmp9
local.get $tmp9
local.set $digit
local.get $digit
local.get $prev
i64.lt_s
local.set $tmp10
local.get $tmp10
 (if
       (then 
 i32.const 0
local.set $tmp14
local.get $tmp14 
 return
br $block_4914117915955952
 
) 
       (else 
 br $block_4914117915955952
 
) 
)

      )
local.get $digit
local.set $prev
i64.const 10
local.set $tmp15
local.get $tmp
local.get $tmp15
i64.div_s
local.set $tmp16
local.get $tmp16
local.set $tmp
br $l_loop_14986818607540675
 
) 
       (else 
 i32.const 1
local.set $tmp17
local.get $tmp17 
 return
 
) 
)

          local.get $__v0
          br_if $l_loop_14986818607540675
        )
      )
i32.const 0
return
 )
(func $last_digit (param $x i64) (result i64) (local $tmp18 i64) (local $tmp19 i64) (local $tmp20 i64) (local $tmp21 i64) (local $tmp22 i64) 
i64.const 10
local.set $tmp18
local.get $x
local.get $tmp18
i64.div_s
local.set $tmp19
i64.const 10
local.set $tmp20
local.get $tmp19
local.get $tmp20
i64.mul
local.set $tmp21
local.get $x
local.get $tmp21
i64.sub
local.set $tmp22
local.get $tmp22 
 return
i64.const 0
return
 )

)
