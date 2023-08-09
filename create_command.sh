#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <LLDBParentFolder> <CommandName>"
    exit 1
fi

lldb_parent_folder="$1"
command_name="$2"

# Step 1: Create the source file in lldb/source/Commands
source_file_path="${lldb_parent_folder}/lldb/source/Commands/CommandObject${command_name}.cpp"
header_file_path="${lldb_parent_folder}/lldb/source/Commands/CommandObject${command_name}.h"

echo "#include \"CommandObject${command_name}.h\"
#include \"lldb/Interpreter/CommandInterpreter.h\"
using namespace lldb;
using namespace lldb_private;

CommandObject${command_name}::CommandObject${command_name}(CommandInterpreter &interpreter)
    : CommandObjectParsed(interpreter, \"$command_name\",
                          \"Description of new command\",
                          \"${command_name} args [optional args]\")
{
    // Add any command-specific argument data here if needed
}

CommandObject${command_name}::~CommandObject${command_name}() = default;

bool CommandObject${command_name}::DoExecute(Args &command, CommandReturnObject &result)
{
    // Implement the command execution logic here
    llvm::outs() << \"This is your new command ${command_name}!\\n\";
    return true;
}" > "$source_file_path"

# Step 2: Create the header file in lldb/source/Commands
echo "#ifndef LLDB_SOURCE_COMMANDS_COMMANDOBJECT${command_name}_H
#define LLDB_SOURCE_COMMANDS_COMMANDOBJECT${command_name}_H

#include \"lldb/Interpreter/CommandObject.h\"
#include \"lldb/Interpreter/CommandReturnObject.h\"

namespace lldb_private
{
    class CommandObject${command_name} : public CommandObjectParsed
    {
    public:
        CommandObject${command_name}(CommandInterpreter &interpreter);
        ~CommandObject${command_name}() override;

    protected:
        bool DoExecute(Args &args, CommandReturnObject &result) override;
    };
} // namespace lldb_private

#endif // LLDB_SOURCE_COMMANDS_COMMANDOBJECT${command_name}_H
" > "$header_file_path"

# Step 3: Add the file to LLDB Library
command_object_name="CommandObject${command_name}"

cmake_file_path="${lldb_parent_folder}/lldb/source/Commands/CMakeLists.txt"
if grep -q "${command_object_name}.cpp" "$cmake_file_path"; then
    echo "The command object already exists in CMakeLists.txt"
else

    new_line="\  ${command_object_name}.cpp"
    sed -i "/add_lldb_library(lldbCommands NO_PLUGIN_DEPENDENCIES/ a ${new_line}" "$cmake_file_path"

    echo "Command object '${command_object_name}' added to CMakeLists.txt"
fi

# Step 4: Add the new command to CommandInterpreter source file and dictionary
command_interpreter_file_path="${lldb_parent_folder}/lldb/source/Interpreter/CommandInterpreter.cpp"

# Add #include directive after #include <vector>
if grep -q "#include \"Commands/CommandObject${command_name}.h\"" "$command_interpreter_file_path"; then
    echo "The #include directive already exists in CommandInterpreter.cpp"
else
    sed -i "/#include <vector>/a #include \"Commands/CommandObject${command_name}.h\"" "$command_interpreter_file_path"
fi

if grep -q "REGISTER_COMMAND_OBJECT(\"${command_name}\", ${command_object_name});" "$command_interpreter_file_path"; then
    echo "The command object is already registered in LoadCommandDictionary function"
else
    command_lowercase="$(echo "$command_name" | tr '[:upper:]' '[:lower:]')"
    sed -i "/REGISTER_COMMAND_OBJECT(\"language\", CommandObjectLanguage);/a \ \tREGISTER_COMMAND_OBJECT(\"$command_lowercase\", ${command_object_name});" "$command_interpreter_file_path"
fi

echo "Command '$command_name' created successfully!"
