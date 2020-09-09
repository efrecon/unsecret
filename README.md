# unsecret

`unsecret` is an inverted wrapper: It will arrange to set the value of one or
several environment variables from the content of files before starting a
program. This is useful when you have a Docker image that can only be configured
using environment variables, but you wish to transmit settings (secrets?) to the
container using a secret mechanism such as Docker [secrets]. Obviously, the
secrets will be accessible and visible at the host running the container (since
they are given to the underlying container through environment variables), but
at least, you would have transmitted the value to the host using a secure
mechanism.

  [secrets]: https://docs.docker.com/engine/swarm/secrets/

Provided you have a file called `my-test` with the content `12345`, the
following command would print out `MY_TEST` with the value `12345` in the list
of environment variables printed out at the console.

```shell
./unsecret.sh -e MY_TEST -- env
```

And to detect all environment variables ending with `_FILE` and create, for
each, a variable without the `_FILE` ending but with the content of the file
pointed at by the variable ending with `_FILE`, run the following command:

```shell
./unsecret.sh -a _FILE --env
```

For more details, run the script with `--help`, the script can be controlled by
command-line options, or environment variables, all starting with `UNSECRET_`.
Command-line options have precedence over the environment variables.
