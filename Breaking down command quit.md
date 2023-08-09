File: `llvm-project/lldb/source/Commands/CommandObjectQuit.cpp`

1. Includes the necessary files

```cpp
#include "CommandObjectQuit.h"
#include "lldb/Interpreter/CommandInterpreter.h"
#include "lldb/Interpreter/CommandReturnObject.h"
#include "lldb/Target/Process.h"
#include "lldb/Utility/StreamString.h"
```

2. Bring relevant namespaces to the current scope

```cpp
using namespace lldb;
using namespace lldb_private;
```
3. Constructor for the class `CommandObjectQuit`

```cpp
CommandObjectQuit::CommandObjectQuit(CommandInterpreter &interpreter)
: CommandObjectParsed(interpreter, "quit", "Quit the LLDB debugger.",
"quit [exit-code]") {
CommandArgumentData exit_code_arg{eArgTypeUnsignedInteger, eArgRepeatPlain};
m_arguments.push_back({exit_code_arg});
}
```

- The constructor gets an argument of type `CommandInterpreter` (which is self-explainable). 
- It calls the constructor of `CommandObjectParsed`:
	- Arguments: 
		- `interpreter` -> passed by `CommandObjectQuit`
		- `name` -> string representing the name of the command
		- `help` -> string representing what command do (optional)
		- `syntax` -> string representing the syntax of command (optional)
		- `flags` -> flags associated with the command

```cpp
CommandObjectParsed(CommandInterpreter &interpreter, const char *name,
const char *help = nullptr, const char *syntax = nullptr,
uint32_t flags = 0)
: CommandObject(interpreter, name, help, syntax, flags) {}
```
- The constructor of `CommandObjectParsed` calls the constructor of `CommandObject`, which is the parent class for all commands:
	- The arguments are passed from the child to the parent classes and they are used in the initializer list.
```cpp
CommandObject::CommandObject(CommandInterpreter &interpreter,
llvm::StringRef name, llvm::StringRef help,
llvm::StringRef syntax, uint32_t flags)
: m_interpreter(interpreter), m_cmd_name(std::string(name)),
m_flags(flags), m_deprecated_command_override_callback(nullptr),
m_command_override_callback(nullptr), m_command_override_baton(nullptr) {
m_cmd_help_short = std::string(help);
m_cmd_syntax = std::string(syntax);
}
```
- Since the command accepts one argument, an optional exit code, an object of type `CommandArgumentData` is created with type `eArgTypeUnsignedInteger` (from the enum `CommandArgumentType`) and repetition type `eArgRepeatPlain` (from the enum `ArgumentRepetitionType`) meaning it only has one occurrence.
- Finally, all command objects have arguments stored in the `std::vector m_arguments`, and our new argument list `exit_code_arg` is passed to this vector.

4. Destructor of the class
```cpp
CommandObjectQuit::~CommandObjectQuit() = default;
```

5. Function to check if LLDB should ask for confirmation before quitting (this will happen if any process is killed if quit).

