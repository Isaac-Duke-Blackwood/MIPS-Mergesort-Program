#Isaac Blackwood
#This program asks the user for how many elements they will enter into a list, and gets 
#them from the user from keyboard input. Then the program sorts the elements by dividing
#the lists into sub lists and merging neighboring lists. It returns the starting address
#of the sorted list in $a0. It lastly displays the elements onscreen.
				.data
prompt1:		.asciiz "Please enter the number of elements in the list.\n"
prompt2:		.asciiz "Please enter the first element in the list.\n"
prompt3:		.asciiz "Please enter the next element in the list.\n"
error1:			.asciiz "You must enter a list with either 2, 4, 8, 16, or 32 elements.\n"
space:			.asciiz " "
				.globl list
				.globl list_length
list_length:	.word 0						#stores the length of the list
list:			.space 128					#stores the resulting list, $a0 will contain this address
temp_list:		.space 128					#stores the list thats created by the merge function
				.text
				.globl main
main:			#get list length from user and store it in list_length
				la $a0, prompt1
				addi $v0, $0, 4 
				syscall
				addi $v0, $0, 5
				syscall
				la $t0, list_length
				sw $v0, 0($t0)
				#check to make sure the input is a power of 2. branch to error if not.
				#if the passed integer is not 2, 4, 8, 16 or 32, then go to error message
				addi $t1, $0, 32			#initialize last value the loop checks for
				addi $t0, $0, 2
power2_loop:	beq $v0, $t0, end_power2
				sll $t0, $t0, 1
				blt $t0, $t1, power2_loop				
				j bad_length				#when all powers up to the sentinal value have been checked, we know its a bad list length
end_power2:		
				#get the list from the user with a for loop and store it in list.
				addi $s0, $v0, 0			#initialize a loop index variable with the list size
				blez $s0, bad_length
				la $s1, list				#initialize a pointer to the next element in the list
				la $a0, prompt2
				addi $v0, $0, 4 
				syscall
				addi $v0, $0, 5
				syscall
				#stores the passed int in the pointer location, and then increments passed the stored word and decrements the count of words left to be stored			
				sw $v0, 0($s1)				#store the read integer in the list
				addi $s1, $s1, 4			#point to the next integer
				addi $s0, $s0, -1			#decrement the count of elements left to read			
input_list:		blez $s0, input_end
				#read the next int in the list and store it in the next position in list
				la $a0, prompt3
				addi $v0, $0, 4 
				syscall
				addi $v0, $0, 5
				syscall
				#stores the passed int in the pointer location, and then increments passed the stored word and decrements the count of words left to be stored			
				sw $v0, 0($s1)				#store the read integer in the list
				addi $s1, $s1, 4			#point to the next integer
				addi $s0, $s0, -1			#decrement the count of elements left to read
				j input_list
input_end:		#sort the list by calling merge
				la $s0, list_length
				lw $s0, 0($s0)
				
				
				addi $s3, $0, 1				#initialize the group size at 1
				la $s2, list
				#call merge on the two halves of each group of 1, 2, 4, 8, 16 etc. elements until the list size has been reached (16 is largest group supported in this program because of the max 32 list size)
group_loop:		slt $t0, $s3, $s0
				beqz $t0, print				#if the list is sorted, print it and exit
				#determine the necessary number of merge_loop iterations
				div $s4, $s0, $s3			#$s4 counts the necessary number of merge operations
				sra $s4, $s4, 1
				addi $s5, $0, 0				#counts the number of currently completed iterations for merge loop
merge_loop:		slt $t0, $s5, $s4
				beqz $t0, end_merge_loop
				#determine offset from list for the first group
				sll $t0, $s3, 3				#multiply the group size by 4 (bytes in a word) by 2 (number of groups) to get offset in bytes per group already merged.
				#multiply the $t0 and $s5 to calculate the offset
				addi $t1, $0, 0				#initialize total at 0
				addi $t2, $s5, 0			#initialize loop control variable
multiply:		beqz $t2, end_multiply
				add $t1, $t1, $t0			#add to sum
				addi $t2, $t2, -1			#decrement LCV
				j multiply
end_multiply:	addi $t0, $t1, 0			#store offset in $t0 for first group
				#determine the starting address of first group
				add $t1, $s2, $t0
				#determine offset from first group for the second group
				sll $t2, $s3, 2
				#determine the starting address of second group
				add $t2, $t2, $t1
				#load into $a- registers and call merge
				addi $a0, $s3, 0
				addi $a1, $t1, 0
				addi $a2, $s3, 0
				addi $a3, $t2, 0
				jal merge
				addi $s5, $s5, 1
				j merge_loop
end_merge_loop: sll $s3, $s3, 1				#make the group size twice as large
				j group_loop
				
				#begin merge subroutine
