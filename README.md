# listenHere

listenHere is a Mac OSX command line tool that watches a directory for
file system changes and notifies a remote TCP server of each event. It
was designed specifically to work with the gulp [watch-network][1] task
which eases front-end development inside vagrant vms.

#### Usage

    $ listenHere <path>

[1]: https://github.com/efacilitation/watch-network
