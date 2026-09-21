package sqlv1_test

import (
	"context"
	"io"
	"net"
	"testing"
	"time"

	sqlv1 "github.com/nominal-io/nominal-api-protos-go/sql/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"
	"google.golang.org/protobuf/proto"
)

type sqlServer struct {
	sqlv1.UnimplementedSqlServiceServer
	want *sqlv1.SqlServiceQueryRequest
}

func (s *sqlServer) Query(req *sqlv1.SqlServiceQueryRequest, stream grpc.ServerStreamingServer[sqlv1.SqlServiceQueryResponse]) error {
	if !proto.Equal(req, s.want) {
		return status.Error(codes.InvalidArgument, "request did not survive serialization")
	}
	for _, payload := range []string{"first", "second"} {
		if err := stream.Send(&sqlv1.SqlServiceQueryResponse{QueryId: "test-query", Payload: []byte(payload)}); err != nil {
			return err
		}
	}
	return nil
}

// Exercise the public import path and streaming RPC over an in-memory connection.
// Payloads are opaque test bytes, not an encoded SQL result.
func TestQueryStream(t *testing.T) {
	req := &sqlv1.SqlServiceQueryRequest{
		Query:        "SELECT 1 AS value",
		WorkspaceRid: "test-workspace",
		MaxRows:      proto.Int32(10),
		ResultFormat: sqlv1.SqlServiceQueryResultFormat_SQL_SERVICE_QUERY_RESULT_FORMAT_ARROW_STREAM,
	}
	listener := bufconn.Listen(1 << 20)
	t.Cleanup(func() { _ = listener.Close() })
	server := grpc.NewServer()
	sqlv1.RegisterSqlServiceServer(server, &sqlServer{want: req})
	t.Cleanup(server.Stop)
	go func() { _ = server.Serve(listener) }()

	conn, err := grpc.NewClient("passthrough:///sql-test",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return listener.DialContext(ctx)
		}),
	)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	stream, err := sqlv1.NewSqlServiceClient(conn).Query(ctx, req)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"first", "second"} {
		response, err := stream.Recv()
		if err != nil {
			t.Fatal(err)
		}
		if response.GetQueryId() != "test-query" || string(response.GetPayload()) != want {
			t.Fatalf("unexpected response: %v", response)
		}
	}
	if _, err := stream.Recv(); err != io.EOF {
		t.Fatalf("stream termination: got %v, want EOF", err)
	}
}
