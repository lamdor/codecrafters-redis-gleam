import redis/resp
import gleam/bytes_builder

pub fn simple_string_test() {
  let bits =
    resp.simple_string_bytes("OK")
    |> bytes_builder.to_bit_array

  let assert <<"+OK\r\n":utf8>> = bits

  let assert Ok(resp.SimpleString("OK")) = resp.decode(bits)
}

pub fn simple_error_test() {
  let bits =
    resp.simple_error_bytes("owwww. something is wrong")
    |> bytes_builder.to_bit_array

  let assert <<"-owwww. something is wrong\r\n":utf8>> = bits
}

pub fn integer_test() {
  // positive
  let bits =
    resp.integer_bytes(123)
    |> bytes_builder.to_bit_array

  let assert <<":123\r\n":utf8>> = bits

  let assert Ok(resp.Integer(123)) = resp.decode(bits)

  // positive, with sigh
  let assert Ok(resp.Integer(123)) = resp.decode(<<":+123\r\n":utf8>>)

  // negative
  let bits =
    resp.integer_bytes(-123)
    |> bytes_builder.to_bit_array

  let assert <<":-123\r\n":utf8>> = bits

  let assert Ok(resp.Integer(-123)) = resp.decode(bits)
}

pub fn bulk_string_test() {
  let bits =
    resp.bulk_string_bytes("hello")
    |> bytes_builder.to_bit_array

  let assert <<"$5\r\nhello\r\n":utf8>> = bits

  let assert Ok(resp.BulkString("hello")) = resp.decode(bits)

  // given length doesn't match
  let assert Error(Nil) = resp.decode(<<"$3\r\nhello\r\n":utf8>>)
  let assert Error(Nil) = resp.decode(<<"$5\r\nhel\r\n":utf8>>)
  // no terminator
  let assert Error(Nil) = resp.decode(<<"$5hello\r\n":utf8>>)
  let assert Error(Nil) = resp.decode(<<"$5\r\nhello":utf8>>)
}

pub fn null_test() {
  let bits =
    resp.null_bytes()
    |> bytes_builder.to_bit_array

  let assert <<"$-1\r\n":utf8>> = bits

  // null bulk string
  let assert Ok(resp.Null(Nil)) = resp.decode(bits)
}

pub fn array_test() {
  let bits =
    resp.array_bytes([
      resp.bulk_string_bytes("hello"),
      resp.bulk_string_bytes("world"),
    ])
    |> bytes_builder.to_bit_array

  let assert <<"*2\r\n$5\r\nhello\r\n$5\r\nworld\r\n":utf8>> = bits

  let assert Ok(resp.Array([resp.BulkString("hello"), resp.BulkString("world")])) =
    resp.decode(bits)
}

pub fn to_string_list_test() {
  let xs = [resp.BulkString("hello"), resp.BulkString("world")]
  let assert Ok(["hello", "world"]) = resp.to_string_list(xs)
  let xs = [resp.Integer(3), resp.BulkString("world")]
  let assert Error(Nil) = resp.to_string_list(xs)
  let xs = [resp.SimpleString("hello"), resp.SimpleString("world")]
  let assert Ok(["hello", "world"]) = resp.to_string_list(xs)
}
