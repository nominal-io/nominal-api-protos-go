# Nominal API protos for Go

Generated Go protobuf messages and gRPC clients for the Nominal API, independent
of the Conjure-generated `nominal-api-go` module. Go 1.25 or newer is required.

The initial scope is `nominal.sql.v1.SqlService` (Query, Export, and GetSqlCatalog)
and its Nominal annotations. This is not yet a complete client for every Nominal
service. No versioned release has been published.

## Use

Import `github.com/nominal-io/nominal-api-protos-go/sql/v1` as `sqlv1`. Given an
existing authenticated `grpc.ClientConn` and a context with a deadline:

```go
client := sqlv1.NewSqlServiceClient(conn)
stream, err := client.Query(ctx, &sqlv1.SqlServiceQueryRequest{
    Query:        "SELECT 1 AS value",
    WorkspaceRid: workspaceRID,
    ResultFormat: sqlv1.SqlServiceQueryResultFormat_SQL_SERVICE_QUERY_RESULT_FORMAT_ARROW_STREAM,
})
```

Handle the error, then call `stream.Recv()` until `io.EOF`. Each response carries
`Payload` bytes and a `QueryId`. Consume payload chunks in order as one Arrow IPC
stream; individual gRPC messages need not contain complete Arrow records.

The generated code supplies transport bindings, not a configured connection.
Consumers own the gRPC endpoint, TLS, API-key metadata, deadlines, connection
cleanup, and decoding of Arrow/CSV/JSON results. No credentials belong in this
repository. Endpoint availability should be checked against the target deployment.

## Reproduce generation

[`source.json`](source.json) records the exact Scout commit, original paths, and
SHA-256 hashes for the unmodified snapshots in `proto/`. Private Scout access is
not required to regenerate from these snapshots. Third-party proto versions are
locked in `buf.lock`; their Go bindings come from upstream modules rather than
being copied into this module.

With Go 1.26.6 or newer and Python 3 installed:

```sh
./scripts/generate.sh
go mod tidy
git diff --exit-code
go test -race ./...
```

The script verifies source checksums, installs pinned Buf and Go generator
versions into ignored `.bin/`, and uses local generators. Go package names are
assigned by `buf.gen.yaml`; canonical Scout definitions are not edited. Network
access is needed to fetch public tools and locked dependencies. CI also checks
for untracked generated files and runs `go build` and `go vet`.

To update the source snapshot (maintainers with Scout access):

```sh
./scripts/sync-source.py ../scout <scout-commit-or-tag>
./scripts/generate.sh
go mod tidy
go test -race ./...
```

Review `source.json`, proto changes, and generated changes together. Update Buf
and Go dependency pins deliberately when the source requires it; generation
never updates `buf.lock`. Generated `.pb.go` files must not be edited by hand.

## Validation

The consumer smoke test uses an in-memory gRPC server to check a SQL request and
multiple streamed response messages through the generated public client. It
needs no Nominal credentials and does not prove live deployment connectivity or
SQL execution. Live Grafana integration and release automation are separate work.

## License

Apache-2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE).
