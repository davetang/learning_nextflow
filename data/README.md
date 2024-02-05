## README

Download data using `wget`. If you are curious, like me, about what the
`--content-disposition` parameter does:

```
--content-disposition
    If this is set to on, experimental (not fully-functional) support for "Content-Disposition" headers is
    enabled. This can currently result in extra round-trips to the server for a "HEAD" request, and is known
    to suffer from a few bugs, which is why it is not currently enabled by default.

    This option is useful for some file-downloading CGI programs that use "Content-Disposition" headers to
    describe what the name of a downloaded file should be.
```

Data will be downloaded as `data.tar.gz`.

```console
wget --content-disposition https://ndownloader.figshare.com/files/28531743
tar -xzf data.tar.gz
```

Numbers file.

```console
for i in {1..20}; do echo ${i}; done | shuf --random-source=<(yes 1984) > num.txt
```
