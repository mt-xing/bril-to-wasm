
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
  
  (func (export "_start") (param $input i64) (local $zero i64) (local $ten i64) (local $result i64) (local $__v0 i32) (local $digit i64) (local $__v1 i32) (local $processed i32) (local $done i32) (local $r0 i64) 
i64.const 0
local.set $zero
i64.const 10
local.set $ten
i64.const 0
local.set $result
i32.const 1
local.set $__v0
(block $b_loop_4128491984317054
        (loop $l_loop_4128491984317054
          local.get $input
call $peel_last_digit
 local.set $digit
local.get $input
local.get $ten
i64.div_s
local.set $input
local.get $result
local.get $digit
i64.add
local.set $result
i32.const 1
local.set $__v1
(block $b_loop_6185057992024133
        (loop $l_loop_6185057992024133
          local.get $result
call $int_to_string_and_print
call $print_newline
local.get $result
call $is_single_digit
 local.set $processed
local.get $processed
 (if
       (then 
 local.get $input
local.get $zero
i64.eq
local.set $done
local.get $done
 (if
       (then 
 local.get $result
call $int_to_string_and_print
call $print_newline
return
 
) 
       (else 
 br $l_loop_4128491984317054
 
) 
)
 
) 
       (else 
 local.get $result
call $peel_last_digit
 local.set $r0
local.get $result
local.get $ten
i64.div_s
local.set $result
local.get $result
local.get $r0
i64.add
local.set $result
br $l_loop_6185057992024133
 
) 
)

          local.get $__v1
          br_if $l_loop_6185057992024133
        )
      )

          local.get $__v0
          br_if $l_loop_4128491984317054
        )
      )
 )
(func $is_single_digit (param $input i64) (result i32) (local $ten i64) (local $zero i64) (local $divided i64) (local $mul_by_ten i64) (local $result i32) 
i64.const 10
local.set $ten
i64.const 0
local.set $zero
local.get $input
local.get $ten
i64.div_s
local.set $divided
local.get $divided
local.get $ten
i64.mul
local.set $mul_by_ten
local.get $mul_by_ten
local.get $zero
i64.eq
local.set $result
local.get $result 
 return
i32.const 0
return
 )
(func $peel_last_digit (param $input i64) (result i64) (local $ten i64) (local $div_by_ten i64) (local $mul_by_ten i64) (local $last_digit i64) 
i64.const 10
local.set $ten
local.get $input
local.get $ten
i64.div_s
local.set $div_by_ten
local.get $div_by_ten
local.get $ten
i64.mul
local.set $mul_by_ten
local.get $input
local.get $mul_by_ten
i64.sub
local.set $last_digit
local.get $last_digit 
 return
i64.const 0
return
 )

)
