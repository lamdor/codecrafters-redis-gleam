import redis/resp
import gleam/bytes_builder

pub fn simple_string_test() {
  let assert <<"+PONG\r\n":utf8>> =
    resp.simple_string("PONG")
    |> bytes_builder.to_bit_array
}
