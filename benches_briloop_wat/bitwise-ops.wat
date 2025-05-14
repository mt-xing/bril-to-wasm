
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
  
  (func $mod2 (param $a i64) (result i32) (local $two i64) (local $tmp i64) (local $tmp2 i64) (local $tmp3 i64) (local $one i64) (local $ans i32) 
i64.const 2
local.set $two
local.get $a
local.get $two
i64.div_s
local.set $tmp
local.get $tmp
local.get $two
i64.mul
local.set $tmp2
local.get $a
local.get $tmp2
i64.sub
local.set $tmp3
i64.const 1
local.set $one
local.get $one
local.get $tmp3
i64.eq
local.set $ans
local.get $ans 
 return
i32.const 0
return
 )
(func $loop_subroutine (param $a i64) (param $b i64) (param $c i32) (result i64) (local $i i64) (local $n i64) (local $one i64) (local $two i64) (local $ans i64) (local $to_add i64) (local $__v0 i32) (local $cond i32) (local $mod2a i32) (local $mod2b i32) (local $cond_add i32) 
i64.const 0
local.set $i
i64.const 63
local.set $n
i64.const 1
local.set $one
i64.const 2
local.set $two
i64.const 0
local.set $ans
i64.const 1
local.set $to_add
i32.const 1
local.set $__v0
(block $b_loop_37051378076275965
        (loop $l_loop_37051378076275965
          local.get $i
local.get $n
i64.le_s
local.set $cond
local.get $cond
 (if
       (then 
 (block $block_5359767242468516
        local.get $a
call $mod2
 local.set $mod2a
local.get $b
call $mod2
 local.set $mod2b
local.get $mod2a
local.get $mod2b
i32.and
local.set $cond_add
local.get $c
 (if
       (then 
 local.get $mod2a
local.get $mod2b
i32.or
local.set $cond_add
br $block_5359767242468516
 
) 
       (else 
 br $block_5359767242468516
 
) 
)

      )
(block $block_5629964209162753
        local.get $cond_add
 (if
       (then 
 local.get $ans
local.get $to_add
i64.add
local.set $ans
br $block_5629964209162753
 
) 
       (else 
 br $block_5629964209162753
 
) 
)

      )
local.get $a
local.get $two
i64.div_s
local.set $a
local.get $b
local.get $two
i64.div_s
local.set $b
local.get $to_add
local.get $two
i64.mul
local.set $to_add
local.get $i
local.get $one
i64.add
local.set $i
br $l_loop_37051378076275965
 
) 
       (else 
 local.get $ans 
 return
 
) 
)

          local.get $__v0
          br_if $l_loop_37051378076275965
        )
      )
i64.const 0
return
 )
(func $OR (param $a i64) (param $b i64) (result i64) (local $oper i32) (local $v1 i64) 
i32.const 1
local.set $oper
local.get $a
local.get $b
local.get $oper
call $loop_subroutine
 local.set $v1
local.get $v1 
 return
i64.const 0
return
 )
(func $AND (param $a i64) (param $b i64) (result i64) (local $oper i32) (local $v1 i64) 
i32.const 0
local.set $oper
local.get $a
local.get $b
local.get $oper
call $loop_subroutine
 local.set $v1
local.get $v1 
 return
i64.const 0
return
 )
(func $XOR (param $a i64) (param $b i64) (result i64) (local $and_val i64) (local $or_val i64) (local $ans i64) 
local.get $a
local.get $b
call $AND
 local.set $and_val
local.get $a
local.get $b
call $OR
 local.set $or_val
local.get $or_val
local.get $and_val
i64.sub
local.set $ans
local.get $ans 
 return
i64.const 0
return
 )
(func (export "_start") (param $a i64) (param $b i64) (param $c i64) (local $one i64) (local $zero i64) (local $sel i64) (local $ans i64) (local $less i32) (local $equal i32) (local $greater i32) 
(block $block_02993442059330209
        i64.const 1
local.set $one
i64.const 0
local.set $zero
local.get $c
local.get $one
i64.sub
local.set $sel
local.get $zero
local.set $ans
local.get $sel
local.get $zero
i64.lt_s
local.set $less
local.get $sel
local.get $zero
i64.eq
local.set $equal
local.get $sel
local.get $zero
i64.gt_s
local.set $greater
local.get $less
 (if
       (then 
 local.get $a
local.get $b
call $AND
 local.set $ans
br $block_02993442059330209
 
) 
       (else 
 local.get $equal
 (if
       (then 
 local.get $a
local.get $b
call $OR
 local.set $ans
br $block_02993442059330209
 
) 
       (else 
 local.get $a
local.get $b
call $XOR
 local.set $ans
br $block_02993442059330209
 
) 
)
 
) 
)

      )
local.get $ans
call $int_to_string_and_print
call $print_newline
return
 )

)
