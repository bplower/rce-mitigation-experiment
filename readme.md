
# RCE Defense Experiment

This experiment asked the question: If we assume our service has an RCE vuln in it, what can be done to prevent a malicious actor from accessing secrets necessesary for the service to run?

To explore this scenario, the python script `service.py` contains a wsgi app with an `exec` function that executes whatever a user provides in the body of a post request. Aside from that, the service code itself makes no other effort to assist or mitigate the RCE viability. The focus was to find a way to run the python service within docker such that an attacker cannot gain any sensative information from the operating context (like shell environment or filesystem).

## Scenario

First off, build the image: `make build`

### No protections

Start the service with no protections: `make run`. Now in a separate shell run the following commands:

1. Send a request reading the available environment variables. Note that you can see our example secrets here.
    ```
    make server-read-env
    ```

2. Send a request reading the settings file. Here you can see the example secrets
    ```
    make server-read-settings
    ```

3. Send a request reading cli args. If secrets were provided this way, we'd be able to read them here
    ```
    make server-read-process
    ```

![Example](./env.cast.svg)

### Env var protections

Start the service with environment variable protections with `make run-protect-env`.

1. Sending the request to read the env vars only shows the vars set while gunicorn started
    ```
    make server-read-env
    ```

2. Sending the request to read the settings file still gets us access to the service secrets
    ```
    make server-read-settings
    ```

![Example](./env.cast.svg)

### File protections

Start the service with file protections (also includes env var protections). In this case, the settings file "self destructs" after being read. Since the container stops after the process stops, this self destructing file works for us (except in cases with multiple gunicorn workers, but I'm working on that).

1. The settings file read request now fails, causing a stack trace on the server logs, and not giving any results to the malicious actor.
    ```
    make server-read-settings
    ```

2. However, the unfortunate aspect of python is that there are no memory safety guards, and the service secrets are in memory so long as the service is running, so all we have to do is find a way to reference the app instance. In short, this is done using the following make target, which finds that instance using pythons garbage collector library.
    ```
    make server-read-inmem-config
    ```

![Example](./file.cast.svg)

## WIP Conclusion

Since this is an example with python, an RCE vuln is indefensible, as can be seen by the `server-read-inmem-config` target which manages to access the service configurations live in memory, even after running the service without environment variables in the shell and after deleting the settings file. This is because python does not impose memory restrictions. Maybe the severity of an RCE would be less if it were a C/C++ or Rust service?