```cpp
bool CommandObjectQuit::ShouldAskForConfirmation(bool &is_a_detach) {
if (!m_interpreter.GetPromptOnQuit())
	return false;
bool should_prompt = false;
is_a_detach = true;
```
- If the interpreter disabled the feature of prompt on quit, i.e., `m_interpreter.GetPromptOnQuit()` returns false, LLDB should not ask for confirmation and the function is exited.
- Creates a boolean `should_prompt` to be the return value.
- Sets boolean `is_a_detach` to true. It will be set to false if at least a process is killed when LLDB quit.
```cpp
for (uint32_t debugger_idx = 0; debugger_idx < Debugger::GetNumDebuggers();
debugger_idx++) {
	DebuggerSP debugger_sp(Debugger::GetDebuggerAtIndex(debugger_idx));
	if (!debugger_sp)
		continue;
```
- Iterates over all debuggers, and obtains the shared pointer to the current debugger. If the pointer (`DebuggerSP`) is a `nullptr`, skips the iteration.
```cpp
const TargetList &target_list(debugger_sp->GetTargetList());
for (uint32_t target_idx = 0;
target_idx < static_cast<uint32_t>(target_list.GetNumTargets());
target_idx++) {
	TargetSP target_sp(target_list.GetTargetAtIndex(target_idx));
	if (!target_sp)
		continue;
```
- Similarly, iterates over all the targets, if the target pointer is invalid, it continues to the next iteration.
```cpp
ProcessSP process_sp(target_sp->GetProcessSP());
if (process_sp && process_sp->IsValid() && process_sp->IsAlive() &&
process_sp->WarnBeforeDetach()) {
should_prompt = true;
if (!process_sp->GetShouldDetach()) {
// if we need to kill at least one process, just say so and return
is_a_detach = false;
return should_prompt;
}
}
```
- For each valid target, checks if there is a valid process. 
- If the process pointer is valid (`process_sp` returns `true`), if the process is valid (has not been finalized), if the process is still alive (redundant??) and if the user should be warned about that process being detached, then LLDB should prompt the user for confirmation, hence `should_prompt = true;`.
- If the process does need to be detached `process_sp->GetShouldDetach` returns `false`, set `is_a_detach` to false and return.

6. Execution function `DoExecute`
```cpp
bool CommandObjectQuit::DoExecute(Args &command, CommandReturnObject &result)
```
- The function gets as arguments the command arguments and the result that will be used to give the status of execution.
```cpp
bool is_a_detach = true;
if (ShouldAskForConfirmation(is_a_detach)) {
	StreamString message;
	message.Printf("Quitting LLDB will %s one or more processes. Do you really "
	"want to proceed",
	(is_a_detach ? "detach from" : "kill"));
	if (!m_interpreter.Confirm(message.GetString(), true)) {
		result.SetStatus(eReturnStatusFailed);
		return false;
	}
}
```
- If the function `ShouldAskForConfirmation` returns true, the user is prompted with a message to check if he really wants to leave the session. If user does not confirm, i.e., `m_interpreter.Confirm(message.GetString(), true)` returns false, the result is set to `eReturnStatusFailed` (enum in `ReturnStatus`) and the `DoExecute` returns false, indicating that the session was not left, i.e., `quit` failed.
```cpp
if (command.GetArgumentCount() > 1) {
	result.AppendError("Too many arguments for 'quit'. Only an optional exit "
	"code is allowed");
	return false;
}
```
- The `quit` command only accept an optional argument (an integer exit code). If there is more than one argument (`command.GetArgumentCount() > 1`), the result gets an error message and the execution fails, returning `false` and not leaving the session.
```cpp
if (command.GetArgumentCount() == 1) {
llvm::StringRef arg = command.GetArgumentAtIndex(0);
int exit_code;
if (arg.getAsInteger(/*autodetect radix*/ 0, exit_code)) {
lldb_private::StreamString s;
std::string arg_str = arg.str();
s.Printf("Couldn't parse '%s' as integer for exit code.", arg_str.data());
result.AppendError(s.GetString());
return false;
}
if (!m_interpreter.SetQuitExitCode(exit_code)) {
result.AppendError("The current driver doesn't allow custom exit codes"
" for the quit command.");
return false;
}
```
- If the command only gets one argument (`command.GetArgumentCount() == 1`):
	- The argument is passed to the variable `arg`: `llvm::StringRef arg = command.GetArgumentAtIndex(0);`
	- If the parsing of `arg` to an integer is successful, it is passed to the integer variable `exit_code`. If not, the execution will fail and `result` will get an error message. Also, if the current driver does not allow custom exit codes, execution will fail.
```cpp
const uint32_t event_type =
CommandInterpreter::eBroadcastBitQuitCommandReceived;
m_interpreter.BroadcastEvent(event_type);
result.SetStatus(eReturnStatusQuit);
return true;
```
- Broadcast a quit command event to the interpreter and `result` gets the status of successful quit `eReturnStatusQuit`. Since everything occurred normally, `return true`;