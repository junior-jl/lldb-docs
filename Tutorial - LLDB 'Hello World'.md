In this tutorial, we'll create a simple LLDB command named "hello". It prints "Hello" followed by strings that are passed as arguments (up to a maximum of 3).

## Step 1: create the header file

Following LLDB source code pattern, let's write include guards for the symbol `LLDB_SOURCE_COMMANDS_COMMANDOBJECTHELLO_H`:

```cpp
#ifndef LLDB_SOURCE_COMMANDS_COMMANDOBJECTHELLO_H
#define LLDB_SOURCE_COMMANDS_COMMANDOBJECTHELLO_H
.
.
.
#endif // LLDB_SOURCE_COMMANDS_COMMANDOBJECTHELLO_H
```

Now, let's include the necessary header files:

```cpp
#include "lldb/Interpreter/CommandObject.h"
#include "lldb/Interpreter/CommandReturnObject.h"
```

Our new class command derives from `CommandObject` as all commands and `CommandReturnObject` is used to handle the command return value.

Finally, we declare the class `CommandObjectHello`, inheriting from `CommandObjectParsed`, meaning that LLDB will parse its arguments before executing it.

```cpp
class CommandObjectHello : public CommandObjectParsed {
public:
    CommandObjectHello(CommandInterpreter &interpreter);
    ~CommandObjectHello() override;
```

Here we create the constructor (that gets a reference to a `CommandInterpreter` as a parameter) and the destructor.

All commands have a `bool DoExecute` function. Here it is declared as `protected` because this is an override. This function is where we put the logic of the command. In this case, it will take two arguments:
- `args` -> the command arguments
- `result` -> result of execution

```cpp
protected:
bool DoExecute(Args &args, CommandReturnObject &result) override;
```

## Step 2: create the source file

We include the header file defined in the previous step and bring relevant namespaces into scope.

```cpp
#include "CommandObjectHello.h"
#include "lldb/Interpreter/CommandInterpreter.h"
using namespace lldb;
using namespace lldb_private;
```

The constructor gets an argument of type `CommandInterpreter` (which is self-explainable). It calls the constructor of `CommandObjectParsed`:
	- Arguments: 
		- `interpreter` -> passed by `CommandObjectHello`
		- `name` -> string representing the name of the command
		- `help` -> string representing what command do (optional)
		- `syntax` -> string representing the syntax of command (optional)

```cpp
CommandObjectHello::CommandObjectHello(CommandInterpreter &interpreter)
    : CommandObjectParsed(interpreter, "hello",
                            "Prints 'Hello' followed by any string.",
                            "hello [strings]")
```

Then, the arguments are passed to an object of type `CommandArgumentData` an assigned to the `std::vector` that holds the arguments of the command `m_arguments`.

```cpp
CommandArgumentData string_arg{eArgTypeValue};
        m_arguments.push_back({string_arg});
```

### Logic of the command (`DoExecute`)

```cpp
bool CommandObjectHello::DoExecute(Args &command, CommandReturnObject &result)
```

We use `GetArgumentCount` utility function to check if there are more than 3 arguments (personal choice, one can change this -- sorry for the 'magic' number). If that happens, the object `result` gets an error message and the execution fails (`return false`);

```cpp
if (command.GetArgumentCount() > 3)
    {
        result.AppendError("Too many arguments for 'hello'. Only three strings "
                           "are allowed");
        return false;
    }
```

If the argument count is an allowed quantity, we pass it to a variable and iterate over it to print "Hello" and a sequence of the arguments. (Note: here we used `llvm::outs` to print, but there are other ways to do it, like using one of the methods of `CommandReturnObject`). Lastly, we set the status of return to success.

```cpp
else
    {
        size_t n_args = command.GetArgumentCount();
        llvm::outs() << "Hello";
        for (size_t idx = 0; idx < n_args; idx++)
        {
            llvm::StringRef arg = command.GetArgumentAtIndex(idx);
            llvm::outs() << " " << arg;
        }
        llvm::outs() << "\n";
        result.SetStatus(eReturnStatusSuccessContinuingNoResult);
    }
```
Then, we inform that the command was executed -> `return true`.

### Step 3: register the command

1. Add the file to LLDB Library: Go to `lldb/source/Commands/CMakeListst.txt`, and inside `add_lldb_library` put the source file name: `CommandObjectHello.cpp`. (Try to be consistent with the naming order).
2. Add the new command to the `CommandInterpreter` source file and dictionary.
	- Go to `lldb/source/Interpreter/CommandInterpreter.cpp` 
		- In function: `CommandInterpreter::LoadCommandDictionary` -> `REGISTER_COMMAND_OBJECT("hello", CommandObjectHello);`
		- In include directives: `#include "Commands/CommandObjectHello.h"`
3. Rebuild LLDB: go to the build folder and run `ninja`.

## Example of use

![[Pasted image 20230808233753.png]]
