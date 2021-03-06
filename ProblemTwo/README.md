# JHU Comp Arch 605.611 Book Project Problem 2

This project attempts to create a consistent and easy-to-use environment for a code redirection from a buffer overflow on ARM32.

It does so in the following ways:

- Creates fault handlers to make the program easier to redirect without GDB.
- Positions target code at a consistent virtual memory address that fits up with a specific ASCII string.

To see the assignment head over to the [problem statements](ProblemStatements.md). When ready take a look at the [walkthrouh](walkthrough.md).