merge:			#allocate room on the stack and store $s0~$s5
				addi $sp, $sp, -24
				sw $s0, 0($sp)
				sw $s1, 4($sp)
				sw $s2, 8($sp)
				sw $s3, 12($sp)
				sw $s4, 16($sp)
				sw $s5, 20($sp)
				add $s0, $a0, $a2		#determine the size of the resultant list and store the size in $s0
				#merge 2 sorted lists into one sorted list (#$a0=size of list 1, $a1=starting address of list 1, $a2=size of list 2, $a3=starting address of list 2, $a1=starting address of result list.)
				#while both lists aren't empty, compare the beginning and put the smaller element in the merged list.
				addi $s1, $zero, 0			#store list_one offset in $s1
				addi $s2, $zero, 0			#store list_two offset in $s2
				addi $s3, $zero, 0			#store result_list offset in $s3
				la $s4, temp_list			#store base address of result_list in $s4
				addi $s5, $a1, 0			#store where the list will end up
compare_loop:	blez $a2, empty_list_one	#pretest loop checks to see if one of the lists is empty - if so then empty the remaining integers in the other list into the result list 
				blez $a0, empty_list_two		
				add $t1, $a1, $s1			#add offset to the starting address of list_one
				add $t2, $a3, $s2			#add offset to the starting address of list_two
				lw  $t1, 0($t1)				#get current value from list_one
				lw  $t2, 0($t2)				#get current value from list_two
				slt $t0, $t1, $t2			#compare which is bigger, use $t0 as boolean 0=list_two smaller, 1=list_one smaller
				beq $t0, $zero, append_fr_two	
append_fr_one:	add $t0, $s4, $s3			#determine address of next int in result_list
				add $t1, $a1, $s1			#determine the address of the value from list_one (this is for safety in case $t1 has been changed since the body of the loop) 
				lw $t1, 0($t1)
				sw $t1, 0($t0)				#store the lower int in the result_list
				#"pop" the head of the list and update the result_list offset
				addi $a0, $a0, -1		
				addi $s1, $s1, 4
				addi $s3, $s3, 4
				j compare_loop
append_fr_two:	add $t0, $s4, $s3			#determine address of next int in result_list
				add $t2, $a3, $s2			#determine the address of the value from list_one (this is for safety in case $t2 has been changed since the body of the loop) 
				lw $t2, 0($t2)
				sw $t2, 0($t0)				#store the lower int in the result_list
				#"pop" the head of the list and update the result_list offset
				addi $a2, $a2, -1		
				addi $s2, $s2, 4
				addi $s3, $s3, 4
				j compare_loop
				#continue to append from the respective list to the result_list until it is empty
empty_list_one:	blez $a0, copy
				add $t0, $s4, $s3			#determine address of next int in result_list
				add $t1, $a1, $s1			#determine the address of the int to append
				lw $t1, 0($t1)
				sw $t1, 0($t0)				#store the int in the result_list
				#"pop" the head of the list and update the result_list offset
				addi $a0, $a0, -1		
				addi $s1, $s1, 4
				addi $s3, $s3, 4
				j empty_list_one
				#same as empty_list_one but with different registers.
empty_list_two:	blez $a2, copy
				add $t0, $s4, $s3
				add $t2, $a3, $s2
				lw $t2, 0($t2)
				sw $t2, 0($t0)
				addi $a2, $a2, -1
				addi $s2, $s2, 4
				addi $s3, $s3, 4
				j empty_list_two
				#copy temp_list to list then return ($s0 should contain the size of the result list, and $s4 should contain the starting address of the temp_list)
copy:			addi $t1, $s5, 0				
				addi $t2, $0, 0 			#initialize offset at 0
copy_loop:		blez $s0, return
				add $t0, $t1, $t2			#store copy destination address in $t0
				add $t3, $s4, $t2			#store copy source address in $t3
				lw $t4, 0($t3)
				sw $t4, 0($t0)				#copy the int from one list to the other
				addi $s0, $s0, -1			#decrement the count of elements needing to be copied
				addi $t2, $t2, 4			#move to the next two integers
				j copy_loop
				#return from calling location (main)
return:			#load back $s0~$s5
				lw $s0, 0($sp)
				lw $s1, 4($sp)
				lw $s2, 8($sp)
				lw $s3, 12($sp)
				lw $s4, 16($sp)
				lw $s5, 20($sp)
				addi $sp, $sp, 24			#pop values
				jr $ra		
				#end merge	subroutine		
				#print the list and then exit
print:			addi $t0, $zero, 0			#set the offset at 0
				la $t1, list				#set a pointer to the list beginning
				la $t3, list_length			#set the number of elements to be printed
				lw $t3, 0($t3)
print_loop:		blez $t3, exit
				add $t4, $t1, $t0
				lw $a0, 0($t4)
				addi $v0, $zero, 1			#print int
				syscall
				la $a0, space
				addi $v0, $zero, 4			#print space
				syscall				
				addi $t0, $t0, 4
				addi $t3, $t3, -1
				j print_loop
exit:			la $a0, list
				addi $v0, $zero, 10
				syscall
				#potential errors
bad_length:		la $a0, error1
				addi $v0, $0, 4 
				syscall
				j exit	