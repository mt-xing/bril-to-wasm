
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
  
  (func $abs (param $a i64) (result i64) (local $zero i64) (local $is_neg i32) (local $neg_one i64) 
(block $block_4700554393439049
        i64.const 0
local.set $zero
local.get $a
local.get $zero
i64.lt_s
local.set $is_neg
local.get $is_neg
 (if
       (then 
 i64.const -1
local.set $neg_one
local.get $a
local.get $neg_one
i64.mul
local.set $a
br $block_4700554393439049
 
) 
       (else 
 br $block_4700554393439049
 
) 
)

      )
local.get $a 
 return
i64.const 0
return
 )
(func $mod (param $a i64) (param $b i64) (result i64) (local $q i64) (local $aq i64) (local $mod i64) 
local.get $a
local.get $b
i64.div_s
local.set $q
local.get $b
local.get $q
i64.mul
local.set $aq
local.get $a
local.get $aq
i64.sub
local.set $mod
local.get $mod 
 return
i64.const 0
return
 )
(func $gcd (param $a i64) (param $b i64) (result i64) (local $__v2 i32) (local $mod i64) (local $zero i64) (local $is_term i32) 
i32.const 1
local.set $__v2
(block $b_loop_4479726891159036
        (loop $l_loop_4479726891159036
          local.get $a
local.get $b
call $mod
 local.set $mod
i64.const 0
local.set $zero
local.get $mod
local.get $zero
i64.eq
local.set $is_term
local.get $is_term
 (if
       (then 
 local.get $b 
 return
 
) 
       (else 
 local.get $b
local.set $a
local.get $mod
local.set $b
br $l_loop_4479726891159036
 
) 
)

          local.get $__v2
          br_if $l_loop_4479726891159036
        )
      )
i64.const 0
return
 )
(func $lcm (param $a i64) (param $b i64) (result i64) (local $zero i64) (local $a_is_zero i32) (local $b_is_zero i32) (local $ab i64) (local $gcdab i64) (local $lcm i64) 
(block $block_6772689407710083
        i64.const 0
local.set $zero
local.get $a
local.get $zero
i64.eq
local.set $a_is_zero
local.get $a_is_zero
 (if
       (then 
 local.get $b
local.get $zero
i64.eq
local.set $b_is_zero
local.get $b_is_zero
 (if
       (then 
 local.get $zero 
 return
 
) 
       (else 
 br $block_6772689407710083
 
) 
)
 
) 
       (else 
 br $block_6772689407710083
 
) 
)

      )
local.get $a
local.get $b
i64.mul
local.set $ab
local.get $ab
call $abs
 local.set $ab
local.get $a
local.get $b
call $gcd
 local.set $gcdab
local.get $ab
local.get $gcdab
i64.div_s
local.set $lcm
local.get $lcm 
 return
i64.const 0
return
 )
(func $orders (param $u i64) (param $n i64) (param $use_lcm i32) (local $__v6 i32) (local $is_term i32) (local $lcm i64) (local $ordu i64) (local $gcdun i64) (local $one i64) 
i32.const 1
local.set $__v6
(block $b_loop_7781952735832087
        (loop $l_loop_7781952735832087
          local.get $u
local.get $n
i64.eq
local.set $is_term
local.get $is_term
 (if
       (then 
 return
 
) 
       (else 
 (block $block_6781853175690025
        local.get $use_lcm
 (if
       (then 
 local.get $u
local.get $n
call $lcm
 local.set $lcm
local.get $lcm
local.get $u
i64.div_s
local.set $ordu
br $block_6781853175690025
 
) 
       (else 
 local.get $u
local.get $n
call $gcd
 local.set $gcdun
local.get $n
local.get $gcdun
i64.div_s
local.set $ordu
br $block_6781853175690025
 
) 
)

      )
local.get $u
call $int_to_string_and_print
call $print_newline
local.get $ordu
call $int_to_string_and_print
call $print_newline
i64.const 1
local.set $one
local.get $u
local.get $one
i64.add
local.set $u
br $l_loop_7781952735832087
 
) 
)

          local.get $__v6
          br_if $l_loop_7781952735832087
        )
      )
 )
(func (export "_start") (param $n i64) (param $use_lcm i32) (local $zero i64) (local $u i64) 
i64.const 0
local.set $zero
i64.const 1
local.set $u
local.get $n
call $abs
 local.set $n
local.get $zero
call $int_to_string_and_print
call $print_newline
local.get $u
call $int_to_string_and_print
call $print_newline
local.get $u
local.get $n
local.get $use_lcm
call $orders
return
 )

)
