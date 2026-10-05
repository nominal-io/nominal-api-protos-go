# Nominal API protos for Go

Generated Go protobuf messages and gRPC clients for the Nominal API.

```sh
go get github.com/nominal-io/nominal-api-protos-go@latest
```

## Updates and releases

The **Bump scout API** workflow runs every Monday (or on demand) and regenerates the bindings from the
latest scout `@nominal-io/proto-zip-npm-files` package. If anything changed, it opens a
`feat(api): bump scout api to <version>` PR. `SCOUT_VERSION` records the scout release the bindings were generated from.

Releases use [release-please](https://github.com/googleapis/release-please). Merged conventional-commit PRs
accumulate in a release PR, and merging that PR tags `vX.Y.Z`.

To regenerate locally from a `protos.zip`, run `scripts/generate.sh <protos.zip>`.

Apache-2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE).
