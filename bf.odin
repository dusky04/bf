package main

import "core:fmt"
import "core:os"


BF_DEBUG :: false

MAX_STACK_SIZE :: 256 // this defines the maximum nesting the brainfuck code can have
Stack :: struct {
	sp:    uint,
	count: uint,
	data:  [MAX_STACK_SIZE]uint,
}
push :: proc(st: ^Stack, x: uint) {
	if st.count >= MAX_STACK_SIZE {return}

	st.data[st.sp] = x
	st.sp += 1
	st.count += 1

}
pop :: proc(st: ^Stack) {
	if is_empty(st) {return}

	st.sp -= 1
	st.count -= 1
}


is_empty :: proc(st: ^Stack) -> bool {
	return true if (st.count == 0) else false
}
top :: proc(st: ^Stack) -> (result: uint, ok: bool) {
	if is_empty(st) {
		return 0, false
	}
	return st.data[st.sp - 1], true
}

TAPE_SIZE :: 10
BF :: struct {
	data_ptr: uint,
	ins_ptr:  uint,
	tape:     [TAPE_SIZE]byte,
	st:       Stack,
}

interpret :: proc(bf: ^BF, program: []byte) {


	for bf.ins_ptr < len(program) {
		switch program[bf.ins_ptr] {
		case '>':
			{
				// Increment the data pointer by one (to point to the next cell to the right).
				if bf.data_ptr == TAPE_SIZE - 1 {
					fmt.println("Cannot increment the data pointer anymore, hit the tape size")
					break
				}
				bf.data_ptr += 1
			}
		case '<':
			{
				// Decrement the data pointer by one (to point to the next cell to the left). Undefined if at 0.
				if bf.data_ptr == 0 {
					fmt.println("Cannot decrement the data pointer anymore, hit 0")

					break
				}
				bf.data_ptr -= 1
			}
		case '+':
			{
				// Increment the byte at the data pointer by one modulo 256.
				bf.tape[bf.data_ptr] = u8((uint(bf.tape[bf.data_ptr]) + 1) % 256)
			}
		case '-':
			{
				// Decrement the byte at the data pointer by one modulo 256.
				bf.tape[bf.data_ptr] = u8((uint(bf.tape[bf.data_ptr]) - 1) % 256)
			}
		case '.':
			{
				// Output the byte at the data pointer.
				if BF_DEBUG {
					fmt.printf(
						"Byte at [cell = %4d | val = %3d] | str = %c]\n",
						bf.data_ptr,
						bf.tape[bf.data_ptr],
						bf.tape[bf.data_ptr],
					)
				}
				fmt.printf("%c", bf.tape[bf.data_ptr])

			}
		case ',':
			{
				// Accept one byte of input, storing its value in the byte at the data pointer.
				fmt.println("',' encountered. NOT HANDLED YET")
			}
		case '[':
			{
				// If the byte at the data pointer is zero, then instead of moving the instruction pointer forward to the next command, jump it forward to the command after the matching ] command.
				if bf.tape[bf.data_ptr] == 0 {
					// find corresponding ']' index in the program
					// and then set bf.ins_ptr += ]_idx + 1
					depth := 1
					scan_idx := bf.ins_ptr + 1
					for scan_idx < len(program) {
						if program[scan_idx] == '[' {
							depth += 1
						} else if program[scan_idx] == ']' {
							depth -= 1
						}

						if depth == 0 {
							bf.ins_ptr = scan_idx
							break
						}
						scan_idx += 1
					}

				} else {
					push(&bf.st, bf.ins_ptr)
				}
			}

		case ']':
			{
				// If the byte at the data pointer is nonzero, then instead of moving the instruction pointer forward to the next command, jump it back to the command after the matching [ command.
				if bf.tape[bf.data_ptr] != 0 {
					matching_left_paren_idx, ok := top(&bf.st)
					assert(ok, "Encountered ']' before matching '['")
					bf.ins_ptr = matching_left_paren_idx
				} else {
					pop(&bf.st)
				}
			}
		}
		bf.ins_ptr += 1
	}
}


main :: proc() {
	if len(os.args) < 2 {
		return
	}

	program, ok := os.read_entire_file(os.args[1], context.allocator)
	if !ok {
		fmt.eprintf("Could not read file: %s\n", os.args[1])
		return
	}
	defer delete(program, context.allocator)

	bf := BF {
		data_ptr = 0,
		ins_ptr  = 0,
	}

	// NOTE: check if passing the program like this is making a copy
	interpret(&bf, program)
	fmt.println("%v", bf.tape)
}
