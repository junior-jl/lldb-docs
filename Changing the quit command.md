The quit command is defined in the file `llvm-project/lldb/source/Commands/CommandObjectQuit.cpp`

- Inside `CommandObjectQuit::DoExecute`:
	- Inside the condition `if (command.GetArgumentCount() == 1) {`:
		I added:
		```
		// Print "10x" n times ; n = exit code
		for (int i = 0; i < exit_code; i++)
		{
			llvm::outs() << "10x ";
		}
		llvm::outs() << "\n";
		```

Hence, when a debug session is ended with an optional exit code, e.g. `(lldb) q 2`; `(lldb) exit 3`, it will print the string "10x" n times, where n is the exit code.

![[Pasted image 20230804151158.png]]
