# Nominal API protos for Go

Generated Go protobuf messages and gRPC clients for the Nominal API.

```sh
go get github.com/nominal-io/nominal-api-protos-go@latest
```

## Releases

A weekly workflow regenerates the bindings from scout's latest protos and opens a `feat(api): bump scout api to <version>` PR
when they change. `SCOUT_VERSION` is the scout release they were generated from, and
[release-please](https://github.com/googleapis/release-please) tags releases as `vX.Y.Z`.

Apache-2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE).
