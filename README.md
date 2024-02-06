# Greeter Script

The Greeter Script is a bash script that greets users based on their system status and group membership. It logs the greetings with timestamps and provides information about the user's special group status.

## Usage

```bash
./greeter.sh [-l <log_file>] [-k <lock_file>] [-h] [username1] [username2] ...
Options:
-l <log_file>: Specify a custom log file location (default: $HOME/greetings.log).
-k <lock_file>: Specify a custom lock file location (default: /tmp/greeter.lock).
-h: Show the help message.

Examples:
./greeter.sh -l /path/to/custom/logfile -lk /path/to/custom/lockfile user1 user2
```

## Installation

Clone the repository:

```bash
git clone <https://github.com/f-4-u/coursecontent-greeter.git>
```

Change into the script directory:

```bash
cd coursecontent-greeter
```

Make the script executable:

```bash
chmod u+x greeter.sh
```

## Program Flow

1. **Lock File Creation**: Checks if the lock file exists. If not, it creates one to prevent multiple script instances from running simultaneously.
2. **Log File Initialization**: Checks if the log file exists. If not, it creates one and sets appropriate permissions.
3. **User Existence and Groups**: Checks if users provided as arguments exist on the system and belong to specified groups (adm, root, sudo, wheel).
4. **Logging Greetings**: Logs greetings with Unix timestamps into the specified log file.
5. **Display Greetings**: Displays greetings for each user based on their existence and group membership.
6. **Unlock**: Removes the lock file before exiting.

## Exit Codes

```text
0: Successful execution
1: Another instance of the script is running
2: Error creating or accessing lock or log file
3: No username provided
4: User does not exist on the system
5: Script execution failed
6: Script help menu was shown
```

## Examples

```bash
./greeter.sh user1 user2
./greeter.sh -l /path/to/custom/logfile -k /path/to/custom/lockfile user1 user2
./greeter.sh -h
```

## License

This script is licensed under the GPL-3.0 License.

Feel free to further modify it to meet your specific needs.
