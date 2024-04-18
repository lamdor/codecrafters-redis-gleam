import redis/resp
import gleam/bytes_builder

pub fn simple_string_test() {
  let bits =
    resp.simple_string("OK")
    |> bytes_builder.to_bit_array

  let assert <<"+OK\r\n":utf8>> = bits

  let assert Ok(resp.SimpleString("OK")) = resp.decode(bits)
}

pub fn simple_error_test() {
  let bits =
    resp.simple_error("owwww. something is wrong")
    |> bytes_builder.to_bit_array

  let assert <<"-owwww. something is wrong\r\n":utf8>> = bits
}

pub fn bulk_string_test() {
  let bits =
    resp.bulk_string("hello")
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
