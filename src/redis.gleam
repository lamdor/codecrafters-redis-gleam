import gleam/erlang/process
import gleam/option.{None}
import gleam/bytes_builder.{type BytesBuilder}
import gleam/otp/actor
import gleam/result
import glisten
import redis/resp
import redis/commands

pub fn main() {
  let assert Ok(_) =
    glisten.handler(fn(_conn) { #(Nil, None) }, fn(msg, state, conn) {
      let assert glisten.Packet(bits) = msg

      let resp_byte_builder = case resp.decode(bits) {
        Ok(resp.Array(resps)) -> {
          let handled_cmd = {
            use strings <- result.try(resp.to_string_list(resps))
            use cmd <- result.map(commands.from_string_list(strings))
            case cmd {
              commands.Ping -> handle_ping()
              commands.Echo(str) -> handle_echo(str)
            }
          }
          result.unwrap(
            handled_cmd,
            resp.simple_error_bytes("ERR unknown command"),
          )
        }
        _ -> resp.simple_error_bytes("ERR Unable to decode")
      }

      let assert Ok(_) = glisten.send(conn, resp_byte_builder)
      actor.continue(state)
    })
    |> glisten.serve(6379)

  process.sleep_forever()
}

fn handle_ping() -> BytesBuilder {
  resp.simple_string_bytes("PONG")
}

fn handle_echo(str: String) -> BytesBuilder {
  resp.bulk_string_bytes(str)
}
